import 'package:equatable/equatable.dart';

class SignInState extends Equatable {
  final String email;
  final String password;
  final String emailError;
  final String passwordError;

  final bool isLoading;
  final bool isSuccess;
  final String? message;  // Thêm trường message
  final String errorMessage;
  final String? token; // Thêm trường token


  const SignInState({
    this.email = '',
    this.password = '',
    this.emailError = '',
    this.passwordError = '',

    this.isLoading = false,
    this.isSuccess = false,
    this.message,  // Thêm vào constructor
    this.errorMessage = '',
    this.token,

  });

  SignInState copyWith({
    String? email,
    String? password,
    String? emailError,
    String? passwordError,

    bool? isLoading,
    bool? isSuccess,
    String? message,  // Thêm vào copyWith
    String? errorMessage,
    String? token, // Thêm token vào copyWith

  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,

      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,  // Thêm vào return
      errorMessage: errorMessage ?? this.errorMessage,
      token: token ?? this.token,

    );
  }


  @override
  List<Object?> get props => [email, password, isLoading, emailError, passwordError, errorMessage, token, message];
}