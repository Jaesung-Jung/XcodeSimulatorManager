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

  let runCommand: CommandRunner
  let makePushPayloadURL: () -> URL
  let writePushPayload: (String, URL) throws -> Void
  let removePushPayload: (URL) -> Void
  let now: () -> Date
  let makeID: () -> String
  let selectedXcodePathTimeout: TimeInterval?
  let listTimeout: TimeInterval?
  let openSimulatorAppTimeout: TimeInterval?
  let deviceCommandTimeout: TimeInterval?

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
}
