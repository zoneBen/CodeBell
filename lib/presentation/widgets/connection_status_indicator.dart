import 'package:flutter/material.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusIndicator({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isConnected ? 'Connected' : 'Disconnected',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
