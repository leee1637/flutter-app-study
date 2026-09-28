import 'package:flutter/material.dart';

/// Текстовое поле с подписью.
///
/// Обёртка нужна, чтобы не повторять одну и ту же разметку `TextFormField`
/// в нескольких формах, и чтобы валидация выглядела одинаково везде.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      // У скрытого поля всегда одна строка, иначе пароль превратится в textarea.
      maxLines: obscureText ? 1 : maxLines,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
