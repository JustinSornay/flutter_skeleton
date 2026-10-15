// snap_controller.dart
//
// SheetSnap, the three resting heights of SnapBottomSheet, and
// SnapBottomSheetController, the caller-owned ChangeNotifier that moves the
// sheet from code. The sheet writes the resting height back into it after
// user drags.

part of "index.dart";

/// The three resting heights of a [SnapBottomSheet], lowest first.
enum SheetSnap {
  /// Lowest height: the handle and the header.
  collapsed,

  /// Intermediate height.
  mid,

  /// Highest height.
  full,
}

/// Moves a [SnapBottomSheet] from code.
///
/// The caller owns it and disposes it; the sheet only listens. User drags
/// write the resting height back into it, so [snap] matches the sheet once
/// it settles.
final class SnapBottomSheetController extends ChangeNotifier {
  SnapBottomSheetController({SheetSnap initialSnap = SheetSnap.mid}) : _snap = initialSnap;

  SheetSnap _snap;

  /// The height the sheet rests at, or is moving to.
  SheetSnap get snap => _snap;

  /// Moves the sheet to [snap] (animated through `resolveMotion`).
  /// Does nothing, and does not notify, when [snap] is the current value.
  void setSnap(SheetSnap snap) {
    if (_snap == snap) return;
    _snap = snap;
    notifyListeners();
  }

  /// Steps the sheet down one height: full → mid, mid → collapsed.
  ///
  /// Returns true when the sheet moves. Returns false, without moving, when
  /// it is already collapsed; a back handler may then let the route pop.
  bool stepDown() {
    if (_snap == SheetSnap.collapsed) return false;
    setSnap(SheetSnap.values[_snap.index - 1]);
    return true;
  }
}
