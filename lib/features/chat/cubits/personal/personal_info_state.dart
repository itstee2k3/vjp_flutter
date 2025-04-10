import 'package:equatable/equatable.dart';
import '../../../../data/models/user.dart'; // Adjust path if necessary

enum PersonalInfoStatus { initial, loading, success, failure }

class PersonalInfoState extends Equatable {
  final PersonalInfoStatus status;
  final User? user;
  final String? errorMessage;

  const PersonalInfoState({
    this.status = PersonalInfoStatus.initial,
    this.user,
    this.errorMessage,
  });

  PersonalInfoState copyWith({
    PersonalInfoStatus? status,
    User? user,
    String? errorMessage,
    // Helper to clear error message easily
    bool clearError = false,
  }) {
    return PersonalInfoState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
} 