# Coding Conventions

## Core Principles

- Match the indentation, line breaks, naming, and access control style of the file you are editing.
- Reuse patterns that already appear in nearby files.
- Prefer a simple extension of the current code over a new abstraction.
- Do not change formatting, names, or structure outside the scope of the requested change.
- Write code so the role is clear from the call site.
- Do not over-extract short logic that is used only once.

Do not:

- Create a function, type, or option only because it might be useful later.
- Introduce new naming, helpers, or namespaces without checking existing patterns first.
- Present a simple substitution or thin wrapper as meaningful design.

## Formatting

- Use 2 spaces for indentation.
- Do not use tab characters.
- Keep declarations and calls on one line by default when they are 150 columns or shorter.
- Write `guard` statements across multiple lines by default, even when the body is short.
- Write early-exit `if` statements across multiple lines by default, even when the body is short.
- Do not add line breaks only because there are multiple parameters or conditions.
- Use multiple lines only for code over 150 columns, nested closures, nested collections or literals, or long trailing closures.
- Put each multiline parameter on its own line.
- Put each step of a long method chain on its own line.
- Write array and dictionary literals vertically without trailing commas.
- Prefer one-line single-expression computed properties.

Example:

```swift
var itemSpacing: CGFloat { margins * 0.5 }

guard !ids.isEmpty else {
  return
}

if ids.isEmpty {
  return
}
```

Do not:

- Mechanically expand simple calls of 150 columns or shorter across multiple lines.
- Force long closures or generic declarations onto one line.
- Break modifier chains, test flow, or property groups with meaningless blank lines.

## Naming

- Use `UpperCamelCase` for types, protocols, and nested types.
- Use `lowerCamelCase` for functions, properties, variables, and enum cases.
- Prefer `is`, `has`, `can`, or `should` prefixes for Booleans.
- Keep only established abbreviations in uppercase.
  - Allowed: `URL`, `ID`, `UUID`, `DB`
- Names should reveal their role.
  - Good: `BookLibrary`, `BookThumbnailLoader`, `libraryUpdated`
  - Bad: `Manager`, `Helper`, `Util`
- Group subordinate concepts of the same type as nested types.
  - Example: `BookThumbnailLoader.Request`, `BookStorage.Package.Resource`

Do not:

- Use vague generic names as the default for new types.
- Create arbitrary abbreviations.
- Use Korean in test function names.
- Function names should be English `lowerCamelCase`; `@Test` display names may use Korean.

## Access Control

- Mark external module contracts as `public`.
- Use the default access level, `internal`, for collaboration points inside the same module.
- Usually omit `internal` because it is the default.
- Use `private` only when the restriction is genuinely needed.
  - Protecting invariants
  - Preventing external calls
  - Hiding implementation details that are meaningful only within a file or type
- Use `fileprivate` only when there is a specific reason.

Decision criteria:

- Use `internal` when another file in the same target or test support code should naturally use it.
- Use `private` for stored closures or internal state that would blur the type contract if called directly.
- Use `public` only for APIs that must be used outside the module.

Do not:

- Reflexively make new helpers `private`.
- Make internal types `public` for implementation convenience.
- Over-restrict access levels only because encapsulation seems better.

## Static

- Use `static` functions and variables only when truly needed.
- Allow them only for values that belong to the meaning of the type itself or are independent of any instance.
  - Examples: design tokens, fixture constants, clear type-level factories
- Express behavior that needs instance state, environment, or dependencies as an instance API or injected closure.
- Use a `static` factory for complex creation logic only when it makes the call site clearer.

Do not:

- Promote behavior to `static` only because creating an instance is inconvenient.
- Create `static` APIs to avoid dependency injection.
- Put shared state in `static` storage only for test convenience.
- Add a `static func` or `static let` only for convenience.

## Type and Function Design

- Prefer `struct` for value models.
- Declare `Sendable`, `Hashable`, and `Identifiable` when needed.
- Prefer the domain port pattern of a `Sendable` struct that stores closures.
- Public methods should act as thin contracts around stored closures.
- Prefer computed properties for derived values when they are reused or when the name improves call-site meaning.
- Do not extract values that are passed only once into computed properties; create them directly at the call site.
- Use functions for behavior that takes parameters and performs work.
- Extract a function only when one of the following is clear.
  - Reuse
  - Creating a test boundary
  - A name explains the behavior better than the body
  - Hiding a complex branch or operation to simplify the call site
