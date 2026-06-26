# Graph Report - barbar_app  (2026-06-04)

## Corpus Check
- 109 files · ~34,979 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 681 nodes · 759 edges · 65 communities (42 shown, 23 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 18 edges
2. `package:flutter_bloc/flutter_bloc.dart` - 17 edges
3. `../../core/theme/app_theme.dart` - 14 edges
4. `package:lucide_icons/lucide_icons.dart` - 13 edges
5. `../../../core/network/api_client.dart` - 11 edges
6. `package:equatable/equatable.dart` - 10 edges
7. `../widgets/glass_card.dart` - 7 edges
8. `AppDelegate` - 6 edges
9. `../../../data/models/barber_model.dart` - 6 edges
10. `../bloc/auth/auth_bloc.dart` - 6 edges

## Surprising Connections (you probably didn't know these)
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `GetClientArea()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `SetChildContent()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp

## Communities (65 total, 23 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (38): ../../../core/network/api_client.dart, ../../../data/models/transaction_model.dart, ../datasources/remote/directory_remote_datasource.dart, ../datasources/remote/marketplace_remote_datasource.dart, ../datasources/remote/wallet_remote_datasource.dart, directory_event.dart, directory_state.dart, ../../../domain/repositories/directory_repository.dart (+30 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (43): ../bloc/auth/auth_event.dart, ../bloc/wallet/wallet_bloc.dart, ../bloc/wallet/wallet_event.dart, ../bloc/wallet/wallet_state.dart, AlertDialog, build, _buildMerchantEarningsCard, _buildOrdersTab (+35 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (43): ../bloc/marketplace/marketplace_bloc.dart, ../bloc/marketplace/marketplace_event.dart, ../bloc/marketplace/marketplace_state.dart, package:google_maps_flutter/google_maps_flutter.dart, build, _buildActionButton, _buildHistoryTab, _buildOrderCard (+35 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (42): ../bloc/booking/booking_bloc.dart, ../bloc/booking/booking_event.dart, ../bloc/booking/booking_state.dart, BarberDetailScreen, _BarberDetailScreenState, build, _buildPickerButton, _buildServiceTile (+34 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (34): ../../../data/models/user_model.dart, package:equatable/equatable.dart, AuthRepository, AppStarted, AuthEvent, LogoutRequested, RegisterRequested, SendOtpRequested (+26 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (34): data/datasources/remote/auth_remote_datasource.dart, data/datasources/remote/booking_remote_datasource.dart, data/datasources/remote/directory_remote_datasource.dart, data/datasources/remote/marketplace_remote_datasource.dart, data/datasources/remote/wallet_remote_datasource.dart, data/repositories/auth_repository_impl.dart, data/repositories/booking_repository_impl.dart, data/repositories/directory_repository_impl.dart (+26 more)

### Community 6 - "Community 6"
Cohesion: 0.07
Nodes (24): ../constants/constants.dart, ../../../core/constants/constants.dart, dart:async, dart:convert, ../../../data/datasources/local/auth_local_datasource.dart, ../network/api_client.dart, package:dio/dio.dart, package:flutter_secure_storage/flutter_secure_storage.dart (+16 more)

### Community 7 - "Community 7"
Cohesion: 0.07
Nodes (25): ../../../data/models/order_model.dart, ../../../data/models/product_model.dart, marketplace_event.dart, marketplace_state.dart, MarketplaceRepository, MarketplaceBloc, _onAddToCart, _onClearCart (+17 more)

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 9 - "Community 9"
Cohesion: 0.08
Nodes (23): booking_event.dart, booking_state.dart, ../../../data/models/booking_model.dart, ../../../data/models/service_model.dart, ../datasources/remote/booking_remote_datasource.dart, ../../../domain/repositories/booking_repository.dart, ../models/booking_model.dart, ../models/service_model.dart (+15 more)

### Community 10 - "Community 10"
Cohesion: 0.07
Nodes (27): AdminConsoleScreen, _AdminConsoleScreenState, AlertDialog, build, _buildAnalyticsTab, _buildDisputeCard, _buildDisputesTab, _buildKycCard (+19 more)

### Community 11 - "Community 11"
Cohesion: 0.08
Nodes (23): dart:ui, package:flutter/material.dart, package:google_fonts/google_fonts.dart, ../../presentation/screens/wallet_screen.dart, ../theme/app_theme.dart, handleDeepLink, Icon, NotificationService (+15 more)

### Community 12 - "Community 12"
Cohesion: 0.08
Nodes (24): map_discovery_screen.dart, package:shimmer/shimmer.dart, build, _buildActiveQueueTrackerWidget, _buildBarberCard, _buildEmptyState, _buildLiveBadge, _buildLoadingShimmer (+16 more)

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (24): ../bloc/auth/auth_state.dart, AuthScreen, _AuthScreenState, build, _buildAuthTabsWidget, _buildLoginForm, _buildOtpWidget, _buildRoleChip (+16 more)

### Community 14 - "Community 14"
Cohesion: 0.09
Nodes (22): ../bloc/auth/auth_bloc.dart, BarberDashboardScreen, _BarberDashboardScreenState, build, _buildActiveQueuesTab, _buildBookingQueueCard, _buildScheduleTab, _buildTimeConfigRow (+14 more)

### Community 15 - "Community 15"
Cohesion: 0.09
Nodes (21): barber_detail_screen.dart, ../bloc/directory/directory_bloc.dart, ../bloc/directory/directory_event.dart, ../bloc/directory/directory_state.dart, ../../core/services/location_service.dart, build, _buildCarouselItem, dispose (+13 more)

### Community 16 - "Community 16"
Cohesion: 0.14
Nodes (13): ../../core/network/websocket_client.dart, ../../core/theme/app_theme.dart, home_screen.dart, queue_tracker_screen.dart, shop_screen.dart, build, CustomerDashboardShell, _CustomerDashboardShellState (+5 more)

### Community 17 - "Community 17"
Cohesion: 0.15
Nodes (4): fl_register_plugins(), main(), my_application_activate(), my_application_new()

### Community 18 - "Community 18"
Cohesion: 0.15
Nodes (12): package:lucide_icons/lucide_icons.dart, AddressModel, AddressScreen, _AddressScreenState, build, Container, dispose, Function (+4 more)

### Community 19 - "Community 19"
Cohesion: 0.18
Nodes (9): auth_event.dart, auth_state.dart, ../datasources/local/auth_local_datasource.dart, ../datasources/remote/auth_remote_datasource.dart, ../../../domain/repositories/auth_repository.dart, ../models/user_model.dart, package:flutter_bloc/flutter_bloc.dart, AuthRepositoryImpl (+1 more)

### Community 21 - "Community 21"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), NSWindow, MainFlutterWindow

### Community 22 - "Community 22"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 24 - "Community 24"
Cohesion: 0.4
Nodes (4): ../datasources/remote/address_remote_datasource.dart, ../../domain/repositories/address_repository.dart, AddressRepositoryImpl, Exception

### Community 25 - "Community 25"
Cohesion: 0.5
Nodes (3): package:barbar_app/data/models/user_model.dart, package:flutter_test/flutter_test.dart, main

### Community 26 - "Community 26"
Cohesion: 0.5
Nodes (3): dart:io, AppConfig, AppConstants

### Community 27 - "Community 27"
Cohesion: 0.5
Nodes (3): service_model.dart, BookingModel, copyWith

## Knowledge Gaps
- **469 isolated node(s):** `PodsDummy_flutter_secure_storage_macos`, `PodsDummy_Pods_Runner`, `PodsDummy_shared_preferences_foundation`, `PodsDummy_Pods_RunnerTests`, `PodsDummy_geolocator_apple` (+464 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter_bloc/flutter_bloc.dart` connect `Community 19` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 5`, `Community 7`, `Community 9`, `Community 10`, `Community 12`, `Community 13`, `Community 14`, `Community 15`?**
  _High betweenness centrality (0.176) - this node is a cross-community bridge._
- **Why does `package:flutter/material.dart` connect `Community 11` to `Community 1`, `Community 2`, `Community 3`, `Community 5`, `Community 10`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 18`?**
  _High betweenness centrality (0.137) - this node is a cross-community bridge._
- **Why does `package:equatable/equatable.dart` connect `Community 4` to `Community 0`, `Community 9`, `Community 7`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **What connects `PodsDummy_flutter_secure_storage_macos`, `PodsDummy_Pods_Runner`, `PodsDummy_shared_preferences_foundation` to the rest of the system?**
  _469 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._