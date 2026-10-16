// action_state.dart
//
// ActionState — lifecycle of a one-shot user action that returns no data to
// display (export, share, upload, send). Data fetches use LoadState<T>
// (load_state.dart) instead.

/// Current phase of a one-shot action, driving its button or progress UI:
/// - [idle]: nothing running; show the action.
/// - [loading]: running; show a progress indicator and disable the action.
/// - [success]: done; optionally show a confirmation.
/// - [error]: failed; show an error or a retry.
enum ActionState { idle, loading, success, error }
