import SimControlDomain
import Testing

@Suite("SimControlDomain module")
struct ModuleTests {
  @Test("모듈을 import할 수 있다")
  func moduleCanBeImported() {
    #expect(SimControlDomainModule.name == "SimControlDomain")
  }
}
