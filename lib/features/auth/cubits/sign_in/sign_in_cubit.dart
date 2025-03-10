import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import '../../../../services/api/api_service.dart';
import 'sign_in_state.dart';
import 'sign_in_event.dart';

class SignInCubit extends Bloc<SignInEvent, SignInState> {
  final ApiService _apiService;
  final AuthCubit _authCubit;

  SignInCubit(this._apiService, this._authCubit) : super(const SignInState()) {
    on<SignInEmailChanged>(_onEmailChanged);
    on<SignInPasswordChanged>(_onPasswordChanged);
    on<SignInSubmitted>(_onSubmitted);
  }

  void _onEmailChanged(SignInEmailChanged event, Emitter<SignInState> emit) {
    final email = event.email.trim();
    String emailError = '';

    if (email.isEmpty) {
      emailError = "Email không được để trống!";
    } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      emailError = "Email không hợp lệ!";
    }

    emit(state.copyWith(email: email, emailError: emailError));
  }

  void _onPasswordChanged(SignInPasswordChanged event, Emitter<SignInState> emit) {
    final password = event.password.trim();
    String passwordError = '';

    if (password.isEmpty) {
      passwordError = "Mật khẩu không được để trống!";
    } else if (password.length < 6) {
      passwordError = "Mật khẩu phải có ít nhất 6 ký tự!";
    }

    emit(state.copyWith(password: password, passwordError: passwordError));
  }

  Future<void> _onSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final result = await _apiService.login(state.email, state.password);

      if (result['success']) {
        // Thông báo cho AuthCubit về đăng nhập thành công
        await _authCubit.loginSuccess(result);
        
        emit(state.copyWith(
          isLoading: false,
          isSuccess: true,
          message: result['message'],
        ));
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
}
