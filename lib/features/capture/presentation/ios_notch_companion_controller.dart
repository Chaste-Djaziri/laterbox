import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../enrichment/domain/item_metadata.dart';

sealed class IosNotchState {
  const IosNotchState();
}

class IosNotchIdle extends IosNotchState {
  const IosNotchIdle();
}

class IosNotchClipboardPrompt extends IosNotchState {
  const IosNotchClipboardPrompt({
    required this.value,
    this.metadata,
    this.saving = false,
    this.selectedReturnAt,
  });

  final String value;
  final EnrichedMetadata? metadata;
  final bool saving;
  final DateTime? selectedReturnAt;

  IosNotchClipboardPrompt copyWith({
    String? value,
    EnrichedMetadata? metadata,
    bool? saving,
    DateTime? selectedReturnAt,
    bool clearReturnAt = false,
  }) {
    return IosNotchClipboardPrompt(
      value: value ?? this.value,
      metadata: metadata ?? this.metadata,
      saving: saving ?? this.saving,
      selectedReturnAt:
          clearReturnAt ? null : (selectedReturnAt ?? this.selectedReturnAt),
    );
  }
}

class IosNotchSavedConfirmation extends IosNotchState {
  const IosNotchSavedConfirmation({
    required this.title,
    this.subtitle,
    this.returnAt,
  });

  final String title;
  final String? subtitle;
  final DateTime? returnAt;
}

class IosNotchError extends IosNotchState {
  const IosNotchError({required this.message});

  final String message;
}

class IosNotchCompanionController extends StateNotifier<IosNotchState> {
  IosNotchCompanionController() : super(const IosNotchIdle());

  Timer? _autoDismissTimer;

  void showClipboardPrompt(String value, {EnrichedMetadata? metadata}) {
    _autoDismissTimer?.cancel();
    state = IosNotchClipboardPrompt(
      value: value,
      metadata: metadata,
    );
  }

  void updatePromptMetadata(EnrichedMetadata metadata) {
    if (state case final IosNotchClipboardPrompt prompt) {
      state = prompt.copyWith(metadata: metadata);
    }
  }

  void updatePromptReturnAt(DateTime? returnAt) {
    if (state case final IosNotchClipboardPrompt prompt) {
      state = prompt.copyWith(
        selectedReturnAt: returnAt,
        clearReturnAt: returnAt == null,
      );
    }
  }

  void setPromptSaving(bool saving) {
    if (state case final IosNotchClipboardPrompt prompt) {
      state = prompt.copyWith(saving: saving);
    }
  }

  void showSavedConfirmation({
    required String title,
    String? subtitle,
    DateTime? returnAt,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    _autoDismissTimer?.cancel();
    state = IosNotchSavedConfirmation(
      title: title,
      subtitle: subtitle,
      returnAt: returnAt,
    );
    _autoDismissTimer = Timer(duration, () {
      if (state is IosNotchSavedConfirmation) {
        dismiss();
      }
    });
  }

  void showError(
    String message, {
    Duration duration = const Duration(milliseconds: 3800),
  }) {
    _autoDismissTimer?.cancel();
    state = IosNotchError(message: message);
    _autoDismissTimer = Timer(duration, () {
      if (state is IosNotchError) {
        dismiss();
      }
    });
  }

  void dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    state = const IosNotchIdle();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }
}

final iosNotchCompanionProvider =
    StateNotifierProvider<IosNotchCompanionController, IosNotchState>((ref) {
  return IosNotchCompanionController();
});
