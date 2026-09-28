import 'package:flutter/material.dart';
import 'package:warehouse_app/core/constants/app_constants.dart';

/// Цветовая метка статуса товара.
///
/// Статус приходит из базы строкой, поэтому у `switch` обязателен `default`:
/// компилятор не проверит, что все возможные значения обработаны.
class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;

    switch (status) {
      case AppConstants.statusAvailable:
        color = Colors.green;
        text = 'Свободен';
      case AppConstants.statusTaken:
        color = Colors.orange;
        text = 'Занят';
      default:
        color = Colors.grey;
        text = 'Неизвестно';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
