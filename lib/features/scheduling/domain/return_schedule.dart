enum ReturnPreset { now, laterToday, tomorrow, weekend, someday }

DateTime? resolveReturnPreset(ReturnPreset preset, DateTime now) {
  final local = now.toLocal();
  return switch (preset) {
    ReturnPreset.now => now.toUtc(),
    ReturnPreset.laterToday => now.add(const Duration(hours: 3)).toUtc(),
    ReturnPreset.tomorrow => DateTime(local.year, local.month, local.day + 1, 9).toUtc(),
    ReturnPreset.weekend => DateTime(local.year, local.month,
      local.day + ((DateTime.saturday - local.weekday + 7) % 7 == 0
        ? 7 : (DateTime.saturday - local.weekday + 7) % 7), 9).toUtc(),
    ReturnPreset.someday => null,
  };
}
