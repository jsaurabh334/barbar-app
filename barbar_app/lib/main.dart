import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/api_client.dart';
import 'core/network/websocket_client.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/barber_remote_datasource.dart';
import 'data/datasources/admin_remote_data_source.dart';
import 'data/datasources/remote/booking_remote_datasource.dart';
import 'data/datasources/remote/directory_remote_datasource.dart';
import 'data/datasources/remote/marketplace_remote_datasource.dart';
import 'data/datasources/remote/wallet_remote_datasource.dart';
import 'data/datasources/remote/address_remote_datasource.dart';
import 'data/datasources/remote/review_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/barber_repository_impl.dart';
import 'data/repositories/admin_repository_impl.dart';
import 'data/repositories/booking_repository_impl.dart';
import 'data/repositories/address_repository_impl.dart';
import 'data/repositories/review_repository_impl.dart';
import 'domain/repositories/admin_repository.dart';
import 'domain/repositories/barber_repository.dart';
import 'domain/repositories/booking_repository.dart';
import 'domain/repositories/address_repository.dart';
import 'domain/repositories/review_repository.dart';
import 'data/repositories/directory_repository_impl.dart';
import 'data/repositories/marketplace_repository_impl.dart';
import 'data/repositories/wallet_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/booking/booking_bloc.dart';
import 'presentation/bloc/barber_staff/barber_staff_bloc.dart';
import 'presentation/bloc/barber_profile/barber_profile_bloc.dart';
import 'presentation/bloc/barber_services/barber_services_bloc.dart';
import 'presentation/bloc/barber_documents/barber_documents_bloc.dart';
import 'presentation/bloc/barber_availability/barber_availability_bloc.dart';
import 'presentation/bloc/barber_earnings/barber_earnings_bloc.dart';
import 'presentation/bloc/directory/directory_bloc.dart';
import 'presentation/bloc/marketplace/marketplace_bloc.dart';
import 'presentation/bloc/address/address_bloc.dart';
import 'presentation/bloc/review/review_bloc.dart';
import 'presentation/bloc/wallet/wallet_bloc.dart';
import 'presentation/screens/admin_console_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/barber_dashboard_shell.dart';
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
  final addressRemoteDataSource = AddressRemoteDataSource(apiClient);

  final adminRemoteDataSource = AdminRemoteDataSource(apiClient);
  final reviewRemoteDataSource = ReviewRemoteDataSource(apiClient);
  final barberRemoteDataSource = BarberRemoteDataSource(apiClient);

  // Repositories
  final authRepository = AuthRepositoryImpl(authRemoteDataSource, localDataSource);
  final bookingRepository = BookingRepositoryImpl(bookingRemoteDataSource);
  final barberRepository = BarberRepositoryImpl(barberRemoteDataSource);
  final directoryRepository = DirectoryRepositoryImpl(directoryRemoteDataSource);
  final marketplaceRepository = MarketplaceRepositoryImpl(marketplaceRemoteDataSource);
  final walletRepository = WalletRepositoryImpl(walletRemoteDataSource);
  final addressRepository = AddressRepositoryImpl(addressRemoteDataSource);
  final adminRepository = AdminRepositoryImpl(adminRemoteDataSource);
  final reviewRepository = ReviewRepositoryImpl(reviewRemoteDataSource);

  runApp(
    MyApp(
      authRepository: authRepository,
      bookingRepository: bookingRepository,
      barberRepository: barberRepository,
      directoryRepository: directoryRepository,
      marketplaceRepository: marketplaceRepository,
      walletRepository: walletRepository,
      addressRepository: addressRepository,
      adminRepository: adminRepository,
      reviewRepository: reviewRepository,
      webSocketClient: webSocketClient,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepositoryImpl authRepository;
  final BookingRepositoryImpl bookingRepository;
  final BarberRepositoryImpl barberRepository;
  final DirectoryRepositoryImpl directoryRepository;
  final MarketplaceRepositoryImpl marketplaceRepository;
  final WalletRepositoryImpl walletRepository;
  final AddressRepositoryImpl addressRepository;
  final AdminRepositoryImpl adminRepository;
  final ReviewRepository reviewRepository;
  final WebSocketClient webSocketClient;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.bookingRepository,
    required this.barberRepository,
    required this.directoryRepository,
    required this.marketplaceRepository,
    required this.walletRepository,
    required this.addressRepository,
    required this.adminRepository,
    required this.reviewRepository,
    required this.webSocketClient,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => authRepository,
        ),
        RepositoryProvider<BookingRepository>(
          create: (context) => bookingRepository,
        ),
        RepositoryProvider<BarberRepository>(
          create: (context) => barberRepository,
        ),
        RepositoryProvider<AdminRepository>(
          create: (context) => adminRepository,
        ),
        RepositoryProvider<AddressRepository>(
          create: (context) => addressRepository,
        ),
        RepositoryProvider<ReviewRepository>(
          create: (context) => reviewRepository,
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
          BlocProvider<BarberStaffBloc>(
            create: (context) => BarberStaffBloc(barberRepository),
          ),
          BlocProvider<BarberProfileBloc>(
            create: (context) => BarberProfileBloc(barberRepository),
          ),
          BlocProvider<BarberServicesBloc>(
            create: (context) => BarberServicesBloc(barberRepository),
          ),
          BlocProvider<BarberDocumentsBloc>(
            create: (context) => BarberDocumentsBloc(barberRepository),
          ),
          BlocProvider<BarberAvailabilityBloc>(
            create: (context) => BarberAvailabilityBloc(barberRepository),
          ),
          BlocProvider<BarberEarningsBloc>(
            create: (context) => BarberEarningsBloc(barberRepository),
          ),
          BlocProvider<MarketplaceBloc>(
            create: (context) => MarketplaceBloc(marketplaceRepository),
          ),
          BlocProvider<WalletBloc>(
            create: (context) => WalletBloc(walletRepository),
          ),
          BlocProvider<AddressBloc>(
            create: (context) => AddressBloc(addressRepository),
          ),
          BlocProvider<ReviewBloc>(
            create: (context) => ReviewBloc(reviewRepository),
          ),
        ],
        child: MaterialApp(
          title: 'Barbar App',
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthInitial) {
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
                  return BarberDashboardShell(
                    webSocketClient: webSocketClient,
                    barberRepository: barberRepository,
                  );
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
