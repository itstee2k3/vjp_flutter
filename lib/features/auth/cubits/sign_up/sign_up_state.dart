import 'package:equatable/equatable.dart';

class SignUpState extends Equatable {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isLoading;
  final bool isSuccess;
  final String message; // Success message
  final String errorMessage;

  final String fullNameError;
  final String emailError;
  final String passwordError;
  final String confirmPasswordError;

  const SignUpState({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.isSuccess = false,
    this.message = '',
    this.errorMessage = '',
    this.fullNameError = '',
    this.emailError = '',
    this.passwordError = '',
    this.confirmPasswordError = '',
  });

  SignUpState copyWith({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isLoading,
    bool? isSuccess,
    String? message,
    String? errorMessage,
    String? fullNameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
  }) {
    return SignUpState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
      fullNameError: fullNameError ?? this.fullNameError,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      confirmPasswordError: confirmPasswordError ?? this.confirmPasswordError,
    );
  }

  @override
  List<Object> get props => [fullName, email, password, confirmPassword, isLoading, isSuccess, message, errorMessage, fullNameError, emailError, passwordError, confirmPasswordError];
}
