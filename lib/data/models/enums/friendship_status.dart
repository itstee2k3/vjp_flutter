enum FriendshipStatus {
  none, // Chưa có quan hệ
  pendingSent, // Đã gửi yêu cầu
  pendingReceived, // Đã nhận yêu cầu
  accepted, // Đã là bạn
  rejected, // Đã từ chối
  blocked, // Đã chặn (nếu có)
}