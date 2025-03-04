import 'package:bloc/bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/sign_in/sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit() : super(const SignInState());

  void setErrorMessage(String message) {
    emit(SignInState(errorMessage: message));
  }
  void clearError() {
    emit(const SignInState(errorMessage: '')); // Đặt errorMessage thành rỗng
  }
}