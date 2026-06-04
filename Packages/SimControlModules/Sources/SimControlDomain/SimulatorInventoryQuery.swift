import Foundation

/// A pure query object that projects simulator inventory for feature state.
///
/// `SimulatorInventoryQuery` owns filtering, sorting, exact-search navigation,
/// and selected-target reconciliation. It does not create feature state, run
/// commands, access files, or import UI frameworks.
public struct SimulatorInventoryQuery: Equatable {
  /// The simulator inventory snapshot being projected.
  public var snapshot: SimulatorSnapshot

  /// The filter and sort options used to project the snapshot.
  public var filters: SimulatorFilters

  /// Creates an inventory query for a snapshot and filter set.
  public init(snapshot: SimulatorSnapshot, filters: SimulatorFilters) {
    self.snapshot = snapshot
    self.filters = filters
  }

  /// All devices from the snapshot.
  public var devices: [SimulatorDevice] {
    snapshot.devices
  }

  /// Runtimes keyed by runtime identifier.
  public var runtimeByID: [String: SimulatorRuntime] {
    Dictionary(uniqueKeysWithValues: snapshot.runtimes.map { ($0.id, $0) })
  }

  /// Device types keyed by device type identifier.
  public var deviceTypeByID: [String: SimulatorDeviceType] {
    Dictionary(uniqueKeysWithValues: snapshot.deviceTypes.map { ($0.id, $0) })
  }

  /// Devices keyed by device identifier.
  public var deviceByID: [String: SimulatorDevice] {
    Dictionary(uniqueKeysWithValues: snapshot.devices.map { ($0.id, $0) })
  }
}
