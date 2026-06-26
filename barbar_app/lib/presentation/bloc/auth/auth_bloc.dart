import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepository.getCachedUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
          return;
        }
      }
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSendOtpRequested(SendOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final success = await _authRepository.sendOtp(event.phone);
      if (success) {
        emit(OtpSentSuccess(event.phone));
      } else {
        emit(const AuthFailure('Failed to send OTP. Please check the number.'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onVerifyOtpRequested(VerifyOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.verifyOtp(
        phone: event.phone,
        otp: event.otp,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.register(
        fullName: event.fullName,
        phone: event.phone,
        password: event.password,
        role: event.role,
        email: event.email,
      );
      // After registration, we prompt user to verify with OTP
      final success = await _authRepository.sendOtp(event.phone);
      if (success) {
        emit(OtpSentSuccess(event.phone));
      } else {
        emit(const AuthFailure('Registration succeeded, but failed to send OTP.'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
