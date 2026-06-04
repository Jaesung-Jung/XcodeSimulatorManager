import SimControlDomain

extension CoreSimulatorService {
  /// Boots a simulator device.
  public func bootDevice(id: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "boot", id], deviceCommandTimeout)
  }

  /// Boots a simulator device and waits for boot completion.
  public func bootDeviceIfNeeded(id: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "bootstatus", id, "-b"], deviceCommandTimeout)
  }

  /// Shuts down a simulator device.
  public func shutdownDevice(id: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "shutdown", id], deviceCommandTimeout)
  }

  /// Creates a simulator device.
  public func createDevice(name: String, deviceTypeID: String, runtimeID: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "create", name, deviceTypeID, runtimeID], deviceCommandTimeout)
  }

  /// Clones a simulator device.
  public func cloneDevice(id: String, name: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "clone", id, name], deviceCommandTimeout)
  }

  /// Renames a simulator device.
  public func renameDevice(id: String, name: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "rename", id, name], deviceCommandTimeout)
  }

  /// Erases a simulator device.
  public func eraseDevice(id: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "erase", id], deviceCommandTimeout)
  }

  /// Deletes a simulator device.
  public func deleteDevice(id: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "delete", id], deviceCommandTimeout)
  }

  /// Pairs a watch simulator with a phone simulator.
  public func pairDevices(watchDeviceID: String, phoneDeviceID: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "pair", watchDeviceID, phoneDeviceID], deviceCommandTimeout)
  }

  /// Removes a simulator pair.
  public func unpairDevice(pairID: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "unpair", pairID], deviceCommandTimeout)
  }
}
