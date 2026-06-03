---
name: swiftui-patterns
description: Primary SwiftUI skill for new features, behavior-changing UI work, and normal UI evolution, including iOS 17+ Observation, state ownership, environment injection, navigation hierarchies, custom view modifiers, component patterns, and responsive layouts. Use this as the default entry point unless the task is specifically about runtime performance, Liquid Glass, advanced gesture/layout tradeoffs, or structure-only cleanup of an existing file with behavior preserved.
---

# SwiftUI UI Patterns

Use this as the default SwiftUI skill for most new feature work, behavior-changing edits, and normal UI evolution.

Do not use this skill when the job is only to clean up or split an existing view file while intentionally preserving behavior; use `swiftui-view-refactor` for that.

Choose a more specialized SwiftUI skill only when one concern is clearly primary:
- Runtime diagnosis, dropped frames, or invalidation analysis -> `swiftui-performance-audit`
- Liquid Glass adoption or review -> `swiftui-liquid-glass`
- Gesture composition, advanced animation, adaptive layout, or architecture tradeoffs -> `swiftui-advanced`
- Structure-only cleanup of an existing oversized view file -> `swiftui-view-refactor`

## Quick start

Choose a track based on your goal:

### UI composition and screen design

- Identify the feature or screen and the primary interaction model (list, detail, editor, settings, tabbed).
- Find a nearby example in the repo with `rg "TabView\("` or similar, then read the closest SwiftUI view.
- Apply local conventions: prefer SwiftUI-native state, keep state local when possible, and use environment injection for shared dependencies.
- Choose the relevant component reference from `references/components-index.md` and follow its guidance.
- If the interaction reveals secondary content by dragging or scrolling the primary content away, read `references/scroll-reveal.md` before implementing gestures manually.
- Build the view with small, focused subviews and SwiftUI-native data flow.

### Modern observation and state ownership

- If the feature owns reference state on iOS 17+, start with `references/observation.md` and `references/state-ownership.md`.
- If shared services or shared models are involved, read `references/environment-observation.md` and `references/app-wiring.md`.
- If you are editing legacy `ObservableObject` code, read `references/observation-migration.md` before changing wrappers or environment usage.
- If you are modernizing older SwiftUI APIs or replacing deprecated modifiers, read `references/latest-apis.md`.
- If bindings, lifecycle modifiers, or UIKit wrappers are involved, load `references/view-modifiers.md` or `references/uikit-interop.md`.
- For interactive surfaces, also read `references/accessibility.md` so layout and accessibility decisions stay aligned.

### New project scaffolding

- Start with `references/app-wiring.md` to wire TabView + NavigationStack + sheets.
- Add a minimal `AppTab` and `RouterPath` based on the provided skeletons.
- Choose the next component reference based on the UI you need first (TabView, NavigationStack, Sheets).
- Expand the route and sheet enums as new screens are added.

## General rules to follow

- Use modern SwiftUI state (`@State`, `@Binding`, `@Observable`, `@Environment`) and avoid unnecessary view models.
- On iOS 17+, prefer `@Observable` over `ObservableObject`, root ownership with `@State`, and `@Environment(Type.self)` for truly shared dependencies.
- Use `@Bindable` only when a child view must mutate an injected `@Observable` model; do not default every injected model to `@Bindable`.
- If the deployment target includes iOS 16 or earlier and cannot use the Observation API introduced in iOS 17, fall back to `ObservableObject` with `@StateObject` for root ownership, `@ObservedObject` for injected observation, and `@EnvironmentObject` only for truly shared app-level state.
- Prefer composition; keep views small and focused.
- Use async/await with `.task` and explicit loading/error states. For restart, cancellation, and debouncing guidance, read `references/async-state.md`.
- Prefer `.task` or `.task(id:)` over `onAppear { Task { ... } }`, and prefer `onChange(of:initial:_:)` when you need modern change observation.
- Keep shared app services in `@Environment`, but prefer explicit initializer injection for feature-local dependencies and models. For root wiring patterns, read `references/app-wiring.md`.
- Prefer the newest SwiftUI API that fits the deployment target and call out the minimum OS whenever a pattern depends on it.
- Maintain existing legacy patterns only when editing legacy files.
- Follow the project's formatter and style guide.
- **Sheets**: Prefer `.sheet(item:)` over `.sheet(isPresented:)` when state represents a selected model. Avoid `if let` inside a sheet body. Sheets should own their actions and call `dismiss()` internally instead of forwarding `onCancel`/`onConfirm` closures.
- **Scroll-driven reveals**: Prefer deriving a normalized progress value from scroll offset and driving the visual state from that single source of truth. Avoid parallel gesture state machines unless scroll alone cannot express the interaction.

## State ownership summary

Use the narrowest state tool that matches the ownership model:

