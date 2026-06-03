import Foundation
import SimControlDomain
import Testing
@testable import SimControl

@MainActor
@Suite
struct PathActionServiceTests {
  @Test func existingReadablePathOpenReturnsSuccess() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    var openedURLs: [URL] = []
    let service = makeService(openURL: { url in
      openedURLs.append(url)
      return true
    })

    let result = await service.openInFinder(directory, label: "device data folder")

    #expect(result.succeeded)
    #expect(result.executable == "SimControl")
    #expect(result.arguments == ["open-finder", directory.path])
    #expect(result.stdout == "Opened device data folder path: \(directory.path)")
    #expect(openedURLs == [directory])
  }

  @Test func missingPathAndPermissionDeniedReturnDistinctFailures() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let missingPath = directory.appendingPathComponent("Missing", isDirectory: true)
    let service = makeService(isReadable: { url in
      url != directory
    })

    let missingResult = await service.openInFinder(missingPath, label: "device log folder")
    let permissionResult = await service.openInFinder(directory, label: "device data folder")

    #expect(!missingResult.succeeded)
    #expect(missingResult.exitCode == 1)
    #expect(missingResult.stderr == "device log folder path does not exist: \(missingPath.path)")
    #expect(!permissionResult.succeeded)
    #expect(permissionResult.exitCode == 13)
    #expect(permissionResult.stderr == "Permission denied for device data folder path: \(directory.path)")
  }

  @Test func finderOpenFailureReturnsFailureResult() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let service = makeService(openURL: { _ in
      false
    })

    let result = await service.openInFinder(directory, label: "app data container")

    #expect(!result.succeeded)
    #expect(result.stderr == "Finder could not open app data container path: \(directory.path)")
  }

  @Test func copyFailureReturnsFailureResult() async {
    let service = makeService(copyString: { _ in
      false
    })

    let result = await service.copy("/tmp/Example", label: "device data path")

    #expect(!result.succeeded)
    #expect(result.arguments == ["copy", "/tmp/Example"])
    #expect(result.stderr == "device data path could not be copied to the clipboard.")
  }

  private func makeService(
    isReadable: @escaping (URL) -> Bool = { _ in true },
    openURL: @escaping @MainActor (URL) -> Bool = { _ in true },
    copyString: @escaping @MainActor (String) -> Bool = { _ in true }
  ) -> PathActionService {
    PathActionService(
      isReadable: isReadable,
      openURL: openURL,
      copyString: copyString,
      now: { Date(timeIntervalSince1970: 100) },
      makeID: { "test" }
    )
  }

  private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "SimControlPathActionTests-\(UUID().uuidString)",
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: url,
      withIntermediateDirectories: true
    )
    return url
  }
}
