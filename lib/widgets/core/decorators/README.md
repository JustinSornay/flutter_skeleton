# widgets/core/decorators/

**Decorators** are parameterizable wrappers that apply cross-cutting behavior
(animation, styling, loading state) to a child widget, without containing any
business logic.

## Principle

1. **It is agnostic to its content.** Its responsibility ends at the envelope —
   style, animation, opacity — never at the semantic content inside.
2. **It is reusable anywhere.** No dependency on a specific page or provider.
3. **It accepts a `child`.** Composition, not inheritance.

| Decorator | Custom widget |
|---|---|
| Applies behavior to any child | Is itself the component (has its own semantics) |
| `SkeletonPulse(child: …)` | `Loader(size: 24)` |

## Example: `SkeletonPulse`

Pulses any widget between two opacity levels to indicate a loading state. Two
modes: autonomous (owns its `AnimationController`) or controlled (receives an
external controller to synchronize several skeletons). Respects
`MediaQuery.disableAnimations`.

```dart
SkeletonPulse(child: Container(width: 120, height: 16))
```

## Rules

- A decorator **does not read providers** and **does not make API calls**.
- If the behavior depends on the content (not just the shape), it belongs in
  `custom/`.
- Always honor reduced motion (`resolveMotion()` or
  `MediaQuery.disableAnimationsOf`).
