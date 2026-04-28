---
name: swiftui-advanced
description: Use only when standard SwiftUI UI patterns are not enough and the primary task is advanced gesture composition, advanced animation choreography, adaptive layout branching, or architecture tradeoffs such as MV vs MVVM vs TCA and State-as-Bridge. Do not use this for general SwiftUI implementation, Liquid Glass work, or runtime performance audits.
---

# SwiftUI Advanced

Advanced SwiftUI patterns for gesture composition, animation, adaptive layouts, and architecture tradeoffs that go beyond normal component-level UI work.

Use `swiftui-patterns` for default feature implementation and `swiftui-performance-audit` when the main job is diagnosing runtime performance.

## Reference Loading Guide

**ALWAYS load reference files if there is even a small chance the content may be required.** It's better to have the context than to miss a pattern or make a mistake.

| Reference | Load When |
|-----------|-----------|
| **[Gestures](references/gestures.md)** | Composing multiple gestures, GestureState, custom recognizers |
| **[Animation Basics](references/animation-basics.md)** | Choosing implicit vs explicit animation, timing, and event-driven animation |
| **[Animation Transitions](references/animation-transitions.md)** | Transitions, custom transitions, and `Animatable` |
| **[Animation Advanced](references/animation-advanced.md)** | `phaseAnimator`, `keyframeAnimator`, transactions, completion handling |
| **[Adaptive Layout](references/adaptive-layout.md)** | ViewThatFits, AnyLayout, size classes, iOS 26 free-form windows |
| **[Architecture](references/architecture.md)** | MV vs MVVM vs TCA tradeoffs, State-as-Bridge, coordinator boundaries |

## Core Workflow

1. **Identify pattern category** from user's question
2. **Load relevant reference** for detailed patterns and code examples
3. **Apply pattern** following the decision trees and anti-patterns
4. **Verify** using provided checklists or profiling guidance

## Decision Trees

### Gesture Composition
- Both gestures at same time? -> `.simultaneously`
- One must complete before next? -> `.sequenced`
- Only one should win? -> `.exclusively`

### Layout Adaptation
- Pick best-fitting variant? -> `ViewThatFits`
- Animated H/V switch? -> `AnyLayout`
- Need actual dimensions? -> `onGeometryChange`

### Animation Choice
- Simple state-driven change? -> `.animation(_:value:)`
- Explicit event or gesture? -> `withAnimation`
- Insert/remove views? -> transition + surrounding animation
- Multi-step sequence? -> `.phaseAnimator`
- Precise timing track? -> `.keyframeAnimator`

### Architecture Selection
- Small app, Apple patterns? -> @Observable + State-as-Bridge
- Complex presentation logic? -> MVVM with @Observable
- Rigorous testability needed? -> TCA

## Common Mistakes

1. **Gesture composition order matters** — `.simultaneously` and `.sequenced` have different trigger timing. Swapping them silently changes behavior. Understand gesture semantics before using.

2. **ViewThatFits over-used** — ViewThatFits remeasures on every view change. For animated H/V switches, use `AnyLayout` instead. Use ViewThatFits only for static variant selection.

3. **onGeometryChange triggering unnecessary updates** — Reading geometry changes geometry, which triggers updates, which changes geometry... circular. Use `.onGeometryChange` only with proper state management to avoid loops.

4. **Architecture mismatch mid-project** — Starting with @Observable + State-as-Bridge then realizing you need TCA is expensive. Choose architecture upfront based on complexity (small app = @Observable, complex = TCA).

5. **Using advanced animation APIs too early** — `phaseAnimator` and `keyframeAnimator` are useful, but they are not defaults. Prefer simpler value-driven animation until the motion actually needs staged or keyed timing.
