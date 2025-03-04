import 'package:equatable/equatable.dart';

class SignInState extends Equatable {
  final String errorMessage;

  const SignInState({this.errorMessage = ''});

  @override
  List<Object> get props => [errorMessage];
}