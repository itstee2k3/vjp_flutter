import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/screens/home_screen.dart';
import '../cubits/sign_in/sign_in_cubit.dart';
import '../cubits/sign_in/sign_in_event.dart';
import '../cubits/sign_in/sign_in_state.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({Key? key}) : super(key: key);

  @override
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  Widget _buildInputField({
    required String label,
    required Function(String) onChanged,
    required String errorText,
    bool obscureText = false,
  }) {
    return TextField(
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: errorText.isNotEmpty
            ? Tooltip(
          message: errorText,
          waitDuration: Duration.zero,
          showDuration: const Duration(seconds: 3),
          triggerMode: TooltipTriggerMode.tap,
          child: const Icon(Icons.error, color: Colors.red),
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signInCubit = context.read<SignInCubit>();

      return BlocConsumer<SignInCubit, SignInState>(
      listener: (context, state) {
        if (state.isSuccess) {
          // Hiển thị thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Đăng nhập thành công'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Chuyển trang sau một khoảng thời gian ngắn
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false, // Xóa tất cả các route trước đó
            );
          });
        } else if (state.errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(32),
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
                "Đăng Nhập",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Email field
              _buildInputField(
                label: "Email",
                onChanged: (email) => signInCubit.add(SignInEmailChanged(email)),
                errorText: state.emailError,
              ),
              const SizedBox(height: 10),
              // Password field
              _buildInputField(
                label: "Mật khẩu",
                onChanged: (password) => signInCubit.add(SignInPasswordChanged(password)),
                errorText: state.passwordError,
                obscureText: true,
              ),

              // Hiển thị thông báo lỗi
              if (state.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                      state.errorMessage,
                      style: TextStyle(color: Colors.red)
                  ),
                ),

              const SizedBox(height: 20),
              // Submit button
              state.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () {
                  signInCubit.add(SignInSubmitted());
                },
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
                    "GO!",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
