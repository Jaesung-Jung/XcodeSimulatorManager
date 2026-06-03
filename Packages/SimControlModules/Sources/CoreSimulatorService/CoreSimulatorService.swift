import CommandExecutionService
import Foundation
import SimControlDomain

/// Wraps `xcrun`, `simctl`, and Simulator.app process boundaries.
public struct CoreSimulatorService {
  /// The active developer directory lookup result returned by CoreSimulatorService.
  public struct DeveloperPathResult: Equatable {
    /// The selected Xcode developer directory, when the command succeeded and returned a path.
    public let developerPath: URL?

    /// The command result produced by `xcode-select -p`.
    public let commandResult: CommandResult

    /// Additional service-level context, such as an empty stdout or command failure.
    public let diagnostic: String?

    public init(
      developerPath: URL?,
      commandResult: CommandResult,
      diagnostic: String?
    ) {
      self.developerPath = developerPath
      self.commandResult = commandResult
      self.diagnostic = diagnostic
    }

    /// Indicates whether the command produced a usable developer path.
    public var succeeded: Bool {
      commandResult.succeeded && developerPath != nil && diagnostic == nil
    }
  }

  /// The decoded `simctl list -j` result returned by CoreSimulatorService.
  public struct ListResult: Equatable {
    /// The decoded raw simctl payload, when command execution and JSON decoding both succeeded.
    public let payload: SimctlListPayload?

    /// The command result produced by `xcrun simctl list -j`.
    public let commandResult: CommandResult

    /// Additional service-level context, such as a command failure or JSON decode failure.
    public let diagnostic: String?

    public init(
      payload: SimctlListPayload?,
      commandResult: CommandResult,
      diagnostic: String?
    ) {
      self.payload = payload
      self.commandResult = commandResult
      self.diagnostic = diagnostic
    }

    /// Indicates whether the command produced a decoded simctl payload.
    public var succeeded: Bool {
      commandResult.succeeded && payload != nil && diagnostic == nil
    }
  }

  typealias CommandRunner = (_ executable: String, _ arguments: [String], _ timeout: TimeInterval?) async -> CommandResult

  @usableFromInline static let defaultSelectedXcodePathTimeout: TimeInterval = 10
  @usableFromInline static let defaultListTimeout: TimeInterval = 30
  @usableFromInline static let defaultOpenSimulatorAppTimeout: TimeInterval = 10
  @usableFromInline static let defaultDeviceCommandTimeout: TimeInterval = 60

  private let runCommand: CommandRunner
  private let makePushPayloadURL: () -> URL
  private let writePushPayload: (String, URL) throws -> Void
  private let removePushPayload: (URL) -> Void
  private let now: () -> Date
  private let makeID: () -> String
  private let selectedXcodePathTimeout: TimeInterval?
  private let listTimeout: TimeInterval?
  private let openSimulatorAppTimeout: TimeInterval?
  private let deviceCommandTimeout: TimeInterval?

