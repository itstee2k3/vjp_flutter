import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../cubits/group/group_info_cubit.dart';
import '../../cubits/group/group_info_state.dart';
import '../../../../core/config/api_config.dart';
import '../../../../data/models/group_chat.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/painting.dart';

class GroupInfoScreen extends StatelessWidget {
  final int groupId;

  const GroupInfoScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    final cubit = context.read<GroupInfoCubit>();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);

      // --- Clear ALL Image Cache BEFORE updating ---
      print('Clearing PaintingBinding image cache...');
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      print('Image cache cleared.');
      // --- End Clear Cache ---

      // --- Evict OLD image cache BEFORE updating (Keep for good measure) ---
      final currentAvatarUrl = cubit.state.group?.avatarUrl;
      if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
         final oldFullUrl = ApiConfig.getFullImageUrl(currentAvatarUrl);
         // Use the non-timestamped URL for evicting the base image
         NetworkImage(oldFullUrl).evict().then((_) {
             print('Image cache evicted for OLD URL (base): $oldFullUrl');
         });
         // Also evict with a recent timestamp pattern just in case
         NetworkImage('$oldFullUrl?t=${DateTime.now().millisecondsSinceEpoch}').evict();
         print('Attempted eviction for timestamped OLD URL variants');
      }
      // --- End Evict ---

      await cubit.updateAvatar(imageFile);
      
      // Wait for state update completion (optional but can help ensure state is ready)
      // await Future.delayed(Duration(milliseconds: 100)); // Small delay
      
      // Check the state AFTER the update
      final updatedState = cubit.state; // Get the latest state
      
      if (updatedState.status == GroupInfoStatus.success && updatedState.newAvatarUrl != null) {
        // Successfully updated, show snackbar
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

        // Keep staying on the screen (pop removed previously)
      } else {
         // Handle case where update might have failed silently or state not updated as expected
         print("⚠️ Update avatar finished but state doesn't reflect success/new URL.");
         // Optionally show a generic error or just don't pop
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Avatar update status unclear. Please check manually.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
      }
    }
  }

  // Method to show the edit group name dialog
  Future<void> _showEditGroupNameDialog(BuildContext context, String currentName) async {
    final TextEditingController nameController = TextEditingController(text: currentName);
    final cubit = context.read<GroupInfoCubit>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Group Name'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: "Enter new group name"),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  Navigator.of(dialogContext).pop(); // Dismiss the dialog first
                  await cubit.updateGroupName(newName);
                } else if (newName.isEmpty) {
                   // Optionally show an error if the name is empty
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Group name cannot be empty.'), backgroundColor: Colors.orange,)
                   );
                }
                // If name hasn't changed, simply dismiss
                 else {
                    Navigator.of(dialogContext).pop();
                 }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupInfoCubit, GroupInfoState>(
      listener: (context, state) {
        if (state.status == GroupInfoStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
        } else if (state.status == GroupInfoStatus.success && state.groupNameUpdateStatus == GroupNameUpdateStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Group name updated successfully!'), backgroundColor: Colors.green,)
            );
        } else if (state.status == GroupInfoStatus.failure && state.groupNameUpdateStatus == GroupNameUpdateStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
               SnackBar(content: Text('Failed to update group name: ${state.errorMessage ?? 'Unknown error'}'), backgroundColor: Colors.red,)
            );
        }
      },
      builder: (context, state) {
        final group = state.group;
        final isLoading = state.status == GroupInfoStatus.loading;
        final isUploading = state.status == GroupInfoStatus.uploadingAvatar;

        String groupName = group?.name ?? "Loading...";
        String? groupAvatarRelativePath = group?.avatarUrl;
        int memberCount = group?.memberCount ?? 0;
        String groupLink = "https://zalo.me/g/sfaeqe578";
        bool isPinned = false;
        bool isHidden = false;

        String? fullAvatarUrl;
        if (groupAvatarRelativePath != null && groupAvatarRelativePath.isNotEmpty) {
            if (groupAvatarRelativePath.startsWith('/')) {
              fullAvatarUrl = ApiConfig.baseUrl + groupAvatarRelativePath;
            } else {
              fullAvatarUrl = groupAvatarRelativePath;
            }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Options'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            shadowColor: Colors.grey[200],
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: <Widget>[
                    _buildGroupHeader(context, groupName, fullAvatarUrl, isUploading),

                    _buildQuickActions(context),

                    const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)),

                    _buildInfoTile(
                      context,
                      icon: Icons.info_outline,
                      title: 'Add group description',
                      onTap: () { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.photo_library_outlined,
                      title: 'Photos, files, links',
                      onTap: () { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.calendar_today_outlined,
                      title: 'Group schedule',
                      onTap: () { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.push_pin_outlined,
                      title: 'Pinned messages',
                      onTap: () { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.poll_outlined,
                      title: 'Vote',
                      onTap: () { /* TODO */ },
                    ),

                    const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)),

                    _buildInfoTile(
                      context,
                      icon: Icons.group_outlined,
                      title: 'View members ($memberCount)',
                      onTap: () { /* TODO: Navigate to members screen */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.link_outlined,
                      title: 'Group link',
                      subtitle: groupLink,
                      onTap: () { /* TODO */ },
                    ),

                    const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)),

                    _buildInfoTile(
                      context,
                      icon: Icons.label_outline,
                      title: 'Display setting',
                      subtitle: 'Priority',
                      onTap: () { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.sell_outlined,
                      title: 'Tag',
                      subtitle: 'Task',
                      onTap: () { /* TODO */ },
                    ),

                    _buildSwitchTile(
                      context,
                      icon: Icons.push_pin_outlined,
                      title: 'Pin chat',
                      value: isPinned,
                      onChanged: (bool value) { /* TODO */ },
                    ),
                    _buildSwitchTile(
                      context,
                      icon: Icons.visibility_off_outlined,
                      title: 'Hide chat',
                      value: isHidden,
                      onChanged: (bool value) { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Personal settings',
                      onTap: () { /* TODO */ },
                    ),

                    const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)),
                    _buildInfoTile(
                      context,
                      icon: Icons.warning_amber_outlined,
                      title: 'Report',
                      onTap: () { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.data_usage_outlined,
                      title: 'Chat usage',
                      onTap: () { /* TODO */ },
                    ),
                    ListTile(
                       leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                       title: const Text('Delete chat history', style: TextStyle(color: Colors.red)),
                       trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                       dense: true,
                       onTap: () { /* TODO: Handle delete history */ },
                    ),

                    ListTile(
                       leading: const Icon(Icons.logout_outlined, color: Colors.red),
                       title: const Text('Leave group', style: TextStyle(color: Colors.red)),
                       trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                       dense: true,
                       onTap: () { /* TODO: Handle leave group */ },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildGroupHeader(BuildContext context, String groupName, String? fullAvatarUrl, bool isUploading) {
    // Add a timestamp to avoid caching
    String uniqueAvatarUrl = '';
    if (fullAvatarUrl != null && fullAvatarUrl.isNotEmpty) {
      uniqueAvatarUrl = ApiConfig.getFullImageUrl(fullAvatarUrl);
      if (uniqueAvatarUrl.isNotEmpty) {
        uniqueAvatarUrl += '?t=${DateTime.now().millisecondsSinceEpoch}';
      }
    }
    
    print('Using avatar URL: $uniqueAvatarUrl');
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 45,
                    key: ValueKey(uniqueAvatarUrl.isEmpty ? 'default-avatar-${DateTime.now().millisecondsSinceEpoch}' : uniqueAvatarUrl),
                    backgroundImage: uniqueAvatarUrl.isNotEmpty
                        ? NetworkImage(uniqueAvatarUrl)
                        : const AssetImage("assets/avatar_default/avatar_group_default.png") as ImageProvider,
                    backgroundColor: Colors.grey[200],
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading avatar: $exception');
                      print('Stack trace: $stackTrace');
                    },
                  ),
                  InkWell(
                    onTap: isUploading ? null : () => _pickImage(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.grey[300]?.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5)),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.black54),
                    ),
                  )
                ],
              ),
              if (isUploading)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 30.0),
                   child: Text(
                      groupName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                   ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                    onPressed: () {
                       // Show the edit dialog
                       _showEditGroupNameDialog(context, groupName);
                    },
                    tooltip: 'Edit group name',
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionItem(context, Icons.search, 'Find\nmessage', () { /* TODO */ }),
          _quickActionItem(context, Icons.person_add_alt_1_outlined, 'Add\nmember', () { /* TODO */ }),
          _quickActionItem(context, Icons.palette_outlined, 'Change\nbackground', () { /* TODO */ }),
          _quickActionItem(context, Icons.notifications_off_outlined, 'Mute\nnotification', () { /* TODO */ }),
        ],
      ),
    );
  }

  Widget _quickActionItem(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: Icon(icon, size: 24, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
     return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildSwitchTile(BuildContext context, {required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
      dense: true,
    );
  }
} 