import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
        final messageJson = args[0] as Map<String, dynamic>;
        final message = Message.fromJson(messageJson);
        _messageController.add(message);
      }
    });

    try {
      await _hubConnection.start();
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
      final url = '/api/group/messages/$groupId';
      print('Fetching group messages: $url with page=$page, pageSize=$pageSize');
      
      final response = await _dio.get(
        url,
        queryParameters: {'page': page, 'pageSize': pageSize},
        options: Options(headers: _headers),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get group messages: HTTP ${response.statusCode}');
      }
      
      // Extract messages and pagination info from response
      final data = response.data as Map<String, dynamic>;
      final List<Message> messages = [];
      
      if (data.containsKey('messages') && data['messages'] is List) {
        messages.addAll((data['messages'] as List).map((json) => Message.fromJson(json)).toList());
      }
      
      return {
        'messages': messages,
        'total': data['total'] ?? 0,
        'page': data['page'] ?? page,
        'pageSize': data['pageSize'] ?? pageSize,
        'hasMore': data['hasMore'] ?? false,
      };
    } catch (e) {
      print('Error fetching group messages: $e');
      throw Exception('Failed to get group messages: $e');
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
      
      final messageData = {
        'groupChatId': groupId,
        'content': content,
      };
      
      // Handle image content
      if (imageUrl != null && imageUrl.startsWith('data:image')) {
        // If imageUrl is a base64 image, set it directly in content
        messageData['content'] = imageUrl;
        messageData['type'] = 'image';
      } else if (imageUrl != null) {
        // If imageUrl is a regular URL, set it as imageUrl
        messageData['imageUrl'] = imageUrl;
        messageData['type'] = 'image';
      }
      
      // Add type if specified and not already set
      if (type != null && !messageData.containsKey('type')) {
        messageData['type'] = type;
      }
      
      print('Sending message data: ${messageData.toString().substring(0, messageData.toString().length > 100 ? 100 : messageData.toString().length)}...');
      
      final response = await _dio.post(
        '/api/group/send',
        data: messageData,
        options: Options(headers: _headers),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to send group message: HTTP ${response.statusCode}');
      }
      
      print('Group message sent successfully');
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
      
      final response = await _dio.post(
        '/api/upload/group-image',
        data: formData,
        options: Options(headers: _headers),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: HTTP ${response.statusCode}');
      }
      
      final imageUrl = response.data['imageUrl'] as String;
      print('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
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
  }
} 