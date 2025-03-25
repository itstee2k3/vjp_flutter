import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final Function(String) onChanged;
  final String errorText;
  final bool obscureText;
  
  const CustomInputField({
    Key? key,
    required this.label,
    required this.onChanged,
    required this.errorText,
    this.obscureText = false, required FocusNode focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
} 