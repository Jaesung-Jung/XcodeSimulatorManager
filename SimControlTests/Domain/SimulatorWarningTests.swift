import Testing
@testable import SimControl

@MainActor
@Suite
struct SimulatorWarningTests {
  @Test func preservesSeverityCategoryMessageAndRelatedID() {
    let warning = SimulatorWarning(
      id: "warning-permission",
      severity: .error,
      category: .permissions,
      message: "Permission denied",
      relatedID: "device-1"
    )

    #expect(warning.id == "warning-permission")
    #expect(warning.severity == .error)
    #expect(warning.category == .permissions)
    #expect(warning.message == "Permission denied")
    #expect(warning.relatedID == "device-1")
  }

  @Test func supportsWarningsWithoutRelatedIdentifiers() {
    let warning = SimulatorWarning(
      id: "warning-xcode",
      severity: .info,
      category: .xcode,
      message: "Using active Xcode",
      relatedID: nil
    )

    #expect(warning.severity == .info)
    #expect(warning.category == .xcode)
    #expect(warning.relatedID == nil)
  }
}
