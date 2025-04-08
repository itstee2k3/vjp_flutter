import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../data/models/user.dart'; // Giả sử bạn sẽ dùng lại User model


class FriendshipApiService {
  final Dio _dio;
  final String? _token;

  FriendshipApiService({required Dio dio, required String? token})
      : _dio = dio,
        _token = token {
    // Cấu hình baseUrl cho Dio instance
    _dio.options.baseUrl = ApiConfig.baseUrl;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Options get _authOptions => Options(headers: {
        'Authorization': 'Bearer $_token',
      });

  // --- Các phương thức gọi API ---

  // Tìm kiếm người dùng (Ví dụ - cần điều chỉnh dựa trên API thực tế)
  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/api/friendships/search',
        queryParameters: {'query': query},
        options: _authOptions,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          return User.fromJson(json as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception('Failed to search users: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error searching users: $e');
      if (e is DioException) {
        print('DioException details: ${e.response?.data}');
      }
      throw Exception('Failed to search users: $e');
    }
  }

  // Gửi yêu cầu kết bạn
  Future<void> sendFriendRequest(String receiverId) async {
    try {
      await _dio.post(
        '/api/friendships/request',
        data: {'ReceiverId': receiverId},
        options: _authOptions,
      );
    } catch (e) {
      print('Error sending friend request: $e');
      if (e is DioException && e.response?.data != null) {
        print('Error response data: ${e.response?.data}');
      }
      throw Exception('Failed to send friend request: $e');
    }
  }

  // Lấy danh sách yêu cầu đang chờ
  Future<List<dynamic>> getPendingRequests() async {
    try {
      final response = await _dio.get(
        '/api/friendships/pending',
        options: _authOptions,
      );
      
      if (response.statusCode == 200) {
        // API trả về trực tiếp List<dynamic>, không cần truy cập key 'requests'
        if (response.data is List) {
            return response.data as List<dynamic>;
        } else {
             // Log hoặc xử lý trường hợp dữ liệu không phải là List
             print('Warning: Expected List but got ${response.data.runtimeType} from /api/friendships/pending');
             return []; // Trả về list rỗng để tránh lỗi
        }
      } else {
        throw Exception('Failed to get pending requests: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error getting pending requests: $e');
      if (e is DioException && e.response?.data != null) {
        print('Error response data: ${e.response?.data}');
      }
      throw Exception('Failed to get pending requests: $e');
    }
  }

  // Chấp nhận yêu cầu
  Future<void> acceptRequest(int requestId) async {
    try {
      await _dio.post(
        '/api/friendships/$requestId/accept',
        options: _authOptions,
      );
    } catch (e) {
      print('Error accepting friend request: $e');
      throw Exception('Failed to accept friend request: $e');
    }
  }

  // Từ chối yêu cầu
  Future<void> rejectRequest(int requestId) async {
    try {
      await _dio.post(
        '/api/friendships/$requestId/reject',
        options: _authOptions,
      );
    } catch (e) {
      print('Error rejecting friend request: $e');
      throw Exception('Failed to reject friend request: $e');
    }
  }

  // Lấy danh sách bạn bè
  Future<List<dynamic>> getFriends() async {
    try {
      final response = await _dio.get(
        '/api/friendships/friends',
        options: _authOptions,
      );
      
      if (response.statusCode == 200) {
         // API trả về trực tiếp List<dynamic>, không cần truy cập key
         if (response.data is List) {
            return response.data as List<dynamic>;
         } else {
             print('Warning: Expected List but got ${response.data.runtimeType} from /api/friendships/friends');
             return []; 
         }
      } else {
        throw Exception('Failed to get friends: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error getting friends: $e');
      if (e is DioException && e.response?.data != null) {
         print('Error response data: ${e.response?.data}');
       }
      throw Exception('Failed to get friends: $e');
    }
  }

  // Hủy kết bạn
  Future<void> unfriend(String friendId) async {
    try {
      await _dio.delete(
        '/api/friendships/$friendId',
        options: _authOptions,
      );
    } catch (e) {
      print('Error unfriending: $e');
      throw Exception('Failed to unfriend: $e');
    }
  }
}