import ComposableArchitecture

/// A settings section feature for Xcode selection preferences.
@Reducer
public struct XcodeSettingsFeature {
  /// Creates the Xcode settings reducer.
  public init() {}

  /// State for Xcode selection preferences.
  @ObservableState
  public struct State: Equatable {
    public var preferredXcodeDeveloperPath: String

    /// Creates Xcode settings state from a preferred developer directory path.
    public init(preferredXcodeDeveloperPath: String = "") {
      self.preferredXcodeDeveloperPath = preferredXcodeDeveloperPath
    }
  }

  /// User actions that mutate Xcode selection preferences.
  public enum Action: Equatable {
    case preferredXcodeDeveloperPathChanged(String)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .preferredXcodeDeveloperPathChanged(let preferredXcodeDeveloperPath):
        state.preferredXcodeDeveloperPath = preferredXcodeDeveloperPath
        return .none
      }
    }
  }
}
