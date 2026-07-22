class PaginationHelper {
  int _currentPage = 1;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  int get currentPage => _currentPage;
  bool get hasReachedMax => _hasReachedMax;
  bool get isLoadingMore => _isLoadingMore;

  void reset() {
    _currentPage = 1;
    _hasReachedMax = false;
    _isLoadingMore = false;
  }

  bool shouldLoadMore(int itemCount) {
    if (_hasReachedMax || _isLoadingMore) return false;
    return itemCount >= _currentPage * 20;
  }

  void startLoadingMore() {
    _isLoadingMore = true;
  }

  void onPageLoaded(int totalItems, int fetchedCount) {
    _isLoadingMore = false;
    if (fetchedCount < 20 || totalItems <= _currentPage * 20) {
      _hasReachedMax = true;
    }
    _currentPage++;
  }
}
