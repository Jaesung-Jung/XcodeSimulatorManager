import Foundation
import Testing
import SimControlDomain

@MainActor
@Suite("AppGroupContainerTests")
struct AppGroupContainerTests {
  @Test func preservesGroupIdentifierAndPath() {
    let path = URL(fileURLWithPath: "/tmp/Groups/group.com.example")
    let container = AppGroupContainer(
      id: "group.com.example",
      groupID: "group.com.example",
      path: path
    )

    #expect(container.id == "group.com.example")
    #expect(container.groupID == "group.com.example")
    #expect(container.path == path)
  }

  @Test func equatableComparesStoredValues() {
    let path = URL(fileURLWithPath: "/tmp/Groups/group.com.example")
    let first = AppGroupContainer(
      id: "group.com.example",
      groupID: "group.com.example",
      path: path
    )
    let same = AppGroupContainer(
      id: "group.com.example",
      groupID: "group.com.example",
      path: path
    )

    #expect(first == same)
  }
}
