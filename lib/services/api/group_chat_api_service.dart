import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/group_chat.dart';
import '../../data/models/message.dart';
import '../../core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:signalr_netcore/signalr_client.dart';

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

  Future<List<Message>> getGroupMessages(int groupId) async {
    try {
      final response = await _dio.get(
        '/api/group/messages/$groupId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (response.data as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } catch (e) {
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
      await _dio.post(
        '/api/group/send',
        data: {
          'groupChatId': groupId,
          'content': content,
          'senderId': currentUserId,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (type != null) 'type': type,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  void dispose() {
    _messageController.close();
    _hubConnection.stop();
  }
} 