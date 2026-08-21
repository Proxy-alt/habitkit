import Foundation
import SwiftData

// MARK: - VisionProfile

/// A placeholder schema type for future on-device Vision-based habit validation.
///
/// **Status: Deferred to post-v1.** This type exists in the schema now to
/// prevent a SwiftData migration when Vision validation is added in a future
/// release. It is always `nil` on `Habit` in v1.
///
/// When implemented, Vision processing runs in the main app target only —
/// never in extensions, which have a 6 MB memory limit.
@Model
public class VisionProfile {

    // MARK: - Classification

    /// JSON-encoded `[String]` of `VNClassificationObservation` identifiers
    /// expected to match for this habit's completion photo.
    ///
    /// Stored as JSON to avoid CoW storage issues with SwiftData schema analysis.
    private var expectedLabelsData: Data = Data()

    /// The `VNClassificationObservation` identifiers to match.
    public var expectedLabels: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: expectedLabelsData)) ?? []
        }
        set {
            expectedLabelsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    /// Minimum `VNClassificationObservation.confidence` required for a match.
    /// Typical values: 0.6–0.8.
    public var threshold: Float = 0.7

    // MARK: - OCR

    /// When `true`, `VNRecognizeTextRequest` is also run alongside classification.
    public var useOCR: Bool = false

    /// If `useOCR` is `true`, the text pattern to look for in recognition results.
    public var expectedText: String?

    /// The habit this profile belongs to. CloudKit requires every relationship
    /// to declare an inverse; `Habit.visionProfile` is the other side.
    @Relationship(inverse: \Habit.visionProfile)
    public var habit: Habit?

    // MARK: - Init

    public init(
        expectedLabels: [String] = [],
        threshold: Float = 0.7,
        useOCR: Bool = false,
        expectedText: String? = nil
    ) {
        self.expectedLabelsData = (try? JSONEncoder().encode(expectedLabels)) ?? Data()
        self.threshold = threshold
        self.useOCR = useOCR
        self.expectedText = expectedText
    }
}
