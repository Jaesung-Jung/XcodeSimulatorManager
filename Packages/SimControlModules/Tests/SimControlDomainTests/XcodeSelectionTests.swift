import Foundation
import Testing
import SimControlDomain

@MainActor
@Suite
struct XcodeSelectionTests {
  @Test func preservesValidDeveloperPathAndVersion() {
    let developerPath = URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer")
    let selection = XcodeSelection(
      developerPath: developerPath,
      version: "17.0",
      isValid: true
    )

    #expect(selection.developerPath == developerPath)
    #expect(selection.version == "17.0")
    #expect(selection.isValid)
  }

  @Test func supportsInvalidMissingSelection() {
    let selection = XcodeSelection(
      developerPath: nil,
      version: nil,
      isValid: false
    )

    #expect(selection.developerPath == nil)
    #expect(selection.version == nil)
    #expect(!selection.isValid)
  }
}
