import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/shared/models/tournaments_model.dart';

Future<RoomDetails?> showStartMatchDialog(BuildContext context) {
  final roomIdController = TextEditingController();
  final passwordController = TextEditingController();
  final colorScheme = Theme.of(context).colorScheme;
  final textScheme = Theme.of(context).textTheme;

  return showDialog<RoomDetails>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: colorScheme.surface,
        titleTextStyle: textScheme.titleLarge?.copyWith(color: Colors.white),
        title: Center(child: Text('Start Match')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Room details. These will be securely shared with registered players.',
              style: textScheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(120),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: roomIdController,
              style: textScheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Room ID',
                labelStyle: textScheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(120),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colorScheme.outline.withAlpha(120),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              style: textScheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: 'Room Password',
                labelStyle: textScheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(120),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colorScheme.outline.withAlpha(120),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: textScheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(200),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
            ),
            onPressed: () {
              final rId = roomIdController.text.trim();
              final pwd = passwordController.text.trim();
              if (rId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Room ID is required')),
                );
                return;
              }
              context.pop(RoomDetails(roomId: rId, password: pwd));
            },
            child: Text(
              'Start',
              style: textScheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      );
    },
  );
}
