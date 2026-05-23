import Foundation
import SensitiveContentAnalysis

// MARK: - ContentAnalyzer

/// Analyses completion photos for sensitive content before display (§8.31).
///
/// Uses `SCSensitivityAnalyzer` to check images before they are shown in the
/// habit detail view. If sensitive content is detected, the image is blurred
/// and the user must tap to reveal it.
public actor ContentAnalyzer {

    // MARK: - Shared instance

    public static let shared = ContentAnalyzer()

    // MARK: - Private state

    private let analyzer = SCSensitivityAnalyzer()

    // MARK: - Init

    private init() {}

    // MARK: - Analysis

    /// Analyses image data for sensitive content.
    ///
    /// - Parameter imageData: JPEG or PNG data of the completion photo.
    /// - Returns: A `ContentAnalysisResult` indicating whether the image is safe.
    public func analyse(imageData: Data) async -> ContentAnalysisResult {
        guard analyzer.analysisPolicy != .disabled else {
            return .notApplicable
        }

        guard let handler = SCSensitivityAnalysisHandler(data: imageData) else {
            return .analysisUnavailable
        }

        do {
            let response = try await analyzer.analysisResult(for: handler)
            if response.isSensitive {
                return .sensitive
            } else {
                return .safe
            }
        } catch {
            return .analysisUnavailable
        }
    }
}

// MARK: - ContentAnalysisResult

/// The result of a sensitive-content analysis on a completion photo.
public enum ContentAnalysisResult: Sendable {
    /// The image does not contain sensitive content.
    case safe
    /// The image contains sensitive content and should be blurred.
    case sensitive
    /// The SensitiveContentAnalysis framework is not available or disabled.
    case notApplicable
    /// Analysis could not be performed (e.g. unsupported image format).
    case analysisUnavailable
}
