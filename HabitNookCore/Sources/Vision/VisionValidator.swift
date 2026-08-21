import Foundation
import Vision

// MARK: - VisionValidator

/// Uses the Vision framework to validate completion photos against a habit's
/// `VisionProfile` (§8.24).
///
/// This is a post-v1 feature — `VisionProfile` is captured in the schema now
/// to prevent a migration later. In v1, `validatePhoto(_:against:)` always
/// returns `.notConfigured`. The implementation is provided in full so it can
/// be enabled by flipping the feature flag.
public actor VisionValidator {

    // MARK: - Shared instance

    public static let shared = VisionValidator()

    // MARK: - Init

    private init() {}

    // MARK: - Validation

    /// Validates a JPEG/PNG photo against the habit's vision profile.
    ///
    /// - Parameters:
    ///   - imageData: JPEG or PNG image data from a completion photo.
    ///   - profile: The `VisionProfile` containing expected labels and threshold.
    /// - Returns: A `VisionValidationResult` describing the outcome.
    public func validatePhoto(
        _ imageData: Data,
        against profile: VisionProfile
    ) async -> VisionValidationResult {
        // Feature flag guard — enabled in post-v1.
        guard FeatureFlags.visionValidationEnabled else {
            return .notConfigured
        }

        guard let cgImage = cgImage(from: imageData) else {
            return .error("Could not decode image data")
        }

        let expectedLabels = profile.expectedLabels
        guard !expectedLabels.isEmpty else {
            return .notConfigured
        }

        do {
            let classificationResult = try await classifyImage(cgImage)
            let topLabels = classificationResult
                .prefix(10)
                .map { $0.lowercased() }

            let matched = expectedLabels.filter { expected in
                topLabels.contains { $0.contains(expected.lowercased()) }
            }

            let matchRatio = Float(matched.count) / Float(expectedLabels.count)
            if matchRatio >= profile.threshold {
                return .passed(confidence: matchRatio, matchedLabels: matched)
            } else {
                return .failed(confidence: matchRatio, expectedLabels: expectedLabels)
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }

    // MARK: - OCR (optional)

    /// Runs OCR on the image and returns detected strings.
    ///
    /// Only called when `VisionProfile.useOCR == true`.
    ///
    /// - Parameter imageData: The image to analyse.
    /// - Returns: Array of recognised text strings.
    public func recogniseText(in imageData: Data) async -> [String] {
        guard let cgImage = cgImage(from: imageData) else { return [] }
        do {
            return try await performOCR(on: cgImage)
        } catch {
            return []
        }
    }

    // MARK: - Private helpers

    private func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return image
    }

    private func classifyImage(_ image: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                // Extract just the (Sendable) identifiers here — the
                // VNClassificationObservation results themselves are not
                // Sendable and must not cross the continuation boundary.
                let identifiers = (request.results as? [VNClassificationObservation])?
                    .map { $0.identifier } ?? []
                continuation.resume(returning: identifiers)
            }
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func performOCR(on image: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let strings = (request.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: strings)
            }
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - VisionValidationResult

/// The result of a vision profile photo validation.
public enum VisionValidationResult: Sendable {
    /// Vision validation is not configured for this habit.
    case notConfigured
    /// Validation passed with the given confidence.
    case passed(confidence: Float, matchedLabels: [String])
    /// Validation failed — confidence was below the threshold.
    case failed(confidence: Float, expectedLabels: [String])
    /// An error occurred during validation.
    case error(String)
}

// MARK: - FeatureFlags

/// Internal feature flag namespace.
enum FeatureFlags {
    /// Controls whether Vision-based photo validation is active.
    /// Disabled in v1; can be enabled via remote configuration in a future release.
    static let visionValidationEnabled = false
}
