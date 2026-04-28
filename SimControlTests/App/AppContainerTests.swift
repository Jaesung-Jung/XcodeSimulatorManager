import Testing
@testable import SimControl

@MainActor
@Suite
struct AppContainerTests {
  @Test func holdsStableStoreInstances() {
    let container = AppContainer()

    let simulatorStore = container.simulatorStore
    let settingsStore = container.settingsStore
    let actionLogStore = container.actionLogStore

    #expect(container.simulatorStore === simulatorStore)
    #expect(container.settingsStore === settingsStore)
    #expect(container.actionLogStore === actionLogStore)
  }

  @Test func holdsStableRepositoryInstance() {
    let container = AppContainer()

    let simulatorRepository = container.simulatorRepository

    #expect(container.simulatorRepository === simulatorRepository)
  }
}
