import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api/chat_api_service.dart';
import 'personal_info_state.dart';
import 'dart:async';

class PersonalInfoCubit extends Cubit<PersonalInfoState> {
  final ChatApiService _chatApiService;
  final String userId;

  PersonalInfoCubit(this._chatApiService, this.userId)
      : super(const PersonalInfoState()) {
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    emit(state.copyWith(status: PersonalInfoStatus.loading));
    try {
      final user = await _chatApiService.getUserById(userId);
      emit(state.copyWith(
        status: PersonalInfoStatus.success,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PersonalInfoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
} 