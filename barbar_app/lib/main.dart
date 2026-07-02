import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/api_client.dart';
import 'core/network/websocket_client.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/booking_remote_datasource.dart';
import 'data/datasources/remote/directory_remote_datasource.dart';
import 'data/datasources/remote/marketplace_remote_datasource.dart';
import 'data/datasources/remote/wallet_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/booking_repository_impl.dart';
import 'domain/repositories/booking_repository.dart';
import 'data/repositories/directory_repository_impl.dart';
import 'data/repositories/marketplace_repository_impl.dart';
import 'data/repositories/wallet_repository_impl.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/booking/booking_bloc.dart';
import 'presentation/bloc/directory/directory_bloc.dart';
import 'presentation/bloc/marketplace/marketplace_bloc.dart';
import 'presentation/bloc/wallet/wallet_bloc.dart';
import 'presentation/screens/admin_console_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/barber_dashboard_screen.dart';
import 'presentation/screens/customer_dashboard_shell.dart';
import 'presentation/screens/delivery_dashboard_screen.dart';
import 'presentation/screens/vendor_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Networking & Data Sources
  final localDataSource = AuthLocalDataSource(
    secureStorage: const FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
  final apiClient = ApiClient(localDataSource: localDataSource);
  final webSocketClient = WebSocketClient(localDataSource: localDataSource);

  // Remote DataSources
  final authRemoteDataSource = AuthRemoteDataSource(apiClient);
  final bookingRemoteDataSource = BookingRemoteDataSource(apiClient);
  final directoryRemoteDataSource = DirectoryRemoteDataSource(apiClient);
  final marketplaceRemoteDataSource = MarketplaceRemoteDataSource(apiClient);
  final walletRemoteDataSource = WalletRemoteDataSource(apiClient);

  // Repositories
  final authRepository = AuthRepositoryImpl(authRemoteDataSource, localDataSource);
  final bookingRepository = BookingRepositoryImpl(bookingRemoteDataSource);
  final directoryRepository = DirectoryRepositoryImpl(directoryRemoteDataSource);
  final marketplaceRepository = MarketplaceRepositoryImpl(marketplaceRemoteDataSource);
  final walletRepository = WalletRepositoryImpl(walletRemoteDataSource);

  runApp(
    MyApp(
      authRepository: authRepository,
      bookingRepository: bookingRepository,
      directoryRepository: directoryRepository,
      marketplaceRepository: marketplaceRepository,
      walletRepository: walletRepository,
      webSocketClient: webSocketClient,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepositoryImpl authRepository;
  final BookingRepositoryImpl bookingRepository;
  final DirectoryRepositoryImpl directoryRepository;
  final MarketplaceRepositoryImpl marketplaceRepository;
  final WalletRepositoryImpl walletRepository;
  final WebSocketClient webSocketClient;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.bookingRepository,
    required this.directoryRepository,
    required this.marketplaceRepository,
    required this.walletRepository,
    required this.webSocketClient,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BookingRepository>(
          create: (context) => bookingRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(authRepository)..add(AppStarted()),
          ),
          BlocProvider<DirectoryBloc>(
            create: (context) => DirectoryBloc(directoryRepository),
          ),
          BlocProvider<BookingBloc>(
            create: (context) => BookingBloc(bookingRepository),
          ),
          BlocProvider<MarketplaceBloc>(
            create: (context) => MarketplaceBloc(marketplaceRepository),
          ),
          BlocProvider<WalletBloc>(
            create: (context) => WalletBloc(walletRepository),
          ),
        ],
        child: MaterialApp(
          title: 'Barbar App',
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthInitial || state is AuthLoading) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                );
              } else if (state is AuthAuthenticated) {
                final role = state.user.role.toLowerCase();
                if (role == 'barber') {
                  return BarberDashboardScreen(webSocketClient: webSocketClient);
                } else if (role == 'vendor') {
                  return const VendorDashboardScreen();
                } else if (role == 'delivery' || role == 'delivery_partner') {
                  return const DeliveryDashboardScreen();
                } else if (role == 'admin' || role == 'super_admin') {
                  return const AdminConsoleScreen();
                } else {
                  return CustomerDashboardShell(webSocketClient: webSocketClient);
                }
              } else {
                return const AuthScreen();
              }
            },
          ),
        ),
      ),
    );
  }
}
