import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api/group_chat_api_service.dart';
import 'group_info_state.dart';
import '../../../../data/models/group_chat.dart'; // Required model

class GroupInfoCubit extends Cubit<GroupInfoState> {
  final GroupChatApiService _apiService;
  final int groupId;

  GroupInfoCubit(this._apiService, this.groupId) : super(const GroupInfoState()) {
    loadGroupDetails();
  }

  Future<void> loadGroupDetails() async {
    if (state.status == GroupInfoStatus.loading) return;
    emit(state.copyWith(status: GroupInfoStatus.loading, clearError: true));
    try {
      // TODO: Implement API call to get group details by ID if available
      // Example: final groupDetails = await _apiService.getGroupDetails(groupId);
      // Currently, no such API exists, so fetching from getMyGroups and finding by ID (needs optimization)
      final groups = await _apiService.getMyGroups();
      final group = groups.firstWhere(
         (g) => g.id == groupId,
         orElse: () => throw Exception("Group not found in user's list"), // Or return null/error state
       );

      emit(state.copyWith(status: GroupInfoStatus.success, group: group));
    } catch (e) {
      emit(state.copyWith(status: GroupInfoStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    if (state.status == GroupInfoStatus.uploadingAvatar) return;
    emit(state.copyWith(status: GroupInfoStatus.uploadingAvatar, clearError: true, clearNewAvatar: true));
    try {
      final newAvatarRelativePath = await _apiService.updateGroupAvatar(groupId, imageFile);

      if (newAvatarRelativePath != null) {
         print("✓ New avatar path received: $newAvatarRelativePath for group: $groupId");
         
         // Update state with new avatar (URL only) and success status
         // Full avatar URL will be constructed in UI when reading state.group
         emit(state.copyWith(
           status: GroupInfoStatus.success,
           // Update group in state with new avatar path
           group: state.group?.copyWith(avatar: newAvatarRelativePath),
           newAvatarUrl: newAvatarRelativePath, // Temporarily store to let UI know update succeeded
         ));
         
         // Notify other components about the avatar update
         print("Notifying all listeners about avatar update for group: $groupId");
         _apiService.notifyGroupAvatarUpdated(groupId, newAvatarRelativePath);
      } else {
        throw Exception("API did not return the new avatar URL.");
      }
    } catch (e) {
      print("❌ Error updating avatar: $e");
      emit(state.copyWith(status: GroupInfoStatus.failure, errorMessage: "Error updating image: ${e.toString()}"));
    }
  }

  // Potential future methods: updateGroupName, addMembers, removeMember, leaveGroup...
} 