import Foundation
import Testing
import SimControlDomain

@MainActor
@Suite("ActionResultTests")
struct ActionResultTests {
  @Test func preservesOutcomeMessageCommandAndOccurrenceDate() {
    let occurredAt = Date(timeIntervalSince1970: 400)
    let commandResult = CommandResult(
      id: "command-1",
      executable: "xcrun",
      arguments: ["simctl", "boot", "UDID-1"],
      stdout: "booted",
      stderr: "",
      exitCode: 0,
      duration: 1.2,
      startedAt: occurredAt
    )
    let result = ActionResult(
      id: "action-success",
      title: "Boot Device",
      outcome: .success,
      message: "Booted",
      commandResult: commandResult,
      occurredAt: occurredAt
    )

    #expect(result.id == "action-success")
    #expect(result.title == "Boot Device")
    #expect(result.outcome == .success)
    #expect(result.message == "Booted")
    #expect(result.commandResult == commandResult)
    #expect(result.occurredAt == occurredAt)
  }

  @Test func supportsCancelledActionsWithoutCommandResults() {
    let occurredAt = Date(timeIntervalSince1970: 401)
    let result = ActionResult(
      id: "action-cancelled",
      title: "Delete Device",
      outcome: .cancelled,
      message: nil,
      commandResult: nil,
      occurredAt: occurredAt
    )

    #expect(result.outcome == .cancelled)
    #expect(result.message == nil)
    #expect(result.commandResult == nil)
  }
}
