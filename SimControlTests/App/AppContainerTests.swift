import SimControlDomain
import Testing
@testable import SimControl

@MainActor
@Suite
struct AppContainerTests {
  @Test func holdsStableStoreInstances() {
    let container = AppContainer()

    let settingsStore = container.settingsStore
    let actionLogStore = container.actionLogStore
    let mainWindowStore = container.mainWindowStore

    #expect(container.settingsStore === settingsStore)
    #expect(container.actionLogStore === actionLogStore)
    #expect(container.mainWindowStore === mainWindowStore)
  }

  @Test func holdsStableRepositoryInstance() {
    let container = AppContainer()

    let simulatorRepository = container.simulatorRepository

    #expect(container.simulatorRepository === simulatorRepository)
  }
}
