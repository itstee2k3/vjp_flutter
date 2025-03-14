import 'dart:async';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import 'package:logging/logging.dart' as logging;

class ChatApiService {
  String? _token;
  String? get token => _token;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  final String baseUrl = 'http://localhost:5294';
  late final HubConnection hubConnection;

  static const String userEndpoint = "/api/user";
  static const String chatSendEndpoint = "/api/chat/send";
  static const String chatHistoryEndpoint = "/api/chat/history";
  static const String chatMarkReadEndpoint = "/api/chat/mark-as-read";

  final _messageController = StreamController<Message>.broadcast();
  Stream<Message> get messageStream => _messageController.stream;

  ChatApiService({
    String? token,
    String? currentUserId,
  }) : _token = token,
       _currentUserId = currentUserId {
    print('ChatApiService initialized with token: ${token?.substring(0, 20)}...');
    print('ChatApiService initialized with userId: $currentUserId');

    if (token != null && _currentUserId == null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));
          _currentUserId = payloadMap['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ?? 
                          payloadMap['sub'];
          print('Extracted currentUserId from token: $_currentUserId');
        }
      } catch (e) {
        print('Error decoding token: $e');
      }
    }

    // Cấu hình SignalR
    final serverUrl = '$baseUrl/chatHub';
    print('Initializing SignalR with URL: $serverUrl');
    
    hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async => token ?? "",
          logger: logging.Logger("SignalR"),
          skipNegotiation: false,
          transport: HttpTransportType.WebSockets,
          logMessageContent: false,
        ))
        .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000])
        .build();

    _initializeHubListeners();
  }

  void _initializeHubListeners() {
    hubConnection.off('ReceiveMessage');
    
    hubConnection.on('ReceiveMessage', (arguments) {
      print('=== SignalR Message Debug ===');
      print('Raw message: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final messageData = arguments[0] as Map<String, dynamic>;
          if (messageData.containsKey('sentAt')) {
            final sentAtStr = messageData['sentAt'];
            print('Original sentAt: $sentAtStr');

            // Giữ nguyên thời gian gốc từ server
            messageData['sentAt'] = sentAtStr;
          }

          final message = Message.fromJson(messageData);
          print('Final message time: ${message.sentAt}');
          print('========================');

          _messageController.add(message);
        } catch (e) {
          print('Error handling SignalR message: $e');
        }
      }
    });

    hubConnection.onclose(({Exception? error}) => 
      print('SignalR connection closed: $error')
    );
  }

  Future<void> connect() async {
    // Kiểm tra trạng thái hiện tại
    if (hubConnection.state == HubConnectionState.Connected) {
      print('SignalR already connected');
      return;
    }

    // Nếu đang trong trạng thái kết nối hoặc reconnecting, đợi cho đến khi hoàn tất
    if (hubConnection.state == HubConnectionState.Connecting || 
        hubConnection.state == HubConnectionState.Reconnecting) {
      print('SignalR is already trying to connect...');
      return;
    }

    // Nếu đang trong trạng thái ngắt kết nối, đợi cho đến khi hoàn tất
    if (hubConnection.state == HubConnectionState.Disconnecting) {
      print('Waiting for disconnection to complete...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      print('Connecting to SignalR...');
      await hubConnection.start();
      print('SignalR connected with state: ${hubConnection.state}');
      
      if (currentUserId != null) {
        print('Joining room for user: $currentUserId');
        await hubConnection.invoke('JoinRoom', args: [currentUserId!]);
        print('Joined room successfully');
      }
    } catch (e) {
      print('Error connecting to SignalR: $e');
      // Nếu có lỗi, đảm bảo dừng kết nối hiện tại
      try {
        await hubConnection.stop();
      } catch (stopError) {
        print('Error stopping connection: $stopError');
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (hubConnection.state != HubConnectionState.Disconnected) {
      try {
        await hubConnection.stop();
        print('SignalR disconnected');
      } catch (e) {
        print('Error disconnecting from SignalR: $e');
      }
    }
  }

  Future<List<User>> getUsers() async {
    try {
      if (_token == null || _token!.isEmpty) {
        throw Exception('No valid authentication token');
      }

      final response = await http.get(
        Uri.parse("$baseUrl$userEndpoint"),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('users') && responseData['users'] is List) {
          final List<dynamic> usersData = responseData['users'];
          final users = usersData.map((json) => User.fromJson(json)).toList();
          return users;
        } else {
          throw Exception('API did not return a valid user list');
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      print('Error getting users: $e');
      throw Exception('Error getting users: $e');
    }
  }

  Future<List<Message>> getChatHistory(String userId, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl$chatHistoryEndpoint/$userId?page=$page&pageSize=$pageSize"),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chat history');
      }
    } catch (e) {
      throw Exception('Error getting chat history: $e');
    }
  }

  Future<bool> ensureConnected() async {
    if (hubConnection.state != HubConnectionState.Connected) {
      print('SignalR not connected, reconnecting...');
      try {
        // Đóng kết nối hiện tại nếu đang trong trạng thái lỗi
        if (hubConnection.state == HubConnectionState.Disconnected ||
            hubConnection.state == HubConnectionState.Disconnecting ||
            hubConnection.state == HubConnectionState.Reconnecting) {
          try {
            await hubConnection.stop();
            print('Stopped existing connection');
          } catch (e) {
            print('Error stopping connection: $e');
          }
        }
        
        // Tạo kết nối mới
        await connect();
        
        // Kiểm tra lại trạng thái kết nối
        if (hubConnection.state == HubConnectionState.Connected) {
          print('Successfully reconnected to SignalR');
          return true;
        } else {
          print('Failed to reconnect to SignalR, state: ${hubConnection.state}');
          return false;
        }
      } catch (e) {
        print('Error reconnecting to SignalR: $e');
        return false;
      }
    }
    return true;
  }

  Future<void> sendMessage(String receiverId, String content) async {
    try {
      if (currentUserId == null) {
        throw Exception('CurrentUserId is not set');
      }

      final messageData = {
        "senderId": currentUserId,
        "receiverId": receiverId,
        "content": content,
        "isRead": false,
      };

      // Đảm bảo kết nối trước khi gửi tin nhắn
      if (hubConnection.state != HubConnectionState.Connected) {
        await connect();
      }

      // Gửi tin nhắn qua SignalR
      await hubConnection.invoke('SendMessage', args: [messageData]);

      // Gửi tin nhắn qua API REST
      final response = await http.post(
        Uri.parse("$baseUrl$chatSendEndpoint"),
        headers: _headers,
        body: jsonEncode(messageData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  void dispose() {
    _messageController.close();
    disconnect();
  }

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  void updateToken(String newToken) {
    _token = newToken;
    
    // Cập nhật currentUserId từ token mới
    try {
      final parts = newToken.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));
        _currentUserId = payloadMap['sub'];
      }
    } catch (e) {
      print('Error updating token: $e');
    }

    // Reconnect SignalR với token mới
    if (hubConnection.state == HubConnectionState.Connected) {
      hubConnection.stop().then((_) => connect());
    }
  }
}