  /// Creates a CoreSimulator service backed by a command executor.
  public init(
    commandExecutor: CommandExecutor = CommandExecutor(),
    selectedXcodePathTimeout: TimeInterval? = Self.defaultSelectedXcodePathTimeout,
    listTimeout: TimeInterval? = Self.defaultListTimeout,
    openSimulatorAppTimeout: TimeInterval? = Self.defaultOpenSimulatorAppTimeout,
    deviceCommandTimeout: TimeInterval? = Self.defaultDeviceCommandTimeout,
    makePushPayloadURL: @escaping () -> URL = Self.defaultPushPayloadURL,
    writePushPayload: @escaping (String, URL) throws -> Void = Self.defaultWritePushPayload,
    removePushPayload: @escaping (URL) -> Void = Self.defaultRemovePushPayload,
    now: @escaping () -> Date = Date.init,
    makeID: @escaping () -> String = { UUID().uuidString }
  ) {
    self.selectedXcodePathTimeout = selectedXcodePathTimeout
    self.listTimeout = listTimeout
    self.openSimulatorAppTimeout = openSimulatorAppTimeout
    self.deviceCommandTimeout = deviceCommandTimeout
    self.makePushPayloadURL = makePushPayloadURL
    self.writePushPayload = writePushPayload
    self.removePushPayload = removePushPayload
    self.now = now
    self.makeID = makeID
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
    makePushPayloadURL: @escaping () -> URL = Self.defaultPushPayloadURL,
    writePushPayload: @escaping (String, URL) throws -> Void = Self.defaultWritePushPayload,
    removePushPayload: @escaping (URL) -> Void = Self.defaultRemovePushPayload,
    now: @escaping () -> Date = Date.init,
    makeID: @escaping () -> String = { UUID().uuidString },
    runCommand: @escaping CommandRunner
  ) {
    self.selectedXcodePathTimeout = selectedXcodePathTimeout
    self.listTimeout = listTimeout
    self.openSimulatorAppTimeout = openSimulatorAppTimeout
    self.deviceCommandTimeout = deviceCommandTimeout
    self.makePushPayloadURL = makePushPayloadURL
    self.writePushPayload = writePushPayload
    self.removePushPayload = removePushPayload
    self.now = now
    self.makeID = makeID
    self.runCommand = runCommand
  }

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

  /// Opens Simulator.app without mutating UI state.
  /// Opens Simulator.app.
  public func openSimulatorApp() async -> CommandResult {
    await runCommand(
      "open",
      ["-a", "Simulator"],
      openSimulatorAppTimeout
    )
  }

