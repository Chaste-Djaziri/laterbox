import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_coordinator.dart';

class InboxNotificationSettings extends ConsumerWidget {
  const InboxNotificationSettings({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationCoordinatorProvider);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Device notifications'),
            subtitle: Text(
              notifications.status ??
                  'Scheduled returns and saves from other devices.',
            ),
            value: notifications.enabled,
            onChanged: notifications.busy
                ? null
                : (value) => notifications.update(enable: value),
          ),
          SwitchListTile(
            title: const Text('Scheduled returns'),
            value: notifications.returns,
            onChanged: !notifications.enabled || notifications.busy
                ? null
                : (value) => notifications.update(scheduledReturns: value),
          ),
          SwitchListTile(
            title: const Text('Saves from other devices'),
            value: notifications.saves,
            onChanged: !notifications.enabled || notifications.busy
                ? null
                : (value) => notifications.update(remoteSaves: value),
          ),
          ListTile(
            title: const Text('Send test notification'),
            trailing: const Icon(Icons.notifications_outlined),
            onTap: notifications.busy ? null : notifications.test,
          ),
        ],
      ),
    );
  }
}
