import ComposableArchitecture

/// A settings section feature for Xcode selection preferences.
@Reducer
public struct XcodeSettingsFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var preferredXcodeDeveloperPath: String

    public init(preferredXcodeDeveloperPath: String = "") {
      self.preferredXcodeDeveloperPath = preferredXcodeDeveloperPath
    }
  }

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
