import CommandExecutionService
import Testing

@Suite("CommandExecutionServiceTests")
struct CommandExecutionServiceTests {
  @Test func commandExecutorCanBeConstructedAcrossModules() {
    _ = CommandExecutor()
  }
}
