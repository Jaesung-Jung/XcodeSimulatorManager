import Foundation
import Observation

@MainActor
@Observable
final class SimulatorStore {
  enum RefreshState: Equatable {
    case idle
    case refreshing
    case failed(diagnostic: String)
  }

  enum InstalledAppsAvailability: Equatable {
    case notLoaded
    case loaded
  }

  typealias RefreshProvider = () async -> SimulatorRepository.RefreshResult

  private(set) var snapshot: SimulatorSnapshot?
  private(set) var refreshState: RefreshState = .idle
  private(set) var selectedDeviceID: String?
  private(set) var selectedAppID: String?
  private(set) var lastCommandResults: [CommandResult] = []
  private(set) var installedAppsAvailability: InstalledAppsAvailability = .notLoaded

  @ObservationIgnored private let refreshProvider: RefreshProvider

  init(
    repository: SimulatorRepository = SimulatorRepository(),
    installedAppsAvailability: InstalledAppsAvailability = .notLoaded
  ) {
    self.installedAppsAvailability = installedAppsAvailability
    refreshProvider = {
      await repository.refresh()
    }
  }

  init(
    installedAppsAvailability: InstalledAppsAvailability = .notLoaded,
    refreshProvider: @escaping RefreshProvider
  ) {
    self.installedAppsAvailability = installedAppsAvailability
    self.refreshProvider = refreshProvider
  }

  func refresh() async {
    guard refreshState != .refreshing else {
      return
    }

    refreshState = .refreshing
    let result = await refreshProvider()
    lastCommandResults = commandResults(from: result)

    if let snapshot = result.snapshot, result.diagnostic == nil {
      self.snapshot = snapshot
      refreshState = .idle
      validateSelection(in: snapshot)
    } else {
      refreshState = .failed(
        diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
      )
    }
  }

  func selectDevice(id: String?) {
    guard selectedDeviceID != id else {
      return
    }

    selectedDeviceID = id
    selectedAppID = nil
  }

  func selectApp(id: String?) {
    selectedAppID = id
  }

  private func commandResults(
    from result: SimulatorRepository.RefreshResult
  ) -> [CommandResult] {
    var results = [result.xcodeCommandResult]

    if let listCommandResult = result.listCommandResult {
      results.append(listCommandResult)
    }

    return results
  }

  private func validateSelection(in snapshot: SimulatorSnapshot) {
    guard let selectedDeviceID else {
      selectedAppID = nil
      return
    }

    if !snapshot.devices.contains(where: { $0.id == selectedDeviceID }) {
      self.selectedDeviceID = nil
      selectedAppID = nil
      return
    }

    validateSelectedApp(in: snapshot, selectedDeviceID: selectedDeviceID)
  }

  private func validateSelectedApp(
    in snapshot: SimulatorSnapshot,
    selectedDeviceID: String
  ) {
    guard installedAppsAvailability == .loaded,
          let selectedAppID
    else {
      return
    }

    let installedApps = snapshot.installedAppsByDeviceID[selectedDeviceID] ?? []
    if !installedApps.contains(where: { $0.id == selectedAppID }) {
      self.selectedAppID = nil
    }
  }
}
