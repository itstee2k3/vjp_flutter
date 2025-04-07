import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api/api_service.dart';
import 'sign_up_state.dart';
import '../../../../core/validators/auth_validator.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final ApiService _apiService;

  SignUpCubit(this._apiService) : super(const SignUpState());

  void onFullNameChanged(String fullName) {
    String fullNameError = '';

    // Kiểm tra độ dài
    if (fullName.isEmpty) {
      fullNameError = 'Họ và tên không được để trống';
    } else if (fullName.length < 2) {
      fullNameError = 'Họ và tên phải có ít nhất 2 ký tự';
    }

    emit(state.copyWith(
        fullName: fullName,
        fullNameError: fullNameError
    ));
  }

  void onEmailChanged(String email) {
    final emailError = AuthValidator.validateEmail(email) ?? '';
    emit(state.copyWith(
      email: email,
      emailError: emailError
    ));
  }

  void onPasswordChanged(String password) {
    final passwordError = AuthValidator.validatePassword(password) ?? '';
    emit(state.copyWith(
      password: password,
      passwordError: passwordError,
      // Kiểm tra lại xác nhận mật khẩu
      confirmPasswordError: AuthValidator.validateConfirmPassword(
        password, 
        state.confirmPassword
      ) ?? '',
    ));
  }

  void onConfirmPasswordChanged(String confirmPassword) {
    final confirmPasswordError = AuthValidator.validateConfirmPassword(
      state.password,
      confirmPassword
    ) ?? '';
    
    emit(state.copyWith(
        confirmPassword: confirmPassword,
        confirmPasswordError: confirmPasswordError
    ));
  }

  Future<void> signUp() async {
    emit(state.copyWith(isLoading: true));

    // Kiểm tra toàn bộ các trường một lần nữa trước khi submit
    String fullNameError = state.fullName.isEmpty ? 'Họ và tên không được để trống' : '';
    if (state.fullName.isNotEmpty && state.fullName.length < 2) {
      fullNameError = 'Họ và tên phải có ít nhất 2 ký tự';
    }

    String emailError = state.email.isEmpty ? 'Email không được để trống' : '';
    // Kiểm tra email bằng biểu thức chính quy
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (state.email.isNotEmpty && !emailRegex.hasMatch(state.email)) {
      emailError = 'Email không đúng định dạng';
    }

    String passwordError = state.password.isEmpty ? 'Mật khẩu không được để trống' : '';
    // Revalidate confirm password using AuthValidator
    String confirmPasswordError = AuthValidator.validateConfirmPassword(state.password, state.confirmPassword) ?? '';

    // Nếu có lỗi thì không tiếp tục đăng ký
    if (fullNameError.isNotEmpty ||
        emailError.isNotEmpty ||
        passwordError.isNotEmpty ||
        confirmPasswordError.isNotEmpty) {
      emit(state.copyWith(
        isLoading: false,
        fullNameError: fullNameError,
        emailError: emailError,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
      ));
      return;
    }

    try {
      final response = await _apiService.register(
        state.fullName,
        state.email,
        state.password,
      );


      print('API response: $response');

      if (response['success']) {
        emit(
            state.copyWith(
              isLoading: false,
              isSuccess: true,
              message: response['message'], // Set success message
              errorMessage: '', // Clear error message if successful
            ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          message: '', // Clear success message if failed
          errorMessage: response['message'] ?? 'Đăng ký thất bại',
        ));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Có lỗi xảy ra, vui lòng thử lại!'));
      print('Error: $e');  // In lỗi để bạn có thể debug
    }
  }
}