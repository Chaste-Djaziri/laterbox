import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/laterbox_item.dart';
import '../../library/presentation/library_providers.dart';

final scheduleNowProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// A clock that wakes at a return deadline, local midnight, and app resume.
final scheduleClockProvider = StreamProvider<DateTime>((ref) {
  final items =
      ref.watch(allItemsProvider).valueOrNull ?? const <LaterBoxItem>[];
  final readNow = ref.watch(scheduleNowProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  void tick() {
    final now = readNow();
    controller.add(now);
    final local = now.toLocal();
    var next = DateTime(local.year, local.month, local.day + 1);
    for (final item in items) {
      final time = item.returnAt;
      if (item.isActive &&
          time != null &&
          time.isAfter(now) &&
          time.isBefore(next)) {
        next = time;
      }
    }
    timer?.cancel();
    timer = Timer(next.difference(now), tick);
  }

  final observer = _ResumeObserver(tick);
  WidgetsBinding.instance.addObserver(observer);
  tick();
  ref.onDispose(() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(observer);
    controller.close();
  });
  return controller.stream;
});

class _ResumeObserver extends WidgetsBindingObserver {
  _ResumeObserver(this.tick);
  final VoidCallback tick;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) tick();
  }
}

enum ScheduleView { today, upcoming, someday }

List<LaterBoxItem> scheduleItems(
  List<LaterBoxItem> items,
  ScheduleView view,
  DateTime now,
) {
  final localNow = now.toLocal();
  final result = items.where((item) {
    if (!item.isActive) return false;
    final time = item.returnAt;
    if (view == ScheduleView.someday) return time == null && !item.isDue(now);
    if (time == null) return false;
    if (view == ScheduleView.upcoming) return time.isAfter(now);
    final local = time.toLocal();
    return local.year == localNow.year &&
        local.month == localNow.month &&
        local.day == localNow.day;
  }).toList();
  result.sort(
    (a, b) => view == ScheduleView.someday
        ? b.createdAt.compareTo(a.createdAt)
        : a.returnAt!.compareTo(b.returnAt!),
  );
  return result;
}

final scheduledItemsProvider =
    Provider.family<AsyncValue<List<LaterBoxItem>>, ScheduleView>((ref, view) {
      final now =
          ref.watch(scheduleClockProvider).valueOrNull ??
          ref.watch(scheduleNowProvider)();
      return ref
          .watch(allItemsProvider)
          .whenData((items) => scheduleItems(items, view, now));
    });
