import Foundation
import MainWindowWorkflows
import SimControlClients
import SimControlDomain
import Testing

@Suite("InventoryWorkflowClient")
struct InventoryWorkflowClientTests {
  @Test("refresh delegates to simulator repository client")
  func refreshDelegatesToSimulatorRepositoryClient() async {
    let expectedResult = makeRefreshResult()
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      expectedResult
    }
    let workflow = InventoryWorkflowClient.live(
      simulatorRepository: repository,
      coreSimulatorService: CoreSimulatorClient.testValue
    )

    let result = await workflow.refresh()

    #expect(result == expectedResult)
  }

  @Test("open simulator delegates to core simulator client")
  func openSimulatorDelegatesToCoreSimulatorClient() async {
    let expectedResult = makeCommandResult(id: "open-simulator")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.openSimulatorApp = {
      expectedResult
    }
    let workflow = InventoryWorkflowClient.live(
      simulatorRepository: SimulatorRepositoryClient.testValue,
      coreSimulatorService: coreSimulator
    )

    let result = await workflow.openSimulatorApp()

    #expect(result == expectedResult)
  }
}

extension InventoryWorkflowClientTests {
  private func makeRefreshResult() -> SimulatorRefreshResult {
    SimulatorRefreshResult(
      snapshot: nil,
      xcodeCommandResult: makeCommandResult(id: "xcode"),
      listCommandResult: makeCommandResult(id: "list"),
      diagnostic: "test"
    )
  }

  private func makeCommandResult(id: String) -> CommandResult {
    CommandResult(
      id: id,
      executable: "test",
      arguments: [id],
      stdout: "",
      stderr: "",
      exitCode: 0,
      duration: 0,
      startedAt: Date(timeIntervalSince1970: 0)
    )
  }
}
