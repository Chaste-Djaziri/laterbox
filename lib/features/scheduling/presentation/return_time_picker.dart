import 'package:flutter/material.dart';
import '../domain/return_schedule.dart';

String returnTimeLabel(BuildContext context, DateTime? time) {
  if (time == null) return 'Someday';
  final local = time.toLocal();
  return '${MaterialLocalizations.of(context).formatMediumDate(local)} · ${TimeOfDay.fromDateTime(local).format(context)}';
}

class ReturnTimePicker extends StatelessWidget {
  const ReturnTimePicker({super.key, required this.value, required this.onChanged});
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Choose when · ${returnTimeLabel(context, value)}',
        style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 4, children: [
        for (final entry in const {
          ReturnPreset.now: 'Now', ReturnPreset.laterToday: 'Later today',
          ReturnPreset.tomorrow: 'Tomorrow', ReturnPreset.weekend: 'Weekend',
          ReturnPreset.someday: 'Someday',
        }.entries)
          ActionChip(label: Text(entry.value), onPressed: () =>
            onChanged(resolveReturnPreset(entry.key, DateTime.now()))),
        ActionChip(label: const Text('Custom…'), onPressed: () async {
          final now = DateTime.now();
          final initial = value?.toLocal();
          final date = await showDatePicker(context: context,
            initialDate: initial != null && initial.isAfter(now) ? initial : now,
            firstDate: DateTime(now.year, now.month, now.day),
            lastDate: DateTime(now.year + 100));
          if (date == null || !context.mounted) return;
          final time = await showTimePicker(context: context,
            initialTime: TimeOfDay.fromDateTime(initial ?? now.add(const Duration(hours: 1))));
          if (time == null || !context.mounted) return;
          final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (!result.isAfter(DateTime.now())) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Choose a future time, or select Now.')));
            return;
          }
          onChanged(result.toUtc());
        }),
      ]),
    ],
  );
}
