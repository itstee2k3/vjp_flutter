import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/group_chat.dart';
import '../../../../services/api/group_chat_api_service.dart';
import 'group_chat_list_state.dart';

class GroupChatListCubit extends Cubit<GroupChatListState> {
  final GroupChatApiService _apiService;

  GroupChatListCubit(this._apiService) : super(GroupChatListState.initial()) {
    loadGroups();
  }

  Future<void> loadGroups() async {
    try {
      emit(state.copyWith(isLoading: true));
      final groups = await _apiService.getMyGroups();
      emit(state.copyWith(
        groups: groups,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> createGroup({
    required String name,
    String? avatar,
    required List<String> memberIds,
  }) async {
    try {
      emit(state.copyWith(isLoading: true));
      final newGroup = await _apiService.createGroup(
        name: name,
        avatar: avatar,
        memberIds: memberIds,
      );
      
      final updatedGroups = List<GroupChat>.from(state.groups)..add(newGroup);
      emit(state.copyWith(
        groups: updatedGroups,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  void searchGroups(String query) {
    if (query.isEmpty) {
      loadGroups();
      return;
    }

    final filteredGroups = state.groups
        .where((group) =>
            group.name.toLowerCase().contains(query.toLowerCase()) ||
            (group.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();

    emit(state.copyWith(groups: filteredGroups));
  }

  void resetAndReloadGroups() {
    emit(GroupChatListState.initial());
    loadGroups();
  }

  @override
  Future<void> close() {
    return super.close();
  }
} 
