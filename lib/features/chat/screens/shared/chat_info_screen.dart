import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../cubits/group/group_info_cubit.dart';
import '../../cubits/group/group_info_state.dart';
import '../../cubits/personal/personal_info_cubit.dart';
import '../../cubits/personal/personal_info_state.dart';
import '../../../../core/config/api_config.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/painting.dart';

enum ChatType { personal, group }

class ChatInfoScreen extends StatefulWidget {
  final String chatIdString;
  final ChatType chatType;

  const ChatInfoScreen({
    Key? key,
    required this.chatIdString,
    required this.chatType,
  }) : super(key: key);

  @override
  _ChatInfoScreenState createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  GroupInfoCubit _getGroupCubit(BuildContext context) {
    if (widget.chatType != ChatType.group) {
      throw StateError('Cannot access GroupInfoCubit for personal chat');
    }
    return context.read<GroupInfoCubit>();
  }

  PersonalInfoCubit _getPersonalCubit(BuildContext context) {
    if (widget.chatType != ChatType.personal) {
      throw StateError('Cannot access PersonalInfoCubit for group chat');
    }
    return context.read<PersonalInfoCubit>();
  }

  Future<void> _pickImage(BuildContext context) async {
    if (widget.chatType != ChatType.group) return;

    final cubit = _getGroupCubit(context);
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
    if (widget.chatType != ChatType.group) return;

    final TextEditingController nameController = TextEditingController(text: currentName);
    final cubit = _getGroupCubit(context);

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
    // Use BlocBuilder based on chatType
    if (widget.chatType == ChatType.group) {
      return BlocConsumer<GroupInfoCubit, GroupInfoState>(
        listener: (context, state) {
          _handleGroupListeners(context, state);
        },
        builder: (context, state) {
          return _buildContent(context, state);
        },
      );
    } else { // ChatType.personal
      return BlocConsumer<PersonalInfoCubit, PersonalInfoState>(
        listener: (context, state) {
          _handlePersonalListeners(context, state);
        },
        builder: (context, state) {
          return _buildContent(context, state);
        },
      );
    }
  }

  // --- Listener Handlers ---
  void _handleGroupListeners(BuildContext context, GroupInfoState state) {
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
    // Add other group-specific listeners if needed
  }

