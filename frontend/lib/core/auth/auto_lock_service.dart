import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/session_service.dart';

const int _defaultAutoLockMinutes = 10;

final autoLockTimeoutProvider = Provider<int>((ref) => _defaultAutoLockMinutes);

/// `true` when the session is locked by the auto-lock timer.
class AutoLockNotifier extends StateNotifier<bool> with WidgetsBindingObserver {
  AutoLockNotifier(this._ref) : super(false) {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  final Ref _ref;
  Timer? _timer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetTimer();
    }
  }

  void onUserActivity() {
    if (state) return;
    _resetTimer();
  }

  void unlock() {
    state = false;
    _resetTimer();
  }

  void _startTimer() {
    final timeoutMinutes = _ref.read(autoLockTimeoutProvider);
    final duration = Duration(minutes: timeoutMinutes);
    _timer = Timer(duration, _onTimerFired);
  }

  void _resetTimer() {
    _timer?.cancel();
    _startTimer();
  }

  void _onTimerFired() {
    final session = _ref.read(sessionProvider);
    if (!session.isAuthenticated) return;
    _ref.read(sessionProvider.notifier).lock();
    state = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final autoLockProvider = StateNotifierProvider<AutoLockNotifier, bool>((ref) {
  return AutoLockNotifier(ref);
});

class AutoLockActivityDetector extends ConsumerWidget {
  const AutoLockActivityDetector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          ref.read(autoLockProvider.notifier).onUserActivity(),
      onPointerMove: (_) =>
          ref.read(autoLockProvider.notifier).onUserActivity(),
      child: child,
    );
  }
}
