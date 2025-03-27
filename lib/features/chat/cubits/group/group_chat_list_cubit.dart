import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/group_chat.dart';
import '../../../../services/api/group_chat_api_service.dart';

class GroupChatListState {
  final List<GroupChat> groups;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  GroupChatListState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  GroupChatListState copyWith({
    List<GroupChat>? groups,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return GroupChatListState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class GroupChatListCubit extends Cubit<GroupChatListState> {
  final GroupChatApiService _apiService;

  GroupChatListCubit({
    required GroupChatApiService apiService,
  }) : _apiService = apiService,
       super(GroupChatListState()) {
    loadGroups();
  }

  Future<void> loadGroups([GroupChatApiService? apiService]) async {
    try {
      emit(state.copyWith(isLoading: true));
      final service = apiService ?? _apiService;
      final groups = await service.getMyGroups();
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

  Future<void> createGroup(String name, String? description) async {
    try {
      emit(state.copyWith(isLoading: true));
      final newGroup = await _apiService.createGroup(
        name: name,
        memberIds: [], // You'll need to provide member IDs when creating a group
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

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  List<GroupChat> get filteredGroups {
    if (state.searchQuery.isEmpty) {
      return state.groups;
    }
    return state.groups.where((group) =>
      group.name.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
      (group.description?.toLowerCase().contains(state.searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Future<void> close() {
    return super.close();
  }
} 