  void _handlePersonalListeners(BuildContext context, PersonalInfoState state) {
     if (state.status == PersonalInfoStatus.failure && state.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
        );
    }
    // Add other personal-specific listeners if needed
  }

  // --- Main Content Builder ---
  Widget _buildContent(BuildContext context, dynamic state) {
    // Determine loading/uploading state and data based on state type
    bool isLoading = false;
    bool isUploading = false;
    String? name;
    String? avatarRelativePath;
    int memberCount = 0;
    // Add other common variables if needed

    if (state is GroupInfoState) {
      isLoading = state.status == GroupInfoStatus.loading;
      isUploading = state.status == GroupInfoStatus.uploadingAvatar;
      name = state.group?.name;
      avatarRelativePath = state.group?.avatarUrl;
      memberCount = state.group?.memberCount ?? 0;
    } else if (state is PersonalInfoState) {
      isLoading = state.status == PersonalInfoStatus.loading;
      // Personal chats don't have avatar uploading in this screen (currently)
      isUploading = false;
      name = state.user?.fullName; // Assuming User model has fullName
      avatarRelativePath = state.user?.avatarUrl;
      memberCount = 0; // Personal chats don't have member count
    }

    String displayName = name ?? (isLoading ? "Loading..." : "N/A");

    String? fullAvatarUrl;
    if (avatarRelativePath != null && avatarRelativePath.isNotEmpty) {
      fullAvatarUrl = ApiConfig.getFullImageUrl(avatarRelativePath);
    }

    // Existing scaffold structure
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatType == ChatType.group ? 'Group Options' : 'User Info'),
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
                // Use displayName and fullAvatarUrl
                _buildChatHeader(context, displayName, fullAvatarUrl, isUploading),

                // Conditionally show quick actions
                if (widget.chatType == ChatType.group)
                   _buildGroupQuickActions(context)
                else // Personal Chat
                   _buildPersonalQuickActions(context),

                // --- Divider --- 
                const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)),

                // --- Personal Specific Tiles (Top) ---
                if (widget.chatType == ChatType.personal) ...[
                   _buildInfoTile(
                     context,
                     icon: Icons.edit_note_outlined, // Or appropriate icon
                     title: 'Đổi tên gợi nhớ', // Nickname
                     onTap: () { /* TODO: Edit Nickname */ },
                   ),
                   _buildSwitchTile(
                     context,
                     icon: Icons.star_border_outlined,
                     title: 'Đánh dấu bạn thân', // Mark as close friend
                     value: false, // Replace with actual status
                     onChanged: (bool value) { /* TODO */ },
                   ),
                    _buildInfoTile(
                     context,
                     icon: Icons.wysiwyg_outlined, // Or appropriate icon
                     title: 'Nhật ký chung', // Shared feed/journal
                     onTap: () { /* TODO: Navigate to shared feed */ },
                   ),
                   const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)), // Extra divider for personal
                ],

                // --- Group Specific Tiles (Top) ---
                if (widget.chatType == ChatType.group) ...[
                  _buildInfoTile(
                    context,
                    icon: Icons.info_outline,
                    title: 'Thêm mô tả nhóm', // Add group description (matches image)
                    onTap: () { /* TODO */ },
                  ),
                ],

                // --- Common Tile: Photos, files, links ---
                 _buildInfoTile(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: 'Ảnh, file, link',
                  // TODO: Add preview widget like in the image
                  onTap: () { /* TODO */ },
                ),

                // --- Group Specific Tiles (Middle) ---
                if (widget.chatType == ChatType.group) ...[
                   _buildInfoTile(
                      context,
                      icon: Icons.calendar_today_outlined,
                      title: 'Lịch nhóm',
                      onTap: () { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.push_pin_outlined,
                      title: 'Tin nhắn đã ghim',
                      onTap: () { /* TODO */ },
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.poll_outlined,
                      title: 'Bình chọn',
                      onTap: () { /* TODO */ },
                    ),
                   const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)), // Divider for group
                   _buildInfoTile(
                    context,
                    icon: Icons.group_outlined,
                    title: 'Xem thành viên ($memberCount)',
                    onTap: () { /* TODO: Navigate to members screen */ },
                  ),
                  _buildInfoTile(
                    context,
                    icon: Icons.link_outlined,
                    title: 'Link nhóm',
                    subtitle: "https://zalo.me/g/sfaeqe578", // Replace with dynamic link if available
                    onTap: () { /* TODO */ },
                  ),
                  const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)), // Divider for group
                ],

                // --- Personal Specific Tiles (Middle) ---
                if (widget.chatType == ChatType.personal) ...[
                    _buildInfoTile(
                     context,
                     icon: Icons.group_add_outlined,
                     title: 'Tạo nhóm với ${name ?? "User"}', // Create group with user
                     onTap: () { /* TODO: Create Group */ },
                   ),
                   _buildInfoTile(
                     context,
                     icon: Icons.person_add_alt_outlined, // Add user to existing group?
                     title: 'Thêm ${name ?? "User"} vào nhóm',
                     onTap: () { /* TODO: Add user to group */ },
                   ),
                   _buildInfoTile(
                     context,
                     icon: Icons.groups_outlined,
                     title: 'Xem nhóm chung', // View shared groups
                     onTap: () { /* TODO: Navigate to shared groups */ },
                   ),
                   const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)), // Divider for personal
                ],

                // --- Common Settings Section ---
                 _buildInfoTile(
                  context,
                  icon: Icons.label_outline,
                  title: 'Mục hiển thị', // Display setting (matches images)
                  subtitle: 'Ưu tiên', // Example subtitle
                  onTap: () { /* TODO */ },
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.sell_outlined,
                  title: 'Thẻ phân loại', // Tag (matches images)
                  subtitle: widget.chatType == ChatType.group ? 'Công việc' : 'Chưa gắn thẻ', // Dynamic subtitle
                  onTap: () { /* TODO */ },
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.push_pin_outlined,
                  title: 'Ghim trò chuyện', // Pin chat
                  value: false, // Replace with actual pin status
                  onChanged: (bool value) { /* TODO */ },
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.visibility_off_outlined,
                  title: 'Ẩn trò chuyện', // Hide chat
                  value: false, // Replace with actual hide status
                  onChanged: (bool value) { /* TODO */ },
                ),

                // --- Personal Specific Tiles (Bottom Settings) ---
                if (widget.chatType == ChatType.personal) ...[
                    _buildSwitchTile(
                     context,
                     icon: Icons.call_outlined, // Use a call icon
                     title: 'Báo cuộc gọi đến', // Report incoming call?
                     value: true, // Replace with actual status
                     onChanged: (bool value) { /* TODO */ },
                   ),
                   _buildInfoTile(
                     context,
                     icon: Icons.timer_off_outlined, // Timer icon
                     title: 'Tin nhắn tự xoá', // Disappearing messages
                     subtitle: 'Không tự xoá',
                     onTap: () { /* TODO */ },
                   ),
                ],

                // --- Common Tile: Personal Settings (appears in both) ---
                 _buildInfoTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt cá nhân',
                  onTap: () { /* TODO */ },
                ),

                // --- Divider before Danger Zone --- 
                const Divider(height: 10, thickness: 10, color: Color(0xFFf0f2f5)),

                // --- Common Tile: Report ---
                _buildInfoTile(
                  context,
                  icon: Icons.warning_amber_outlined,
                  title: 'Báo xấu', // Report
                  onTap: () { /* TODO */ },
                ),
                
                 // --- Personal Specific Tile: Block Management ---
                if (widget.chatType == ChatType.personal) ...[
                   _buildInfoTile(
                     context,
                     icon: Icons.block_flipped, // Block icon
                     title: 'Quản lý chặn', // Block management
                     onTap: () { /* TODO: Navigate to block management */ },
                   ),
                ],

                // --- Common Tile: Chat Usage ---
                _buildInfoTile(
                  context,
                  icon: Icons.data_usage_outlined,
                  title: 'Dung lượng trò chuyện', // Chat usage
                  onTap: () { /* TODO */ },
                ),

                // --- Common Tile: Delete History ---
                ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    title: const Text('Xoá lịch sử trò chuyện', style: TextStyle(color: Colors.red)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    dense: true,
                    onTap: () { /* TODO: Handle delete history */ },
                 ),

                 // --- Conditional Leave/Block Options (Keep as is) ---
                 if (widget.chatType == ChatType.group) ...[
                   ListTile(
                     leading: const Icon(Icons.logout_outlined, color: Colors.red),
                     title: const Text('Rời nhóm', style: TextStyle(color: Colors.red)), // Leave group
                     trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                     dense: true,
                     onTap: () { /* TODO: Handle leave group */ },
                   ),
                 ] else ...[
                   // Block user option (already present, might be redundant with Block Management)
                   // Consider removing this if Block Management handles it.
                   // ListTile(
                   //   leading: const Icon(Icons.block_flipped, color: Colors.red),
                   //   title: const Text('Block user', style: TextStyle(color: Colors.red)),
                   //   trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                   //   dense: true,
                   //   onTap: () { /* TODO: Handle block user */ },
                   // ),
                 ],
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // Rename _buildGroupHeader to _buildChatHeader
  Widget _buildChatHeader(BuildContext context, String displayName, String? fullAvatarUrl, bool isUploading) {
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
                  // --- Conditionally show Camera Icon for Groups only ---
                  if (widget.chatType == ChatType.group)
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
              // --- Conditionally show Loading Indicator for Groups only ---
              if (widget.chatType == ChatType.group && isUploading)
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
                      displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                   ),
                ),
                // --- Conditionally show Edit Icon for Groups only ---
                if (widget.chatType == ChatType.group)
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
                        _showEditGroupNameDialog(context, displayName);
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

  // --- Quick Action Widgets ---

  // Updated Group Quick Actions
  Widget _buildGroupQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionItem(context, Icons.search, 'Tìm\ntin nhắn', () { /* TODO */ }),
          _quickActionItem(context, Icons.person_add_alt_1_outlined, 'Thêm\nthành viên', () { /* TODO */ }),
          _quickActionItem(context, Icons.palette_outlined, 'Đổi\nhình nền', () { /* TODO */ }),
          _quickActionItem(context, Icons.notifications_off_outlined, 'Tắt\nthông báo', () { /* TODO */ }),
        ],
      ),
    );
  }

  // New Personal Quick Actions
  Widget _buildPersonalQuickActions(BuildContext context) {
    // TODO: Get user's name for dynamic titles if needed
    // final state = context.read<PersonalInfoCubit>().state;
    // final userName = state.user?.fullName ?? "User";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionItem(context, Icons.search, 'Tìm\ntin nhắn', () { /* TODO */ }),
          _quickActionItem(context, Icons.account_circle_outlined, 'Trang\ncá nhân', () { /* TODO: Navigate to profile */ }),
          _quickActionItem(context, Icons.palette_outlined, 'Đổi\nhình nền', () { /* TODO */ }),
          _quickActionItem(context, Icons.notifications_off_outlined, 'Tắt\nthông báo', () { /* TODO */ }),
        ],
      ),
    );
  }

  // Generic Quick Action Item (No changes needed)
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