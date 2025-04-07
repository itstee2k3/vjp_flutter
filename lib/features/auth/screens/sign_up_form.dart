import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/sign_up/sign_up_cubit.dart';
import '../cubits/sign_up/sign_up_state.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {

  Widget _buildInputField({
    required String label,
    required Function(String) onChanged,
    required String errorText,
    bool obscureText = false,
  }) {
    return TextField(
      onChanged: (value) {
        // Gọi hàm onChanged và trigger validation ngay lập tức
        onChanged(value);
      },
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        // Thêm suffix icon để hiển thị lỗi
        suffixIcon: errorText.isNotEmpty
            ? Tooltip(
          message: errorText,
          // Cấu hình tooltip xuất hiện khi tap
          waitDuration: Duration.zero,
          showDuration: Duration(seconds: 3),
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.error,
            color: Colors.red,
            // Thêm tooltip để hiển thị lỗi khi tap
            semanticLabel: errorText,
          ),
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signUpCubit = context.read<SignUpCubit>();

    return BlocBuilder<SignUpCubit, SignUpState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13), // Reduce vertical padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Đăng Ký",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Full Name field
              _buildInputField(
                label: "Họ và tên",
                onChanged: (fullName) => signUpCubit.onFullNameChanged(fullName),
                errorText: state.fullNameError,
              ),
              const SizedBox(height: 10),
              // Email field
              _buildInputField(
                label: "Email",
                onChanged: (email) => signUpCubit.onEmailChanged(email),
                errorText: state.emailError,
              ),
              const SizedBox(height: 10),
              // Password field
              _buildInputField(
                label: "Mật khẩu",
                onChanged: (password) => signUpCubit.onPasswordChanged(password),
                errorText: state.passwordError,

                obscureText: true,
              ),
              const SizedBox(height: 10),
              // Confirm Password field
              _buildInputField(
                label: "Xác nhận mật khẩu",
                onChanged: (confirmPassword) => signUpCubit.onConfirmPasswordChanged(confirmPassword),
                errorText: state.confirmPasswordError,
                obscureText: true,
              ),
              // Display success or error message here
              if (state.message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    state.message, // Show success message
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ),
              if (state.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    state.errorMessage, // Show error message
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              const SizedBox(height: 20),
              // Submit button
              state.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () => signUpCubit.signUp(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "TẠO TÀI KHOẢN",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}