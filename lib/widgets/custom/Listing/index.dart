// index.dart
//
// Declares the generic Listing<T> stateful widget. Provides paginated,
// lazy-loaded list rendering for any DTO that implements OutputInterface.
//
// The widget manages its own scroll controller and pagination state. It calls
// [apiCallback] with (page, itemsPerPage) and appends results automatically as
// the user scrolls near the bottom.
//
// IMPORTANT: Never wrap Listing in a ScrollView. Instead place it inside a
// Column with Expanded so it can size its internal ListView correctly.
// Use a ValueKey containing every parameter that should trigger a refresh
// (query, filters, locale) to force a full reload when the data source changes.

import "package:flutter/material.dart";
import "package:flutter_skeleton/api/dtos/_base/output/output_interface.dart";
import "package:flutter_skeleton/utils/env.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:logger/logger.dart";

part "view_model.dart";
part "view.dart";

/// Generic paginated list widget that lazy-loads pages from the API.
///
/// Type parameter [T] must implement [OutputInterface]. The widget calls
/// [apiCallback] with a 1-based page number and [itemPerPage] on first mount
/// and again each time the scroll position approaches the end of the list.
///
/// [itemBuilder] may return `null` to skip rendering an item.
/// [separatorBuilder] is always called between consecutive items.
/// [emptyBuilder] is shown when the first page returns an empty list.
/// [errorBuilder] is shown when the first page fails; call `retry` to reload.
/// [itemPerPage] defaults to the `ITEM_PER_PAGE` env variable (20 when unset).
/// [onTotalCountChanged] is called after each page load with the cumulative
/// item count, allowing the caller to update a count display.
final class Listing<T extends OutputInterface> extends StatefulWidget {
  final Future<List<T>> Function(int page, int itemPerPage) apiCallback;
  final Widget? Function(BuildContext context, T item) itemBuilder;
  final Widget Function(BuildContext context, T item) separatorBuilder;
  final int? itemPerPage;
  final Axis scrollDirection;
  final Widget? emptyBuilder;
  final Widget Function(BuildContext context, VoidCallback retry)? errorBuilder;
  final ValueChanged<int>? onTotalCountChanged;

  const Listing({
    super.key,
    required this.apiCallback,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.itemPerPage,
    this.scrollDirection = Axis.vertical,
    this.emptyBuilder,
    this.errorBuilder,
    this.onTotalCountChanged,
  });

  @override
  State<Listing<T>> createState() => _ListingState<T>();
}
