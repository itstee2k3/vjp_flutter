import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../data/models/group_chat.dart';
import '../../data/models/message.dart';
import '../../core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:dio/dio.dart';

class GroupChatApiService {
  final String baseUrl = ApiConfig.baseUrl;
  final String? token;
  final String? currentUserId;
  final _messageController = StreamController<Message>.broadcast();
  late final HubConnection _hubConnection;
  final Dio _dio;
  final Set<String> _processedMessageIds = {};
  final Map<int, DateTime> _lastImageSentTime = {};
  final Duration _minimumImageSendInterval = Duration(seconds: 2);

  Stream<Message> get onMessageReceived => _messageController.stream;

  GroupChatApiService({
    required this.token,
    required this.currentUserId,
  }) : _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)) {
    _initSignalR();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<void> _initSignalR() async {
    final serverUrl = '$baseUrl/chatHub'; // Replace with your actual SignalR URL
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl)
        .withAutomaticReconnect()
        .build();

    _hubConnection.on('ReceiveGroupMessage', (List<Object?>? args) {
      if (args != null && args.isNotEmpty) {
        try {
          print('Received group message data: ${args[0]}');
          final messageJson = args[0] as Map<String, dynamic>;
          
          // Kiểm tra xem tin nhắn có phải là hình ảnh không
          final bool isImageMessage = messageJson['type'] == 'image' || 
                                   (messageJson['imageUrl'] != null && messageJson['imageUrl'].toString().isNotEmpty);
          
          // Tạo ID duy nhất cho tin nhắn để theo dõi trùng lặp
          String messageId;
          if (isImageMessage) {
            // Với tin nhắn hình ảnh, tạo ID đặc biệt bao gồm cả imageUrl
            final imageUrl = messageJson['imageUrl'] ?? '';
            // Chỉ lấy 20 ký tự đầu của imageUrl để tránh ID quá dài
            final shortenedUrl = imageUrl.toString().length > 20 
                ? imageUrl.toString().substring(0, 20) 
                : imageUrl.toString();
            messageId = '${messageJson['id']}-${messageJson['senderId']}-image-${shortenedUrl}';
          } else {
            // ID thông thường cho tin nhắn văn bản
            messageId = '${messageJson['id']}-${messageJson['senderId']}-${messageJson['content']}-${messageJson['sentAt']?.toString()}'; // Include timestamp in text ID for more uniqueness
          }
          
          // Kiểm tra tin nhắn đã xử lý chưa bằng ID chính xác hơn
          if (_processedMessageIds.contains(messageId)) {
            print('Duplicate SignalR group message detected by specific ID, ignoring: $messageId');
            return;
          }
          
          // Giới hạn kích thước của set
          if (_processedMessageIds.length > 200) { // Tăng giới hạn lên 200 để đủ chỗ cho ID ảnh
            final idsToRemove = _processedMessageIds.take(50).toList();
            for (var id in idsToRemove) {
              _processedMessageIds.remove(id);
            }
          }
          
          // Đánh dấu tin nhắn đã xử lý (using the specific ID)
          _processedMessageIds.add(messageId);
          
          // Log the raw message data and its groupId type
          if (messageJson.containsKey('groupId')) {
            print('GroupId type: ${messageJson['groupId'].runtimeType}, value: ${messageJson['groupId']}');
          }
          
          final message = Message.fromJson(messageJson);
          print('Processed message groupId type: ${message.groupId.runtimeType}, value: ${message.groupId}');
          
          _messageController.add(message);
        } catch (e) {
          print('Error processing group message: $e');
        }
      }
    });

    try {
      await _hubConnection.start();
      print('SignalR connection started');
      
      // Join all groups that the user is a member of
      if (currentUserId != null) {
        try {
          final groups = await getMyGroups();
          print('Joining SignalR groups for groups: ${groups.map((g) => g.id).join(', ')}');
          
          for (var group in groups) {
            final groupName = 'group_${group.id}';
            await _hubConnection.invoke('JoinRoom', args: [groupName]);
            print('Joined SignalR room: $groupName');
          }
        } catch (e) {
          print('Error joining group rooms: $e');
        }
      }
    } catch (e) {
      print('Error starting SignalR connection: $e');
    }
  }

  Future<List<GroupChat>> getMyGroups() async {
    try {
      print('Calling API: ${_dio.options.baseUrl}/api/group');
      
      final response = await _dio.get(
        '/api/group',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => true,
        ),
      );
      
      print('GetMyGroups response status: ${response.statusCode}');
      print('GetMyGroups response data: ${response.data}');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get groups: HTTP ${response.statusCode}, Response: ${response.data}');
      }
      
      if (response.data == null) {
        throw Exception('Null response data from server');
      }
      
      List<GroupChat> groups = [];
      
      if (response.data is List) {
        groups = await _processGroupList(response.data as List);
      } else if (response.data is Map && response.data.containsKey('groups')) {
        groups = await _processGroupList(response.data['groups'] as List);
      } else {
        throw Exception('Invalid response format: ${response.data.runtimeType}');
      }

      // Lấy số lượng thành viên cho mỗi nhóm
      final updatedGroups = <GroupChat>[];
      for (var group in groups) {
        try {
          final members = await getGroupMembers(group.id);
          updatedGroups.add(group.copyWith(memberCount: members.length));
        } catch (e) {
          print('Error getting member count for group ${group.id}: $e');
          updatedGroups.add(group); // Giữ nguyên group nếu không lấy được số thành viên
        }
      }

      return updatedGroups;
    } catch (e) {
      print('Failed to get groups: $e');
      throw Exception('Failed to get groups: $e');
    }
  }

  Future<List<GroupChat>> _processGroupList(List rawGroups) async {
    return rawGroups
        .map((json) {
          try {
            return GroupChat.fromJson(json);
          } catch (e) {
            print('Error parsing group: $e, data: $json');
            return null;
          }
        })
        .whereType<GroupChat>()
        .toList();
  }

  Future<GroupChat> createGroup({
    required String name,
    String? avatar,
    required List<String> memberIds,
  }) async {
    try {
      final response = await _dio.post(
        '/api/group/create',
        data: {
          'name': name,
          'avatar': avatar,
          'memberIds': memberIds,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return GroupChat.fromJson(response.data['group']);
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(int groupId) async {
    try {
      final response = await _dio.get(
        '/api/group/$groupId/members',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to get group members: $e');
    }
  }

  Future<Map<String, dynamic>> getGroupMessages(int groupId, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/group/messages/$groupId?page=$page&pageSize=$pageSize"),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('data') && responseData['data'] is List && responseData.containsKey('hasMore')) {
          final List<dynamic> messagesJson = responseData['data'];
          final List<Message> messages = messagesJson.map((json) => Message.fromJson(json)).toList();
          final bool hasMore = responseData['hasMore'] as bool;
          
          // Sắp xếp lại để đảm bảo tin nhắn cũ nhất ở đầu (API trả về mới nhất trước)
          messages.sort((a, b) => a.sentAt.compareTo(b.sentAt)); 
          
          return {'messages': messages, 'hasMore': hasMore};
        } else {
          throw Exception('Invalid API response format for group messages');
        }
      } else {
        throw Exception('Failed to load group messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getGroupMessages: $e');
      rethrow;
    }
  }

  Future<void> sendGroupMessage({
    required int groupId,
    required String content,
    String? imageUrl,
    String? type,
  }) async {
    try {
      print('Sending group message to group: $groupId');
      
      final isImageMessage = type == 'image' || (imageUrl != null && imageUrl.isNotEmpty);
      
      // Kiểm tra thời gian gửi ảnh gần đây nhất cho nhóm này
      if (isImageMessage) {
        final now = DateTime.now();
        final lastSentTime = _lastImageSentTime[groupId] ?? DateTime(2000); // Mặc định thời gian xa
        final timeSinceLastSend = now.difference(lastSentTime);
        
        if (timeSinceLastSend < _minimumImageSendInterval) {
          print('Anti-duplicate: Image sent too soon after previous image (${timeSinceLastSend.inMilliseconds}ms). Waiting...');
          // Chờ đủ thời gian tối thiểu
          await Future.delayed(_minimumImageSendInterval - timeSinceLastSend);
          print('Continuing to send after delay');
        }
        
        // Cập nhật thời gian gửi ảnh gần đây nhất
        _lastImageSentTime[groupId] = DateTime.now();
      }
      
      final messageData = {
        'groupChatId': groupId,
        'content': content,
      };
      
      // Handle image content
      if (imageUrl != null && imageUrl.startsWith('data:image')) {
        // If imageUrl is a base64 image, set it directly in content
        messageData['content'] = imageUrl;
        messageData['type'] = 'image';
        print('Sending base64 image to group $groupId (length: ${imageUrl.length})');
      } else if (imageUrl != null) {
        // If imageUrl is a regular URL, set it as imageUrl
        messageData['imageUrl'] = imageUrl;
        messageData['type'] = 'image';
        print('Sending image URL to group $groupId: ${imageUrl.substring(0, math.min(50, imageUrl.length))}...');
      }
      
      // Add type if specified and not already set
      if (type != null && !messageData.containsKey('type')) {
        messageData['type'] = type;
      }
      
      print('Sending message data: ${isImageMessage 
        ? "${messageData['groupChatId']}, type: ${messageData['type']}, content length: ${messageData['content'].toString().length}" 
        : messageData.toString().substring(0, math.min(100, messageData.toString().length))}...');
      
      // Tạo uniqueId cho tin nhắn này để tránh xử lý trùng lặp
      final now = DateTime.now();
      final uniqueId = isImageMessage 
          ? '$currentUserId-image-${now.millisecondsSinceEpoch ~/ 5000}'
          : '$currentUserId-${content}-${now.millisecondsSinceEpoch}';
          
      _processedMessageIds.add(uniqueId);
      
      // Thêm ID khác cho trường hợp ảnh
      if (isImageMessage) {
        // Thêm một ID chính xác hơn cho khoảng thời gian 2 giây
        for (int i = -2; i <= 2; i++) {
          final timeBasedId = '$currentUserId-image-${now.add(Duration(seconds: i)).millisecondsSinceEpoch ~/ 1000}';
          _processedMessageIds.add(timeBasedId);
        }
      }
      
      final response = await _dio.post(
        '/api/group/send',
        data: messageData,
        options: Options(
          headers: _headers,
          sendTimeout: isImageMessage ? const Duration(seconds: 60) : const Duration(seconds: 15),
          receiveTimeout: isImageMessage ? const Duration(seconds: 30) : const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to send group message: HTTP ${response.statusCode}');
      }
      
      print('Group message sent successfully: ${response.data}');
    } catch (e) {
      print('Error sending group message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<String> uploadGroupImage(int groupId, File imageFile, {String caption = '[Hình ảnh]'}) async {
    try {
      // Log file information to debug
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      print('Image file size: ${await imageFile.length()} bytes');
      
      // Create a multipart request
      final formData = FormData.fromMap({
        'groupId': groupId.toString(),
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'caption': caption,
      });
      
      print('Uploading image for group: $groupId');
      
      // Thiết lập timeout dài hơn cho upload ảnh
      final response = await _dio.post(
        '/api/upload/group-image',
        data: formData,
        options: Options(
          headers: _headers,
          sendTimeout: const Duration(seconds: 30), // 30 giây để gửi
          receiveTimeout: const Duration(seconds: 30), // 30 giây để nhận phản hồi
        ),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: HTTP ${response.statusCode}');
      }
      
      if (response.data == null || !response.data.containsKey('imageUrl')) {
        throw Exception('Invalid response: Missing imageUrl');
      }
      
      final imageUrl = response.data['imageUrl'] as String;
      print('Image uploaded successfully: $imageUrl');
      
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      
      // Nếu gặp lỗi timeout hoặc lỗi mạng, thử fallback về base64
      if (e.toString().contains('timeout') || 
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        print('Detected network issue, falling back to base64 encoding');
        // Thay vì throw exception, ta trả về URL đặc biệt để báo hiệu cần fallback
        return 'fallback_to_base64';
      }
      
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // Fallback method to send image as base64 directly in the message
  Future<void> sendGroupImageAsBase64(int groupId, File imageFile, {String caption = '[Hình ảnh]'}) async {
    try {
      print('Converting image to base64 for group: $groupId');
      
      // Read the file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Convert bytes to base64
      final base64Image = base64Encode(bytes);
      
      // Determine the mime type
      String mimeType = 'image/jpeg'; // Default
      if (imageFile.path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (imageFile.path.endsWith('.gif')) {
        mimeType = 'image/gif';
      }
      
      // Create the data URL
      final dataUrl = 'data:$mimeType;base64,$base64Image';
      
      print('Image converted to base64, size: ${base64Image.length} chars');
      
      // Send the image as a message with the data URL
      await sendGroupMessage(
        groupId: groupId,
        content: caption.isEmpty ? '[Hình ảnh]' : caption,
        imageUrl: dataUrl,
        type: 'image',
      );
      
      print('Image sent as base64 successfully');
    } catch (e) {
      print('Error sending image as base64: $e');
      throw Exception('Failed to send image: $e');
    }
  }

  void dispose() {
    _messageController.close();
    _hubConnection.stop();
    _processedMessageIds.clear();
  }
} 