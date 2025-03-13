import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import '../../../../services/api/api_service.dart';
import 'sign_in_state.dart';
import '../../../../core/validators/auth_validator.dart';
import '../../../main/screens/main_screen.dart';

class SignInCubit extends Cubit<SignInState> {
  final ApiService _apiService;
  final AuthCubit _authCubit;
  final BuildContext context;

  SignInCubit(this._apiService, this._authCubit, this.context) : super(const SignInState());

  void onEmailChanged(String email) {
    final emailTrimmed = email.trim();
    String emailError = _validateEmail(emailTrimmed);

    emit(state.copyWith(
      email: emailTrimmed,
      emailError: emailError,
    ));
  }

  void onPasswordChanged(String password) {
    final passwordTrimmed = password.trim();
    String passwordError = _validatePassword(passwordTrimmed);

    emit(state.copyWith(
      password: passwordTrimmed,
      passwordError: passwordError,
    ));
  }

  Future<void> signIn() async {
    if (!_validateForm()) return;

    try {
      emit(state.copyWith(isLoading: true, errorMessage: ''));

      final result = await _apiService.login(state.email, state.password);

      if (result['success']) {
        await _authCubit.loginSuccess(result);
        
        emit(state.copyWith(
          isLoading: false,
          isSuccess: true,
          message: result['message'],
        ));
        
        // Chuyển đến trang chính sau khi đăng nhập thành công
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
          (route) => false,
        );
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Đã xảy ra lỗi: ${e.toString()}',
      ));
    }
  }

  bool _validateForm() {
    final emailError = _validateEmail(state.email);
    final passwordError = _validatePassword(state.password);

    emit(state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
    ));

    return emailError.isEmpty && passwordError.isEmpty;
  }

  String _validateEmail(String email) {
    return AuthValidator.validateEmail(email) ?? '';
  }

  String _validatePassword(String password) {
    return AuthValidator.validatePassword(password) ?? '';
  }
}
