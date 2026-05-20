import Foundation
import Testing
@testable import HabitKitCore

@Suite("HabitTemplate")
struct HabitTemplateTests {

    private func makeTemplate(type: HabitType = .yesNo, frequency: String = "daily") -> HabitTemplate {
        HabitTemplate(
            name: "Morning Run",
            icon: "figure.run",
            colorHex: "#FF0000",
            type: type,
            schedule: TemplateSchedule(frequency: frequency, reminderTimes: ["07:00"]),
            templateDescription: "A daily run",
            templateVersion: "1.0"
        )
    }

    // MARK: - Encode / decode

    @Test("HabitTemplate round-trips through JSON")
    func roundTrip() throws {
        let template = makeTemplate()
        let data = try template.encode()
        let decoded = try HabitTemplate.decode(from: data)
        #expect(decoded.name == template.name)
        #expect(decoded.icon == template.icon)
        #expect(decoded.colorHex == template.colorHex)
        #expect(decoded.type == template.type)
        #expect(decoded.templateVersion == template.templateVersion)
        #expect(decoded.templateDescription == template.templateDescription)
    }

    @Test("encode produces non-empty data")
    func encodeProducesData() throws {
        let data = try makeTemplate().encode()
        #expect(!data.isEmpty)
    }

    @Test("decode throws on malformed data")
    func decodeBadData() {
        let bad = Data("not json".utf8)
        #expect(throws: (any Error).self) {
            try HabitTemplate.decode(from: bad)
        }
    }

    // MARK: - resolvedFrequency

    @Test("resolvedFrequency returns .daily")
    func resolveDaily() {
        let t = makeTemplate(frequency: "daily")
        #expect(t.resolvedFrequency() == .daily)
    }

    @Test("resolvedFrequency returns .weekly with correct days")
    func resolveWeekly() {
        var t = makeTemplate(frequency: "weekly")
        t.schedule.frequencyDetail = "1,3,5"
        let freq = t.resolvedFrequency()
        #expect(freq == .weekly(days: [1, 3, 5]))
    }

    @Test("resolvedFrequency returns nil for weekly without detail")
    func resolveWeeklyNoDetail() {
        let t = makeTemplate(frequency: "weekly")
        #expect(t.resolvedFrequency() == nil)
    }

    @Test("resolvedFrequency returns .interval")
    func resolveInterval() {
        var t = makeTemplate(frequency: "interval")
        t.schedule.frequencyDetail = "3"
        #expect(t.resolvedFrequency() == .interval(every: 3))
    }

    @Test("resolvedFrequency returns nil for interval without detail")
    func resolveIntervalNoDetail() {
        let t = makeTemplate(frequency: "interval")
        #expect(t.resolvedFrequency() == nil)
    }

    @Test("resolvedFrequency returns .xTimesPerWeek")
    func resolveXTimesPerWeek() {
        var t = makeTemplate(frequency: "xTimesPerWeek")
        t.schedule.frequencyDetail = "4"
        #expect(t.resolvedFrequency() == .xTimesPerWeek(x: 4))
    }

    @Test("resolvedFrequency returns nil for unknown frequency")
    func resolveUnknown() {
        let t = makeTemplate(frequency: "monthly")
        #expect(t.resolvedFrequency() == nil)
    }

    // MARK: - HabitType raw values

    @Test("HabitType raw values are stable")
    func habitTypeRawValues() {
        #expect(HabitType.yesNo.rawValue == "yesNo")
        #expect(HabitType.timed.rawValue == "timed")
        #expect(HabitType.quantity.rawValue == "quantity")
        #expect(HabitType.checklist.rawValue == "checklist")
        #expect(HabitType.negative.rawValue == "negative")
    }

    // MARK: - Type-specific fields

    @Test("timed template preserves targetDurationSeconds")
    func timedTemplate() throws {
        let t = HabitTemplate(
            name: "Meditate", icon: "brain", colorHex: "#00F",
            type: .timed,
            schedule: TemplateSchedule(frequency: "daily"),
            targetDurationSeconds: 600
        )
        let data = try t.encode()
        let decoded = try HabitTemplate.decode(from: data)
        #expect(decoded.targetDurationSeconds == 600)
    }

    @Test("quantity template preserves targetQuantity and unit")
    func quantityTemplate() throws {
        let t = HabitTemplate(
            name: "Water", icon: "drop", colorHex: "#00F",
            type: .quantity,
            schedule: TemplateSchedule(frequency: "daily"),
            targetQuantity: 8,
            unit: "glasses"
        )
        let data = try t.encode()
        let decoded = try HabitTemplate.decode(from: data)
        #expect(decoded.targetQuantity == 8)
        #expect(decoded.unit == "glasses")
    }

    @Test("checklist template preserves steps")
    func checklistTemplate() throws {
        let t = HabitTemplate(
            name: "Morning Routine", icon: "list.bullet", colorHex: "#0F0",
            type: .checklist,
            schedule: TemplateSchedule(frequency: "daily"),
            steps: ["Brush teeth", "Shower", "Breakfast"]
        )
        let data = try t.encode()
        let decoded = try HabitTemplate.decode(from: data)
        #expect(decoded.steps == ["Brush teeth", "Shower", "Breakfast"])
    }

    @Test("negative template preserves avoidTarget")
    func negativeTemplate() throws {
        let t = HabitTemplate(
            name: "No Phone", icon: "iphone.slash", colorHex: "#F00",
            type: .negative,
            schedule: TemplateSchedule(frequency: "daily"),
            avoidTarget: "Avoid social media"
        )
        let data = try t.encode()
        let decoded = try HabitTemplate.decode(from: data)
        #expect(decoded.avoidTarget == "Avoid social media")
    }
}
