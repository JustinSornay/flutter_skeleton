// view_model.dart
//
// State class for Listing<T>. Owns the ScrollController and all pagination
// bookkeeping: next page, whether a next page exists, the accumulated list,
// the loading flag and the first-page error flag.
//
// Pagination trigger: the scroll listener fires when the remaining scroll
// extent drops below the visible extent (extentAfter < extentInside), i.e.
// slightly before the user reaches the bottom. The same check runs after each
// page is laid out so a first page too short to scroll still loads the next.

part of "index.dart";

final class _ListingState<T extends OutputInterface> extends State<Listing<T>> with _ViewMixin<T> {
  final ScrollController controller = ScrollController();

  /// Accumulated items across all loaded pages.
  List<T> list = <T>[];

  /// True while an API call is in flight (initial load or pagination).
  bool isLoading = false;

  /// True when the first page failed to load.
  bool hasError = false;

  /// Next page to fetch (1-based).
  int nextPage = 1;

  /// Set to false when a page returns fewer items than [itemPerPage],
  /// indicating the API has no more data.
  bool hasNextPage = true;

  /// Resolves item-per-page: widget override first, then env variable fallback.
  int get itemPerPage {
    final int n = widget.itemPerPage ?? Env.intOr("ITEM_PER_PAGE", 20);
    assert(n > 0, "itemPerPage must be > 0, got $n");
    return n;
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_onScroll);
    loadNextPage();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (
      controller.hasClients &&
      controller.position.extentAfter < controller.position.extentInside
    ) {
      loadNextPage();
    }
  }

  /// Clears everything and reloads page 1. Used by the error state's retry.
  void retry() {
    setState(() {
      list = <T>[];
      nextPage = 1;
      hasNextPage = true;
      hasError = false;
    });
    loadNextPage();
  }

  /// Fetches [nextPage] and appends it. No-op while a call is in flight or
  /// when the last page has been reached. Errors are logged; a failure on the
  /// first page switches the widget to its error state.
  Future<void> loadNextPage() async {
    if (isLoading || !hasNextPage) return;
    final int page = nextPage;
    setState(() => isLoading = true);

    try {
      final List<T> result = await widget.apiCallback(page, itemPerPage);
      if (!mounted) return;
      setState(() {
        list = <T>[...list, ...result];
        nextPage = page + 1;
        hasNextPage = result.length == itemPerPage;
      });
      widget.onTotalCountChanged?.call(list.length);
      // A page shorter than the viewport never scrolls: re-check once laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onScroll();
      });
    } catch (e, s) {
      Logger().e("Listing.loadNextPage: failed to get page $page ($itemPerPage items)",
        error: e,
        stackTrace: s,
      );
      if (mounted && page == 1) {
        setState(() => hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