  /// Boots the simulator device identified by CoreSimulator UDID.
  /// Boots a simulator device.
  public func bootDevice(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "boot", id],
      deviceCommandTimeout
    )
  }

  /// Boots the simulator if needed and waits until it finishes booting.
  /// Boots a simulator device and waits for boot completion.
  public func bootDeviceIfNeeded(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "bootstatus", id, "-b"],
      deviceCommandTimeout
    )
  }

  /// Shuts down the simulator device identified by CoreSimulator UDID.
  /// Shuts down a simulator device.
  public func shutdownDevice(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "shutdown", id],
      deviceCommandTimeout
    )
  }

  /// Creates a simulator device with the provided device type and runtime identifiers.
  /// Creates a simulator device.
  public func createDevice(
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
  /// Clones a simulator device.
  public func cloneDevice(id: String, name: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "clone", id, name],
      deviceCommandTimeout
    )
  }

  /// Renames an existing simulator device.
  /// Renames a simulator device.
  public func renameDevice(id: String, name: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "rename", id, name],
      deviceCommandTimeout
    )
  }

  /// Erases the contents and settings of a simulator device.
  /// Erases a simulator device.
  public func eraseDevice(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "erase", id],
      deviceCommandTimeout
    )
  }

  /// Deletes a simulator device.
  /// Deletes a simulator device.
  public func deleteDevice(id: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "delete", id],
      deviceCommandTimeout
    )
  }

  /// Creates a watch and phone simulator pair.
  /// Pairs a watch simulator with a phone simulator.
  public func pairDevices(watchDeviceID: String, phoneDeviceID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "pair", watchDeviceID, phoneDeviceID],
      deviceCommandTimeout
    )
  }

  /// Removes an existing watch and phone simulator pair.
  /// Removes a simulator pair.
  public func unpairDevice(pairID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "unpair", pairID],
      deviceCommandTimeout
    )
  }

  /// Launches an installed app on a simulator device.
  /// Launches an installed app on a simulator device.
  public func launchApp(deviceID: String, bundleID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "launch", deviceID, bundleID],
      deviceCommandTimeout
    )
  }

  /// Terminates an installed app on a simulator device.
  /// Terminates an installed app on a simulator device.
  public func terminateApp(deviceID: String, bundleID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "terminate", deviceID, bundleID],
      deviceCommandTimeout
    )
  }

  /// Uninstalls an app from a simulator device.
  /// Uninstalls an app from a simulator device.
  public func uninstallApp(deviceID: String, bundleID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "uninstall", deviceID, bundleID],
      deviceCommandTimeout
    )
  }

  /// Installs an app bundle on a simulator device.
  /// Installs an app bundle on a simulator device.
  public func installApp(deviceID: String, appBundlePath: URL) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "install", deviceID, appBundlePath.path],
      deviceCommandTimeout
    )
  }

  /// Prints the path of an installed app container.
  /// Resolves an app container path through `simctl`.
  public func getAppContainer(
    deviceID: String,
    bundleID: String,
    container: SimulatorAppContainerKind
  ) async -> CommandResult {
    await runCommand(
      "xcrun",
      [
        "simctl",
        "get_app_container",
        deviceID,
        bundleID,
        container.simctlArgument
      ],
      deviceCommandTimeout
    )
  }

  /// Opens a URL on a simulator device.
  /// Opens a URL in a simulator device.
  public func openURL(deviceID: String, urlString: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "openurl", deviceID, urlString],
      deviceCommandTimeout
    )
  }

  /// Sends a simulated push notification payload to a simulator app.
  /// Sends a push notification payload to a simulator device.
  public func pushNotification(
    deviceID: String,
    bundleID: String?,
    payloadJSON: String
  ) async -> CommandResult {
    let payloadURL = makePushPayloadURL()
    let startedAt = now()
    var arguments = ["simctl", "push", deviceID]

    if let bundleID, !bundleID.isEmpty {
      arguments.append(bundleID)
    }

    arguments.append(payloadURL.path)

    do {
      try writePushPayload(payloadJSON, payloadURL)
    } catch {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "Push payload could not be written: \(error.localizedDescription)",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    defer {
      removePushPayload(payloadURL)
    }

    return await runCommand(
      "xcrun",
      arguments,
      deviceCommandTimeout
    )
  }

  /// Grants, revokes, or resets a simulator privacy permission.
  /// Sets a simulator privacy permission.
  public func setPrivacyPermission(
    deviceID: String,
    action: String,
    service: String,
    bundleID: String?
  ) async -> CommandResult {
    var arguments = ["simctl", "privacy", deviceID, action, service]

    if let bundleID, !bundleID.isEmpty {
      arguments.append(bundleID)
    }

    return await runCommand(
      "xcrun",
      arguments,
      deviceCommandTimeout
    )
  }

  /// Sets a fixed simulator location.
  /// Sets the simulator location.
  public func setLocation(deviceID: String, coordinate: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "location", deviceID, "set", coordinate],
      deviceCommandTimeout
    )
  }

  /// Clears any simulated location from a simulator device.
  /// Clears the simulator location override.
  public func clearLocation(deviceID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "location", deviceID, "clear"],
      deviceCommandTimeout
    )
  }

  /// Applies simulator status bar override arguments.
  /// Sets simulator status bar override arguments.
  public func setStatusBarOverride(deviceID: String, arguments overrideArguments: [String]) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "status_bar", deviceID, "override"] + overrideArguments,
      deviceCommandTimeout
    )
  }

  /// Clears all simulator status bar overrides.
  /// Clears simulator status bar overrides.
  public func clearStatusBarOverride(deviceID: String) async -> CommandResult {
    await runCommand(
      "xcrun",
      ["simctl", "status_bar", deviceID, "clear"],
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

  private func commandResult(
    arguments: [String],
    stdout: String,
    stderr: String,
    exitCode: Int32,
    startedAt: Date
  ) -> CommandResult {
    CommandResult(
      id: "core-simulator-service-\(makeID())",
      executable: "xcrun",
      arguments: arguments,
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      duration: max(0, now().timeIntervalSince(startedAt)),
      startedAt: startedAt
    )
  }

  @usableFromInline static func defaultPushPayloadURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("SimControl-PushPayload-\(UUID().uuidString).json")
  }

  @usableFromInline static func defaultWritePushPayload(_ payloadJSON: String, to url: URL) throws {
    try payloadJSON.write(to: url, atomically: true, encoding: .utf8)
  }

  @usableFromInline static func defaultRemovePushPayload(_ url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
