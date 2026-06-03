import Foundation
import MainWindowWorkflows
import SimControlClients
import SimControlDomain
import Testing

@Suite("DeviceLifecycleWorkflowClient")
struct DeviceLifecycleWorkflowClientTests {
  @Test("create device runs command, refreshes, and derives preferred device ID")
  func createDeviceRunsCommandRefreshesAndDerivesPreferredDeviceID() async {
    let recorder = DeviceLifecycleRecorder()
    let commandResult = makeCommandResult(
      id: "create",
      stdout: "\n CREATED-DEVICE \n"
    )
    let refreshResult = makeRefreshResult(id: "refresh")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.createDevice = { name, deviceTypeID, runtimeID in
      await recorder.recordCreate(
        name: name,
        deviceTypeID: deviceTypeID,
        runtimeID: runtimeID
      )
      return commandResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      refreshResult
    }
    let workflow = DeviceLifecycleWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      simulatorRepository: repository
    )

    let result = await workflow.createDevice("iPhone Test", "device-type", "runtime")

    #expect(result == DeviceLifecycleWorkflowResult(
      commandResult: commandResult,
      refreshResult: refreshResult,
      preferredSelectedDeviceID: "CREATED-DEVICE"
    ))
    #expect(await recorder.createCalls() == [
      CreateDeviceCall(
        name: "iPhone Test",
        deviceTypeID: "device-type",
        runtimeID: "runtime"
      )
    ])
  }

  @Test("rename device refreshes without preferred selection")
  func renameDeviceRefreshesWithoutPreferredSelection() async {
    let commandResult = makeCommandResult(id: "rename")
    let refreshResult = makeRefreshResult(id: "refresh")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.renameDevice = { _, _ in
      commandResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      refreshResult
    }
    let workflow = DeviceLifecycleWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      simulatorRepository: repository
    )

    let result = await workflow.renameDevice("DEVICE-1", "Renamed")

    #expect(result == DeviceLifecycleWorkflowResult(
      commandResult: commandResult,
      refreshResult: refreshResult,
      preferredSelectedDeviceID: nil
    ))
  }

  @Test("pair devices preserves watch then phone order")
  func pairDevicesPreservesWatchThenPhoneOrder() async {
    let recorder = DeviceLifecycleRecorder()
    let commandResult = makeCommandResult(id: "pair")
    let refreshResult = makeRefreshResult(id: "refresh")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.pairDevices = { watchDeviceID, phoneDeviceID in
      await recorder.recordPair(
        watchDeviceID: watchDeviceID,
        phoneDeviceID: phoneDeviceID
      )
      return commandResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      refreshResult
    }
    let workflow = DeviceLifecycleWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      simulatorRepository: repository
    )

    let result = await workflow.pairDevices("WATCH-1", "PHONE-1")

    #expect(result.commandResult == commandResult)
    #expect(result.refreshResult == refreshResult)
    #expect(await recorder.pairCalls() == [
      PairDevicesCall(watchDeviceID: "WATCH-1", phoneDeviceID: "PHONE-1")
    ])
  }
}

private struct CreateDeviceCall: Equatable, Sendable {
  let name: String
  let deviceTypeID: String
  let runtimeID: String
}

private struct PairDevicesCall: Equatable, Sendable {
  let watchDeviceID: String
  let phoneDeviceID: String
}

private actor DeviceLifecycleRecorder {
  private var recordedCreateCalls: [CreateDeviceCall] = []
  private var recordedPairCalls: [PairDevicesCall] = []

  func recordCreate(
    name: String,
    deviceTypeID: String,
    runtimeID: String
  ) {
    recordedCreateCalls.append(
      CreateDeviceCall(
        name: name,
        deviceTypeID: deviceTypeID,
        runtimeID: runtimeID
      )
    )
  }

  func recordPair(
    watchDeviceID: String,
    phoneDeviceID: String
  ) {
    recordedPairCalls.append(
      PairDevicesCall(
        watchDeviceID: watchDeviceID,
        phoneDeviceID: phoneDeviceID
      )
    )
  }

  func createCalls() -> [CreateDeviceCall] {
    recordedCreateCalls
  }

  func pairCalls() -> [PairDevicesCall] {
    recordedPairCalls
  }
}

private func makeRefreshResult(id: String) -> SimulatorRefreshResult {
  SimulatorRefreshResult(
    snapshot: nil,
    xcodeCommandResult: makeCommandResult(id: "\(id)-xcode"),
    listCommandResult: makeCommandResult(id: "\(id)-list"),
    diagnostic: nil
  )
}

private func makeCommandResult(
  id: String,
  stdout: String = ""
) -> CommandResult {
  CommandResult(
    id: id,
    executable: "test",
    arguments: [id],
    stdout: stdout,
    stderr: "",
    exitCode: 0,
    duration: 0,
    startedAt: Date(timeIntervalSince1970: 0)
  )
}
