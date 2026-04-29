import Foundation

/// Wraps `xcrun`, `simctl`, and Simulator.app process boundaries.
struct CoreSimulatorService {
  /// The active developer directory lookup result returned by CoreSimulatorService.
  struct DeveloperPathResult: Equatable {
    /// The selected Xcode developer directory, when the command succeeded and returned a path.
    let developerPath: URL?

    /// The command result produced by `xcode-select -p`.
    let commandResult: CommandResult

    /// Additional service-level context, such as an empty stdout or command failure.
    let diagnostic: String?

    /// Indicates whether the command produced a usable developer path.
    var succeeded: Bool {
      commandResult.succeeded && developerPath != nil && diagnostic == nil
    }
  }

  /// The decoded `simctl list -j` result returned by CoreSimulatorService.
  struct ListResult: Equatable {
    /// The decoded raw simctl payload, when command execution and JSON decoding both succeeded.
    let payload: SimctlListPayload?

    /// The command result produced by `xcrun simctl list -j`.
    let commandResult: CommandResult

    /// Additional service-level context, such as a command failure or JSON decode failure.
    let diagnostic: String?

    /// Indicates whether the command produced a decoded simctl payload.
    var succeeded: Bool {
      commandResult.succeeded && payload != nil && diagnostic == nil
    }
  }

  typealias CommandRunner = (_ executable: String, _ arguments: [String], _ timeout: TimeInterval?) async -> CommandResult

  private static let defaultSelectedXcodePathTimeout: TimeInterval = 10
  private static let defaultListTimeout: TimeInterval = 30
  private static let defaultOpenSimulatorAppTimeout: TimeInterval = 10
  private static let defaultDeviceCommandTimeout: TimeInterval = 60

  private let runCommand: CommandRunner
  private let selectedXcodePathTimeout: TimeInterval?
  private let listTimeout: TimeInterval?
  private let openSimulatorAppTimeout: TimeInterval?
  private let deviceCommandTimeout: TimeInterval?

  init(
    commandExecutor: CommandExecutor = CommandExecutor(),
    selectedXcodePathTimeout: TimeInterval? = Self.defaultSelectedXcodePathTimeout,
    listTimeout: TimeInterval? = Self.defaultListTimeout,
    openSimulatorAppTimeout: TimeInterval? = Self.defaultOpenSimulatorAppTimeout,
    deviceCommandTimeout: TimeInterval? = Self.defaultDeviceCommandTimeout
  ) {
    self.selectedXcodePathTimeout = selectedXcodePathTimeout
    self.listTimeout = listTimeout
    self.openSimulatorAppTimeout = openSimulatorAppTimeout
    self.deviceCommandTimeout = deviceCommandTimeout
    self.runCommand = { executable, arguments, timeout in
      await commandExecutor.execute(
        executable: executable,
        arguments: arguments,
        timeout: timeout
      )
    }
  }

  init(
    selectedXcodePathTimeout: TimeInterval? = Self.defaultSelectedXcodePathTimeout,
    listTimeout: TimeInterval? = Self.defaultListTimeout,
    openSimulatorAppTimeout: TimeInterval? = Self.defaultOpenSimulatorAppTimeout,
    deviceCommandTimeout: TimeInterval? = Self.defaultDeviceCommandTimeout,
    runCommand: @escaping CommandRunner
  ) {
    self.selectedXcodePathTimeout = selectedXcodePathTimeout
    self.listTimeout = listTimeout
    self.openSimulatorAppTimeout = openSimulatorAppTimeout
    self.deviceCommandTimeout = deviceCommandTimeout
    self.runCommand = runCommand
  }

  /// Returns the active Xcode developer path reported by `xcode-select -p`.
  func selectedXcodePath() async -> DeveloperPathResult {
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
  func list() async -> ListResult {
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

  /// Opens Simulator.app without mutating UI state.
  func openSimulatorApp() async -> CommandResult {
    await runCommand(
      "open",
      ["-a", "Simulator"],
      openSimulatorAppTimeout
    )
  }

  /// Boots the simulator device identified by CoreSimulator UDID.
  func bootDevice(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "boot", id],
      deviceCommandTimeout
    )
  }

  /// Shuts down the simulator device identified by CoreSimulator UDID.
  func shutdownDevice(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "shutdown", id],
      deviceCommandTimeout
    )
  }

  /// Creates a simulator device with the provided device type and runtime identifiers.
  func createDevice(
    name: String,
    deviceTypeID: String,
    runtimeID: String
  ) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "create", name, deviceTypeID, runtimeID],
      deviceCommandTimeout
    )
  }

  /// Clones an existing simulator device under a new display name.
  func cloneDevice(id: String, name: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "clone", id, name],
      deviceCommandTimeout
    )
  }

  /// Renames an existing simulator device.
  func renameDevice(id: String, name: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "rename", id, name],
      deviceCommandTimeout
    )
  }

  /// Erases the contents and settings of a simulator device.
  func eraseDevice(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "erase", id],
      deviceCommandTimeout
    )
  }

  /// Deletes a simulator device.
  func deleteDevice(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "delete", id],
      deviceCommandTimeout
    )
  }

  /// Creates a watch and phone simulator pair.
  func pairDevices(watchDeviceID: String, phoneDeviceID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "pair", watchDeviceID, phoneDeviceID],
      deviceCommandTimeout
    )
  }

  /// Removes an existing watch and phone simulator pair.
  func unpairDevice(pairID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "unpair", pairID],
      deviceCommandTimeout
    )
  }

  private func commandFailureDiagnostic(command: String, result: CommandResult) -> String {
    let summary = "\(command) failed with exit code \(result.exitCode)."
    let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !stderr.isEmpty else {
      return summary
    }

    return "\(summary)\n\(stderr)"
  }
}
