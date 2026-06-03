import SimControlDomain
import SwiftUI

extension SimulatorWarning.Severity {
  public var displayTitle: String {
    switch self {
    case .info:
      "Info"
    case .warning:
      "Warning"
    case .error:
      "Error"
    }
  }

  public var badgeTint: Color {
    switch self {
    case .info:
      .blue
    case .warning:
      .orange
    case .error:
      .red
    }
  }
}