- Keep `init` thin and focused on stored property assignment.
- Spell out the type name instead of using `.init(...)` when the constructed type should explain call-site meaning, such as enum associated values, state transitions, or test expectations.
  - Example: `.completed(ImportSummary(results: results))`, `.failed(ImportFailure(error: error))`
- When splitting nested types of a parent type into separate files, use a separate `extension ParentType { ... }` block for each type and place `// MARK: - ParentType.NestedType` before each block.

Do not:

- Extract simple value substitutions, short branches used only once, or wrappers whose names are weaker than their bodies into functions.
- Add a computed property that only hides a constructor call at a single call site.
- Create helpers with names that are more ambiguous than the call site.
- Put I/O, DB migration, and dependency assembly all inside an initializer.
- Add protocols only to create test doubles.
- Hide constructed types without context, such as `.completed(.init(...))` or `.failed(.init(...))`.
- Put multiple nested types split into separate files into one large parent extension block.

## Control Flow, Async, Error

- Remove failure paths first with `guard` and keep the happy path left-aligned.
- Use `switch` by default for enum branches and state transitions.
- Do not use `fallthrough`.
- Use `throws` for whole-operation failure.
- Use `[Result<...>]` for per-item partial failure.
- Use `nil` for absence or unsupported cases.
- Use `async/await` by default for async APIs.
- Use `@Sendable` for async closures and dependency contracts.
- Use `AsyncThrowingStream` for observation-style APIs.
- Connect task cancellation or resource cleanup in `onTermination` for streams.
- Use `@unchecked Sendable` only when thread safety is guaranteed by code.

Do not:

- Collapse partial failure into whole-operation `throws`.
- Treat absence and errors as the same meaning.
- Reflect cancellation in state as an ordinary error.
- Use `DispatchQueue` as the default tool in new async code.
- Use `try?` in main operations that must propagate failure.

## SwiftUI and TCA

- Split state and logic into `XxxFeature` and rendering into `XxxView`.
- Declare features in this order: `State`, `Action`, dependencies, `body`.
- Inject `StoreOf<XxxFeature>` into views.
- Use `@Bindable var store` when a view must send binding actions.
- Use `let store` when the view only needs reads and action sends.
- Use cancellation IDs and `cancelInFlight: true` for long-running effects.
- Use `.localizable(...)` for user-facing strings.
- Prefer `.ds` design system tokens for colors, fonts, and animations.
- Keep preview dependencies in preview code only.

Do not:

- Create live dependencies or stores directly in views.
- Bypass domain state management with `@State`.
- Hardcode user-facing strings such as `Text("Library")`.
- Repeat arbitrary color, font, or animation constants screen by screen.

## Testing

- Use Swift Testing.
- Prefer the `@Suite("...") struct ...Tests` format.
- Use English `lowerCamelCase` for test function names.
- Use Korean scenario text for `@Test` display names.
- Use `#expect` for assertions and `#require` for required unwraps.
- Prefer `arguments:` for parameterization.
- In TCA tests, verify effect lifetimes with `send`, `receive`, `finish`, and `cancel` on `TestStore`.
- Prefer reusing fixtures and helpers from `ReadinTestSupport` for test data.
- Clarify intent for async test doubles with actors, locks, `confirmation`, and `Issue.record`.
- Group helpers in an `extension ...Tests` at the bottom of the file.

Do not:

- Use XCTest assertions as the default for new tests.
- Rewrite the same stub builder in each test when a shared helper exists.
- Reference fixture files across test directories with relative paths.
- Write to real user directories or app support directories.

## Comments and Documentation

- Add `///` documentation comments to public types and methods.
- Documentation comments should explain contracts, parameters, return values, and call context rather than implementation details.
- Use internal comments only when the reason is not clear from the code alone.
- Use `// MARK: -` when structural separation is needed.
- Express test intent with `@Test` display names rather than comments.

Do not:

- Repeat what the code already says in comments.
- Leave debug `print` statements behind.
- Leave `TODO` comments as a way to avoid finishing work.
