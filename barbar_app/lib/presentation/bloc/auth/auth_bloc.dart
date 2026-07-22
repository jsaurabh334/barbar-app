import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/notification/fcm_service.dart';
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
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.isLoggedIn().timeout(const Duration(seconds: 5));
      if (result) {
        final user = await _authRepository.getCachedUser().timeout(const Duration(seconds: 3));
        if (user != null) {
          emit(AuthAuthenticated(user));
          try {
            await FCMService.registerDeviceToken();
          } catch (_) {}
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
      await FCMService.registerDeviceToken();
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
      await FCMService.unregisterDeviceToken();
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateProfileRequested(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final updatedUser = await _authRepository.updateProfile(event.data);
      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
