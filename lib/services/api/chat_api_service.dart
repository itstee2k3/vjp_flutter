import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_socket_io/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:signalr_netcore/signalr_client.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ChatApiService {
  late final Dio dio;

  String? _token;
  String? get token => _token;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  final String baseUrl = ApiConfig.baseUrl;
  late final HubConnection hubConnection;

  static const String userEndpoint = "/api/user";
  static const String chatSendEndpoint = "/api/chat/send";
  static const String chatHistoryEndpoint = "/api/chat/history";
  static const String chatMarkReadEndpoint = "/api/chat/mark-as-read";

  final _messageController = StreamController<Message>.broadcast();
  Stream<Message> get messageStream => _messageController.stream;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Thêm Set để theo dõi tin nhắn đã xử lý
  final Set<String> _processedMessageIds = {};

  // Thêm StreamController để theo dõi trạng thái đang nhập
  final _typingStatusController = StreamController<Map<String, bool>>.broadcast();
  Stream<Map<String, bool>> get typingStatus => _typingStatusController.stream;

  ChatApiService({
    String? token,
    String? currentUserId,
  }) : _token = token,
       _currentUserId = currentUserId {
    print('ChatApiService initialized with token: ${token?.substring(0, 20)}...');
    print('ChatApiService initialized with userId: $currentUserId');

    // Khởi tạo Dio với baseUrl
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    ));

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
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final messageData = arguments[0] as Map<String, dynamic>;
          
          // Kiểm tra dữ liệu tin nhắn cơ bản
          if (!messageData.containsKey('senderId') && !messageData.containsKey('SenderId')) {
            print('Invalid message data: missing senderId');
            return;
          }
          
          if (!messageData.containsKey('receiverId') && !messageData.containsKey('ReceiverId')) {
            print('Invalid message data: missing receiverId');
            return;
          }
          
          // Log thời gian từ server
          if (messageData.containsKey('sentAt')) {
            print('Server sentAt: ${messageData['sentAt']}');
          } else if (messageData.containsKey('SentAt')) {
            print('Server SentAt: ${messageData['SentAt']}');
          }
          
          try {
            final message = Message.fromJson(messageData);
            
            // Log thời gian sau khi parse
            print('Parsed sentAt: ${message.sentAt}, local time: ${message.sentAt.toLocal()}, UTC time: ${message.sentAt.toUtc()}');
            
            // Tạo ID duy nhất cho tin nhắn để tránh trùng lặp
            final messageKey = '${message.id}-${message.senderId}-${message.receiverId}';
            
            // Kiểm tra xem tin nhắn đã được xử lý chưa
            if (_processedMessageIds.contains(messageKey)) {
              print('Duplicate message detected, ignoring: $messageKey');
              return;
            }
            
            // Đánh dấu tin nhắn đã được xử lý
            _processedMessageIds.add(messageKey);
            
            // Giới hạn kích thước của Set để tránh tràn bộ nhớ
            if (_processedMessageIds.length > 1000) {
              _processedMessageIds.remove(_processedMessageIds.first);
            }
            
            // Thêm tin nhắn vào stream
            _messageController.add(message);
          } catch (e) {
            print('Error creating Message object: $e');
            print('Message data: $messageData');
          }
        } catch (e) {
          print('Error handling SignalR message: $e');
          print('Error details: ${e.toString()}');
        }
      }
    });

    hubConnection.onreconnecting(({Exception? error}) {
      print('SignalR reconnecting: $error');
      _connectionStatusController.add(false);
    });

    hubConnection.onreconnected(({String? connectionId}) {
      print('SignalR reconnected with ID: $connectionId');
      _connectionStatusController.add(true);
      
      // Khi kết nối lại, tham gia lại phòng
      if (currentUserId != null) {
        hubConnection.invoke('JoinRoom', args: [currentUserId!])
          .then((_) => print('Rejoined room after reconnection'))
          .catchError((e) => print('Error rejoining room: $e'));
      }
    });

    hubConnection.onclose(({Exception? error}) {
      print('SignalR connection closed: $error');
      _connectionStatusController.add(false);
    });

    hubConnection.on('ReceiveTypingStatus', (arguments) {
      if (arguments != null && arguments.length >= 2) {
        try {
          final senderId = arguments[0] as String;
          final isTyping = arguments[1] as bool;
          
          _typingStatusController.add({senderId: isTyping});
        } catch (e) {
          print('Error handling typing status: $e');
        }
      }
    });

    hubConnection.on("ReceiveMessage", _handleSignalRMessage);
  }

  void _handleSignalRMessage(List<Object?>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    
    try {
      final messageData = parameters[0];
      print('Received SignalR message: $messageData');
      
      if (messageData is Map) {
        // Xử lý Map trực tiếp
        final message = Message.fromJson(Map<String, dynamic>.from(messageData));
        _messageController.add(message);
      } else {
        // Chuyển đổi từ JSON string
        final messageMap = jsonDecode(messageData.toString());
        final message = Message.fromJson(messageMap);
        _messageController.add(message);
      }
      
      // Thông báo cho UI cập nhật
      _connectionStatusController.add(true);
    } catch (e) {
      print('Error handling SignalR message: $e');
    }
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
      
      // Thêm cơ chế retry với backoff
      int retryCount = 0;
      const maxRetries = 5;
      
      while (retryCount < maxRetries) {
        try {
          await hubConnection.start();
          print('SignalR connected with state: ${hubConnection.state}');
          
          if (currentUserId != null) {
            print('Joining room for user: $currentUserId');
            await hubConnection.invoke('JoinRoom', args: [currentUserId!]);
            print('Joined room successfully');
          }
          
          // Kết nối thành công, thoát khỏi vòng lặp
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            print('Failed to connect to SignalR after $maxRetries attempts');
            rethrow;
          }
          
          // Tăng thời gian chờ theo cấp số nhân
          final delay = Duration(milliseconds: 1000 * (1 << retryCount));
          print('Retrying connection in ${delay.inSeconds} seconds (attempt $retryCount/$maxRetries)');
          await Future.delayed(delay);
        }
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

  Future<User> getUserById(String userId) async {
    try {
      if (_token == null || _token!.isEmpty) {
        throw Exception('No valid authentication token');
      }
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      final response = await http.get(
        Uri.parse("$baseUrl$userEndpoint/$userId"), // Use the specific user ID endpoint
        headers: _headers,
      );

      print('GetUserById Response Status: ${response.statusCode}');
      print('GetUserById Response Body: ${response.body}');


      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(response.body);
        // Assuming the API returns the user object directly
        return User.fromJson(userData);
      } else if (response.statusCode == 404) {
          throw Exception('User not found: $userId');
      }
      else {
        throw Exception('Failed to load user $userId: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error getting user by ID $userId: $e');
      throw Exception('Error getting user details: $e');
    }
  }

  Future<Map<String, dynamic>> getChatHistory(String userId, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl$chatHistoryEndpoint/$userId?page=$page&pageSize=$pageSize"),
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
          throw Exception('Invalid API response format for chat history');
        }
      } else {
        throw Exception('Failed to load chat history: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error getting chat history: $e'); // Log the error
      throw Exception('Error getting chat history: $e');
    }
  }

  Future<bool> ensureConnected() async {
    if (hubConnection.state != HubConnectionState.Connected) {
      try {
        // Đóng kết nối hiện tại nếu đang trong trạng thái lỗi
        if (hubConnection.state == HubConnectionState.Disconnected ||
            hubConnection.state == HubConnectionState.Disconnecting ||
            hubConnection.state == HubConnectionState.Reconnecting) {
          try {
            await hubConnection.stop();
          } catch (e) {
            // Bỏ qua lỗi khi dừng kết nối
          }
        }
        
        // Tạo kết nối mới
        await connect();
        
        // Kiểm tra lại trạng thái kết nối
        return hubConnection.state == HubConnectionState.Connected;
      } catch (e) {
        print('Error reconnecting to SignalR: $e');
        return false;
      }
    }
    return true;
  }

  Future<Message> sendMessage(String receiverId, String content) async {
    try {
      // Kiểm tra xem receiverId có hợp lệ không
      if (receiverId.isEmpty) {
        throw Exception('ReceiverId is empty');
      }
      
      // In ra để debug
      print('Sending message to: $receiverId, content: $content');
      
      // Tạo body request với định dạng chính xác
      final requestBody = jsonEncode({
        'receiverId': receiverId,  // Đảm bảo tên trường đúng
        'content': content,
        'isRead': false
      });
      
      // In ra body request để debug
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$chatSendEndpoint'),
        headers: _headers,
        body: requestBody,
      );
      
      // Kiểm tra response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('Message sent via REST API');
        
        // Cập nhật ID tin nhắn từ server nếu có
        try {
          final responseData = jsonDecode(response.body);
          if (responseData.containsKey('id')) {
            final serverMessageId = responseData['id'];
            // Cập nhật ID tin nhắn local với ID từ server
            _messageController.add(Message(
              id: serverMessageId,
              senderId: currentUserId!,
              receiverId: receiverId,
              content: content,
              sentAt: DateTime.now(),
              isRead: false,
            ));
          }
        } catch (e) {
          print('Error parsing response: $e');
        }
      } else {
        print('REST API error: ${response.statusCode} - ${response.body}');
        
        // Nếu REST API thất bại, thử gửi qua SignalR
        if (hubConnection.state == HubConnectionState.Connected) {
          final signalRMessageData = {
            "senderId": currentUserId,
            "receiverId": receiverId,
            "content": content,
            "isRead": false,
            "id": DateTime.now().millisecondsSinceEpoch,
            "sentAt": DateTime.now().toUtc().toIso8601String(), // Gửi thời gian UTC
          };
          
          try {
            await hubConnection.invoke('SendMessage', args: [signalRMessageData]);
            print('Message sent via SignalR as fallback');
          } catch (e) {
            print('Error sending message via SignalR: $e');
            // Không throw exception ở đây, vì tin nhắn đã được hiển thị
            // Thay vào đó, đánh dấu tin nhắn là "đang chờ"
            _messageController.add(Message(
              id: DateTime.now().millisecondsSinceEpoch,
              senderId: currentUserId!,
              receiverId: receiverId,
              content: "$content (Đang gửi...)",
              sentAt: DateTime.now(),
              isRead: false,
            ));
          }
        } else {
          // Đánh dấu tin nhắn là "đang chờ"
          _messageController.add(Message(
            id: DateTime.now().millisecondsSinceEpoch,
            senderId: currentUserId!,
            receiverId: receiverId,
            content: "$content (Đang chờ kết nối...)",
            sentAt: DateTime.now(),
            isRead: false,
          ));
        }
      }
      
      return Message(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: currentUserId!,
        receiverId: receiverId,
        content: content,
        sentAt: DateTime.now(),
        isRead: false,
      );
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  // Thêm phương thức để gửi trạng thái đang nhập
  Future<void> sendTypingStatus(String receiverId, bool isTyping) async {
    if (currentUserId == null || hubConnection.state != HubConnectionState.Connected) {
      return;
    }
    
    try {
      await hubConnection.invoke('SendTypingStatus', args: [currentUserId!, receiverId, isTyping]);
    } catch (e) {
      print('Error sending typing status: $e');
    }
  }

  void dispose() {
    _messageController.close();
    disconnect();
  }

  Map<String, String> get _headers {
    // In ra headers để debug
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
    // print('Request headers: $headers');
    return headers;
  }

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

  // Thêm phương thức để gửi hình ảnh
  Future<Message> sendImageMessage(String receiverId, File imageFile) async {
    try {
      if (currentUserId == null) {
        throw Exception('CurrentUserId is not set');
      }

      // Đảm bảo receiverId không rỗng
      if (receiverId.isEmpty) {
        throw Exception('ReceiverId is empty');
      }
      
      // Kiểm tra file có tồn tại không
      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }
      
      // Kiểm tra kích thước file
      final fileSize = await imageFile.length();
      final maxSize = 10 * 1024 * 1024; // 10MB

      if (fileSize > maxSize) {
        throw Exception('Hình ảnh quá lớn (tối đa 10MB)');
      }
      
      // Nén hình ảnh nếu lớn hơn 1MB
      if (fileSize > 1024 * 1024) {
        final compressedFile = await _compressImage(imageFile);
        imageFile = compressedFile;
      }
      
      print('Sending image: ${imageFile.path}, size: ${await imageFile.length()} bytes');

      // Tạo ID tin nhắn duy nhất để theo dõi
      final localMessageId = DateTime.now().millisecondsSinceEpoch;
      final now = DateTime.now();
      
      // Tạo form data để upload file
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload/image'),
      );
      
      // Thêm headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Thêm file vào request
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      request.files.add(await http.MultipartFile.fromPath(
        'File',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ));
      
      // Thêm các trường khác
      request.fields['ReceiverId'] = receiverId;
      request.fields['Caption'] = '[Hình ảnh]';
      
      // Hiển thị tin nhắn tạm thời trong UI
      final tempMessage = Message(
        id: localMessageId,
        senderId: currentUserId!,
        receiverId: receiverId,
        content: '[Đang gửi hình ảnh...]',
        sentAt: now,
        isRead: false,
        type: MessageType.image,
        imageUrl: null, // Chưa có URL
      );
      
      // Thêm tin nhắn tạm thời vào stream
      _messageController.add(tempMessage);
      
      // Gửi request
      print('Sending image upload request to: $baseUrl/api/upload/image');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Tạo tin nhắn mới với URL hình ảnh từ server
        final updatedMessage = Message(
          id: responseData['id'] ?? localMessageId,
          senderId: currentUserId!,
          receiverId: receiverId,
          content: '[Hình ảnh]',
          sentAt: now,
          isRead: false,
          type: MessageType.image,
          imageUrl: responseData['imageUrl'],
        );
        
        // Cập nhật tin nhắn trong stream
        _messageController.add(updatedMessage);
        
        print('Image message added to stream: ${updatedMessage.id}, URL: ${updatedMessage.imageUrl}');
        
        return updatedMessage;
      } else {
        print('Failed to send image: ${response.statusCode} - ${response.body}');
        
        // Phân tích lỗi từ server
        String errorText = 'Lỗi gửi hình ảnh';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorText = errorData['message'];
          } else if (response.body.contains('Internal server error')) {
            errorText = 'Lỗi máy chủ: ${response.body}';
          }
        } catch (e) {
          // Nếu không phân tích được JSON, sử dụng thông báo mặc định
        }
        
        // Giới hạn độ dài của thông báo lỗi
        if (errorText.length > 30) {
          errorText = '${errorText.substring(0, 30)}...';
        }
        
        // Cập nhật tin nhắn tạm thời thành tin nhắn lỗi
        final errorMessage = Message(
          id: localMessageId,
          senderId: currentUserId!,
          receiverId: receiverId,
          content: '[Lỗi: $errorText]',
          sentAt: now,
          isRead: false,
          type: MessageType.text,
          imageUrl: null,
        );
        
        // Thêm tin nhắn lỗi vào stream
        _messageController.add(errorMessage);
        
        throw Exception('Failed to send image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending image: $e');
      throw e;
    }
  }

  Future<File> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final pathToSave = tempDir.path;
    final fileName = path.basename(file.path);
    final targetPath = '$pathToSave/$fileName';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 30,
      minWidth: 400,
      minHeight: 400,
    );
    
    if (result == null) {
      throw Exception('Không thể nén hình ảnh');
    }
    
    return File(result.path);
  }

  // Lấy tin nhắn mới nhất giữa người dùng hiện tại và từng người dùng khác
  Future<Map<String, Message?>> getLatestMessagesForAllUsers(List<User> users) async {
    print('Getting latest messages for users: ${users.length}');
    
    Map<String, Message?> results = {};
    
    try {
      for (var user in users) {
        try {
          final chatHistory = await getChatHistory(user.id, page: 1, pageSize: 1); // Chỉ lấy 1 tin nhắn mới nhất
          if (chatHistory['messages'] is List && chatHistory['messages'].isNotEmpty) {
            results[user.id] = chatHistory['messages'].first;
          } else {
            results[user.id] = null;
          }
        } catch (e) {
          print('Error getting latest message for user ${user.id}: $e');
          results[user.id] = null;
        }
      }
      
      return results;
    } catch (e) {
      print('Error in getLatestMessagesForAllUsers: $e');
      return {};
    }
  }

  // Lấy tin nhắn mới nhất từ một người dùng cụ thể
  Future<Message?> getLatestMessage(String userId) async {
    try {
      final historyResponse = await getChatHistory(userId, page: 1, pageSize: 1);
      final messages = historyResponse['messages'] as List<Message>;
       if (messages.isNotEmpty) {
         // API trả về DESC, nhưng ta đã sort ASC trong getChatHistory, nên lấy last
         return messages.last; 
       }
      return null;
    } catch (e) {
      print('Error getting latest message: $e');
      return null;
    }
  }
}