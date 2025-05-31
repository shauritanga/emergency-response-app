import 'package:flutter/material.dart';

class TextInputField extends StatelessWidget {
  const TextInputField({
    required this.controller,
    super.key,
    this.validator,
    this.labelText,
    this.hintText,
    this.keyboardType,
    this.obscureText,
    this.maxLines,
    this.maxLength,
    this.textInputAction,
    this.textCapitalization,
    this.style,
  });
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool? obscureText;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextCapitalization? textCapitalization;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
      ),
      style: const TextStyle(fontSize: 16.0),
      cursorColor: Colors.blue,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText ?? false,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
    );
  }
}
