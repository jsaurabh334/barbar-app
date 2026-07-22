class AdminFilterState {
  String search;
  String? status;
  String? dateFrom;
  String? dateTo;
  String? sortBy;
  String? sortOrder;

  AdminFilterState({
    this.search = '',
    this.status,
    this.dateFrom,
    this.dateTo,
    this.sortBy,
    this.sortOrder,
  });

  AdminFilterState copyWith({
    String? search,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortOrder,
  }) {
    return AdminFilterState(
      search: search ?? this.search,
      status: status ?? this.status,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  void reset() {
    search = '';
    status = null;
    dateFrom = null;
    dateTo = null;
    sortBy = null;
    sortOrder = null;
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    return params;
  }
}
