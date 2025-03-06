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

  void _onSubmitted(SignInSubmitted event, Emitter<SignInState> emit) async {
    String? emailError;
    String? passwordError;

    if (state.email.isEmpty) {
      emailError = "Email không được để trống!";
    }
    if (state.password.isEmpty) {
      passwordError = "Mật khẩu không được để trống!";
    }

    // Nếu có lỗi, cập nhật state và không tiếp tục xử lý đăng nhập
    if (emailError != null || passwordError != null) {
      emit(state.copyWith(emailError: emailError, passwordError: passwordError));
      return;
    }

    emit(state.copyWith(isLoading: true, emailError: '', passwordError: '', errorMessage: ''));

    try {
      final response = await _apiService.login(state.email, state.password);
      print("API Response: $response"); // Debug response

      // Kiểm tra xem response có chứa token không
      if (response['success']) {
        _authCubit.loginSuccess(response);
        emit(state.copyWith(
          isLoading: false,
          isSuccess: true,
          errorMessage: '',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: response['message'] ?? 'Đăng nhập thất bại',
        ));
      }
    } catch (e) {
      print("Error: $e"); // Debug lỗi
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Đăng nhập thất bại: $e',
      ));
    }
  }
}
