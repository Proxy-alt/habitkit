import Testing
@testable import HabitKitCore

@Suite("HabitError")
struct HabitErrorTests {
    @Test("alreadyCompletedToday has non-nil description")
    func alreadyCompletedTodayDescription() {
        #expect(HabitError.alreadyCompletedToday.errorDescription != nil)
    }

    @Test("notFound includes the UUID in description")
    func notFoundDescription() {
        let id = UUID()
        let error = HabitError.notFound(id)
        #expect(error.errorDescription?.contains(id.uuidString) == true)
    }
}
