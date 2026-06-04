import Foundation
import SimControlDomain

extension CoreSimulatorService {
  /// Returns the active Xcode developer path reported by `xcode-select -p`.
  public func selectedXcodePath() async -> DeveloperPathResult {
    let commandResult = await runCommand(
      "xcode-select",
      ["-p"],
      selectedXcodePathTimeout
    )

    guard commandResult.succeeded else {
      return DeveloperPathResult(
        developerPath: nil,
        commandResult: commandResult,
        diagnostic: commandFailureDiagnostic(command: "xcode-select -p", result: commandResult)
      )
    }

    let path = commandResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !path.isEmpty else {
      return DeveloperPathResult(
        developerPath: nil,
        commandResult: commandResult,
        diagnostic: "xcode-select -p returned an empty developer path."
      )
    }

    return DeveloperPathResult(
      developerPath: URL(fileURLWithPath: path),
      commandResult: commandResult,
      diagnostic: nil
    )
  }

  /// Runs `simctl list -j` and decodes the raw service-layer payload.
  public func list() async -> ListResult {
    let commandResult = await runCommand(
      "xcrun",
      ["simctl", "list", "-j"],
      listTimeout
    )

    guard commandResult.succeeded else {
      return ListResult(
        payload: nil,
        commandResult: commandResult,
        diagnostic: commandFailureDiagnostic(command: "xcrun simctl list -j", result: commandResult)
      )
    }

    do {
      let payload = try JSONDecoder().decode(
        SimctlListPayload.self,
        from: Data(commandResult.stdout.utf8)
      )

      return ListResult(
        payload: payload,
        commandResult: commandResult,
        diagnostic: nil
      )
    } catch {
      return ListResult(
        payload: nil,
        commandResult: commandResult,
        diagnostic: "Failed to decode simctl list JSON: \(error.localizedDescription)"
      )
    }
  }

  /// Opens Simulator.app.
  public func openSimulatorApp() async -> CommandResult {
    await runCommand(
      "open",
      ["-a", "Simulator"],
      openSimulatorAppTimeout
    )
  }
}
