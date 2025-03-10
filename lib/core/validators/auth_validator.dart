class AuthValidator {
  // Regex pattern chung cho email validation
  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$');

  static String? validateEmail(String email) {
    final emailTrimmed = email.trim();
    
    if (emailTrimmed.isEmpty) {
      return "Email không được để trống!";
    }
    
    if (!_emailRegex.hasMatch(emailTrimmed)) {
      return "Email không hợp lệ!";
    }
    
    return null;
  }

  static String? validatePassword(String password) {
    final passwordTrimmed = password.trim();
    
    if (passwordTrimmed.isEmpty) {
      return "Mật khẩu không được để trống!";
    }
    
    if (passwordTrimmed.length < 6) {
      return "Mật khẩu phải có ít nhất 6 ký tự!";
    }
    
    // Thêm các quy tắc khác nếu cần
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$');
    if (!passwordRegex.hasMatch(passwordTrimmed)) {
      return "Mật khẩu phải chứa chữ hoa, chữ thường, số và ký tự đặc biệt!";
    }
    
    return null;
  }

  static String? validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.trim().isEmpty) {
      return "Xác nhận mật khẩu không được để trống!";
    }
    
    if (confirmPassword != password) {
      return "Mật khẩu xác nhận không khớp!";
    }
    
    return null;
  }
} 