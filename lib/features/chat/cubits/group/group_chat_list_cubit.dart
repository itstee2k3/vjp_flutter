import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/group_chat.dart';
import '../../../../services/api/group_chat_api_service.dart';
import 'group_chat_list_state.dart';

class GroupChatListCubit extends Cubit<GroupChatListState> {
  final GroupChatApiService _apiService;
  StreamSubscription? _avatarUpdateSubscription;
  StreamSubscription? _nameUpdateSubscription;
  bool _isLoading = false;

  GroupChatListCubit(this._apiService) : super(GroupChatListState.initial()) {
    // loadGroups();
    _listenForAvatarUpdates();
    _listenForNameUpdates();
  }

  void _listenForAvatarUpdates() {
    _avatarUpdateSubscription = _apiService.onGroupAvatarUpdated.listen((update) {
      final int groupId = update['groupId'];
      final String newAvatarUrl = update['avatarUrl'];
      
      final updatedGroups = state.groups.map((group) {
        if (group.id == groupId) {
          // print('Updating avatar in group list for group $groupId: $newAvatarUrl');
          return group.copyWith(avatar: newAvatarUrl);
        }
        return group;
      }).toList();
      
      emit(state.copyWith(groups: updatedGroups));
    });
  }

  void _listenForNameUpdates() {
    _nameUpdateSubscription = _apiService.onGroupNameUpdated.listen((update) {
      // Handle potential null map gracefully
      if (update == null) {
        print('❌ Error: Received null update in GroupChatListCubit name listener.');
        return;
      }
      
      // Safely access data, providing default values or handling nulls
      final int? groupId = update['groupId'] as int?;
      final String? name = update['name'] as String?; // Use the correct key 'name'

      if (groupId == null || name == null) {
         print('❌ Error: Received invalid name update payload in GroupChatListCubit. Data: $update');
         return;
      }

      print('Cubit received name update for group $groupId: $name');

      final updatedGroups = state.groups.map((group) {
        if (group.id == groupId) {
          print('Updating name in group list for group $groupId to: $name');
          return group.copyWith(name: name); // Use the correct variable 'name'
        }
        return group;
      }).toList();
      
      emit(state.copyWith(groups: updatedGroups));
    }, onError: (error) {
      print('❌ Error in GroupChatListCubit name update stream: $error');
    });
  }

  Future<void> loadGroups() async {
    // Prevent multiple simultaneous loads
    if (_isLoading || state.isLoading) {
      print('🚫 Skipping loadGroups - already loading');
      return;
    }

    try {
      _isLoading = true;
      print('📱 Loading groups...');
      emit(state.copyWith(isLoading: true));
      final groups = await _apiService.getMyGroups();
      print('✓ Loaded ${groups.length} groups');
      emit(state.copyWith(
        groups: groups,
        isLoading: false,
      ));
    } catch (e) {
      print('❌ Error loading groups: $e');
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    } finally {
      _isLoading = false;
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
    _avatarUpdateSubscription?.cancel();
    _nameUpdateSubscription?.cancel();
    return super.close();
  }
}