| Scenario | Preferred pattern |
| --- | --- |
| Local UI state owned by one view | `@State` |
| Child mutates parent-owned value state | `@Binding` |
| Root-owned reference model on iOS 17+ | `@State` with an `@Observable` type |
| Child reads an injected `@Observable` model on iOS 17+ | Pass it explicitly as a stored property |
| Child mutates an injected `@Observable` model on iOS 17+ | `@Bindable` |
| Shared app service or configuration | `@Environment(Type.self)` |
| Legacy reference model on iOS 16 and earlier | `@StateObject` at the root, `@ObservedObject` when injected |

Choose the ownership location first, then pick the wrapper. Do not introduce a reference model when plain value state is enough.

## Cross-cutting references

- `references/navigationstack.md`: navigation ownership, per-tab history, and enum routing.
- `references/sheets.md`: centralized modal presentation and enum-driven sheets.
- `references/deeplinks.md`: URL handling and routing external links into app destinations.
- `references/app-wiring.md`: root dependency graph, environment usage, and app shell wiring.
- `references/observation.md`: `@Observable` models, feature-scoped reference state, and when not to keep a separate view model.
- `references/state-ownership.md`: choosing between `@State`, `@Binding`, `@Bindable`, and environment injection.
- `references/environment-observation.md`: iOS 17+ environment injection with `environment(_:)` and `@Environment(Type.self)`.
- `references/observation-migration.md`: migrating `ObservableObject`/`@StateObject` code to Observation.
- `references/latest-apis.md`: deprecated-to-modern SwiftUI API replacements when updating older code.
- `references/async-state.md`: `.task`, `.task(id:)`, cancellation, debouncing, and async UI state.
- `references/view-modifiers.md`: modern `onChange` and task-driven lifecycle modifiers.
- `references/composition.md`: reusable subviews, local `@ViewBuilder` helpers, and small custom modifiers.
- `references/accessibility.md`: VoiceOver, Dynamic Type, and custom accessibility actions.
- `references/uikit-interop.md`: wrapping UIKit views and controllers safely in SwiftUI.
- `references/previews.md`: `#Preview`, fixtures, mock environments, and isolated preview setup.
- `references/performance.md`: stable identity, observation scope, lazy containers, and render-cost guardrails.

## Anti-patterns

- Giant views that mix layout, business logic, networking, routing, and formatting in one file.
- Multiple boolean flags for mutually exclusive sheets, alerts, or navigation destinations.
- Live service calls directly inside `body`-driven code paths instead of view lifecycle hooks or injected models/services.
- Reaching for `AnyView` to work around type mismatches that should be solved with better composition.
- Defaulting every shared dependency to `@EnvironmentObject` or a global router without a clear ownership reason.

## Workflow for a new SwiftUI view

1. Define the view's state, ownership location, and minimum OS assumptions before writing UI code.
2. Identify which dependencies belong in `@Environment` and which should stay as explicit initializer inputs. If a reference model is involved, confirm whether it should be `@Observable` and who owns it.
3. Sketch the view hierarchy, routing model, and presentation points; extract repeated parts into subviews. For complex navigation, read `references/navigationstack.md`, `references/sheets.md`, or `references/deeplinks.md`. **Build and verify no compiler errors before proceeding.**
4. Implement async loading with `.task` or `.task(id:)`, plus explicit loading and error states when needed. Read `references/async-state.md` or `references/view-modifiers.md` when the work depends on changing inputs or cancellation.
5. Add previews for the primary and secondary states, then add accessibility labels or identifiers when the UI is interactive. Read `references/previews.md` when the view needs fixtures or injected mock dependencies.
6. Validate with a build: confirm no compiler errors, check that previews render without crashing, ensure state changes propagate correctly, and sanity-check that list identity and observation scope will not cause avoidable re-renders. Read `references/performance.md` if the screen is large, scroll-heavy, or frequently updated. For common SwiftUI compilation errors — missing `@State` annotations, ambiguous `ViewBuilder` closures, or mismatched generic types — resolve them before updating callsites. **If the build fails:** read the error message carefully, fix the identified issue, then rebuild before proceeding to the next step. If a preview crashes, isolate the offending subview, confirm its state initialisation is valid, and re-run the preview before continuing. If the work touches legacy observation wrappers, confirm the right migration path in `references/observation-migration.md` instead of mixing old and new patterns.

## Component references

Use `references/components-index.md` as the entry point. Each component reference should include:
- Intent and best-fit scenarios.
- Minimal usage pattern with local conventions.
- Pitfalls and performance notes.
- Paths to existing examples in the current repo.

## Adding a new component reference

- Create `references/<component>.md`.
- Keep it short and actionable; link to concrete files in the current repo.
- Update `references/components-index.md` with the new entry.
