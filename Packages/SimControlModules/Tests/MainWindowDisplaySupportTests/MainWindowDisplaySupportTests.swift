import Foundation
import MainWindowDisplaySupport
import SimControlDomain
import Testing

@Suite("MainWindowDisplaySupportTests")
struct MainWindowDisplaySupportTests {
  @Test func exposesDisplayTitlesAcrossModules() {
    #expect(SimulatorPlatform.iOS.displayTitle == "iOS")
    #expect(SimulatorDevice.State.booted.displayTitle == "Booted")
    #expect(SimulatorFilters.SidebarScope.pinned.displayTitle == "Bookmark")
    #expect(SimulatorFilters.DeviceSort.lastBootedAt.displayTitle == "Last Booted")
    #expect(SimulatorFilters.AppSystemFilter.user.displayTitle == "User Apps")
  }

  @Test func exposesCommandResultSummariesAcrossModules() {
    let result = CommandResult(
      id: "command-1",
      executable: "/usr/bin/xcrun",
      arguments: ["simctl", "list"],
      stdout: "",
      stderr: "",
      exitCode: 0,
      duration: 1.25,
      startedAt: Date(timeIntervalSince1970: 0)
    )

    #expect(result.commandLineSummary == "xcrun simctl list")
    #expect(result.durationTitle == "1.25s")
  }
}
