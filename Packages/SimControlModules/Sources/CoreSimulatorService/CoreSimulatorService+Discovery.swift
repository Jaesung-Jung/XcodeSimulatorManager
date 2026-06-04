import Foundation
import SimControlDomain

extension CoreSimulatorService {
  /// Returns the active Xcode developer path reported by `xcode-select -p`.
  public func selectedXcodePath() async -> DeveloperPathResult {
    let commandResult = await runCommand("xcode-select", ["-p"], selectedXcodePathTimeout)

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
    let commandResult = await runCommand("xcrun", ["simctl", "list", "-j"], listTimeout)

    guard commandResult.succeeded else {
      return ListResult(
        payload: nil,
        commandResult: commandResult,
        diagnostic: commandFailureDiagnostic(command: "xcrun simctl list -j", result: commandResult)
      )
    }

    do {
      let payload = try JSONDecoder().decode(SimctlListPayload.self, from: Data(commandResult.stdout.utf8))

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

  /// Runs `simctl listapps` and decodes installed app container metadata.
  public func listApps(deviceID: String) async -> ListAppsResult {
    let commandResult = await runCommand("xcrun", ["simctl", "listapps", deviceID], listTimeout)

    guard commandResult.succeeded else {
      return ListAppsResult(
        appsByBundleID: [:],
        commandResult: commandResult,
        diagnostic: commandFailureDiagnostic(command: "xcrun simctl listapps \(deviceID)", result: commandResult)
      )
    }

    do {
      return ListAppsResult(
        appsByBundleID: try listedApps(from: commandResult.stdout),
        commandResult: commandResult,
        diagnostic: nil
      )
    } catch {
      return ListAppsResult(
        appsByBundleID: [:],
        commandResult: commandResult,
        diagnostic: "Failed to decode simctl listapps plist: \(error.localizedDescription)"
      )
    }
  }

  /// Opens Simulator.app.
  public func openSimulatorApp() async -> CommandResult {
    await runCommand("open", ["-a", "Simulator"], openSimulatorAppTimeout)
  }

  private func listedApps(from output: String) throws -> [String: ListedApp] {
    let plist = try PropertyListSerialization.propertyList(
      from: Data(output.utf8),
      options: [],
      format: nil
    )
    guard let apps = plist as? [String: Any] else {
      return [:]
    }

    return apps.reduce(into: [:]) { result, element in
      let bundleID = element.key
      guard let metadata = element.value as? [String: Any] else {
        return
      }

      let appBundlePath = url(from: metadata["Path"]) ?? url(from: metadata["Bundle"])
      let dataContainer = url(from: metadata["DataContainer"])
      let groupContainers = (metadata["GroupContainers"] as? [String: Any] ?? [:])
        .reduce(into: [String: URL]()) { groups, element in
          groups[element.key] = url(from: element.value)
        }

      result[bundleID] = ListedApp(
        bundleID: bundleID,
        appBundlePath: appBundlePath,
        dataContainer: dataContainer,
        groupContainers: groupContainers
      )
    }
  }

  private func url(from value: Any?) -> URL? {
    if let url = value as? URL {
      return url
    }

    guard let path = value as? String,
          !path.isEmpty
    else {
      return nil
    }

    if path.hasPrefix("file://") {
      return URL(string: path)?.standardizedFileURL
    }

    return URL(fileURLWithPath: path).standardizedFileURL
  }
}
