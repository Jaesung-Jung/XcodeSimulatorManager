import Testing
@testable import SimControl

@MainActor
@Suite("AppContainerTests")
struct AppContainerTests {
  @Test func holdsStableMainWindowStoreInstance() {
    let container = AppContainer()

    let mainWindowStore = container.mainWindowStore

    #expect(container.mainWindowStore === mainWindowStore)
  }

  @Test func holdsStableRepositoryInstance() {
    let container = AppContainer()

    let simulatorRepository = container.simulatorRepository

    #expect(container.simulatorRepository === simulatorRepository)
  }
}
