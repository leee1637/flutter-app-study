import 'package:flutter/material.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';

class RoleSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const RoleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      items: const [
        DropdownMenuItem(
          value: AppConstants.adminRole,
          child: Text(AppConstants.adminRole),
        ),
        DropdownMenuItem(
          value: AppConstants.userRole,
          child: Text(AppConstants.userRole),
        ),
      ],
      decoration: const InputDecoration(
        labelText: 'Роль',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Выберите роль';
        }
        return null;
      },
    );
  }
}