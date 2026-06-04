import CommandExecutionService
import Testing

@Suite
struct CommandExecutionServiceTests {
  @Test func commandExecutorCanBeConstructedAcrossModules() {
    _ = CommandExecutor()
  }
}
