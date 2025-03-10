import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api/api_service.dart';
import 'sign_up_state.dart';
import 'sign_up_event.dart';
import '../../../../core/validators/auth_validator.dart';

class SignUpCubit extends Bloc<SignUpEvent, SignUpState> {
  final ApiService _apiService;

  SignUpCubit(this._apiService) : super(const SignUpState()) {
    on<SignUpFullNameChanged>(_onFullNameChanged);
    on<SignUpEmailChanged>(_onEmailChanged);
    on<SignUpPasswordChanged>(_onPasswordChanged);
    on<SignUpConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<SignUpSubmitted>(_onSubmitted);
  }

  void _onFullNameChanged(SignUpFullNameChanged event, Emitter<SignUpState> emit) {
    String fullNameError = '';

    // Kiểm tra độ dài
    if (event.fullName.isEmpty) {
      fullNameError = 'Họ và tên không được để trống';
    } else if (event.fullName.length < 2) {
      fullNameError = 'Họ và tên phải có ít nhất 2 ký tự';
    }

    emit(state.copyWith(
        fullName: event.fullName,
        fullNameError: fullNameError
    ));
  }

  void _onEmailChanged(SignUpEmailChanged event, Emitter<SignUpState> emit) {
    final emailError = AuthValidator.validateEmail(event.email) ?? '';
    emit(state.copyWith(
      email: event.email,
      emailError: emailError
    ));
  }

  void _onPasswordChanged(SignUpPasswordChanged event, Emitter<SignUpState> emit) {
    final passwordError = AuthValidator.validatePassword(event.password) ?? '';
    emit(state.copyWith(
      password: event.password,
      passwordError: passwordError,
      // Kiểm tra lại xác nhận mật khẩu
      confirmPasswordError: AuthValidator.validateConfirmPassword(
        event.password, 
        state.confirmPassword
      ) ?? '',
    ));
  }

  void _onConfirmPasswordChanged(SignUpConfirmPasswordChanged event, Emitter<SignUpState> emit) {
    final confirmPasswordError = AuthValidator.validateConfirmPassword(
      state.password,
      event.confirmPassword
    ) ?? '';
    
    emit(state.copyWith(
        confirmPassword: event.confirmPassword,
        confirmPasswordError: confirmPasswordError
    ));
  }

  void _onSubmitted(SignUpSubmitted event, Emitter<SignUpState> emit) async {
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
    String confirmPasswordError = state.confirmPassword.isEmpty ? 'Xác nhận mật khẩu không được để trống' : '';
    // Kiểm tra mật khẩu và xác nhận mật khẩu có khớp không
    if (state.password != state.confirmPassword) {
      confirmPasswordError = 'Mật khẩu không khớp';
    }

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

  String _validateEmail(String email) {
    return AuthValidator.validateEmail(email) ?? '';
  }

  String _validatePassword(String password) {
    return AuthValidator.validatePassword(password) ?? '';
  }

  String _validateConfirmPassword(String confirmPassword) {
    if (confirmPassword.trim().isEmpty) {
      return "Xác nhận mật khẩu không được để trống!";
    }
    
    if (confirmPassword != state.password) {
      return "Mật khẩu xác nhận không khớp!";
    }
    
    return '';
  }
}