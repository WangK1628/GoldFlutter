import 'package:flutter_riverpod/flutter_riverpod.dart';

final toastMessageProvider = StateProvider<String?>((ref) => null);

void showToast(dynamic ref, String message) {
  ref.read(toastMessageProvider.notifier).state = message;
  Future.delayed(const Duration(seconds: 2), () {
    if (ref.read(toastMessageProvider) == message) {
      ref.read(toastMessageProvider.notifier).state = null;
    }
  });
}
