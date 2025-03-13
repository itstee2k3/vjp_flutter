import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/custom_input_field.dart';
import '../cubits/sign_in/sign_in_cubit.dart';
import '../cubits/sign_in/sign_in_state.dart';
import '../cubits/auth_cubit.dart';

class SignInForm extends StatelessWidget {
  const SignInForm({Key? key}) : super(key: key);

  @override 
  Widget build(BuildContext context) {
    final signInCubit = context.watch<SignInCubit>();

    return BlocConsumer<SignInCubit, SignInState>(
      listener: (context, state) {
        // if (state.errorMessage.isNotEmpty) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(state.errorMessage),
        //       backgroundColor: Colors.red,
        //     ),
        //   );
        // }
      },
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(32),
          decoration: _buildContainerDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Đăng Nhập",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CustomInputField(
                label: "Email",
                onChanged: signInCubit.onEmailChanged,
                errorText: state.emailError,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: "Mật khẩu",
                onChanged: signInCubit.onPasswordChanged,
                errorText: state.passwordError,
                obscureText: true,
              ),

              if (state.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  state.errorMessage,
                  style: const TextStyle(color: Colors.red)
                ),
              ),

              const SizedBox(height: 24),

              state.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: signInCubit.signIn,
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

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}
