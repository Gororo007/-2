import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningThreshold;
  final VoidCallback onTimeout;
  final Widget child;

  const InactivityWatcher({
    super.key,
    this.timeout = const Duration(minutes: 3),
    this.warningThreshold = const Duration(seconds: 30),
    required this.onTimeout,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _inactivityTimer;
  Timer? _warningTimer;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restartTimers();
  }

  bool _onKey(KeyEvent event) {
    _onUserActivity();
    return false;
  }

  void _onUserActivity() {
    if (_warningShown) {
      return;
    } // во время окна предупреждения таймер не сбрасывается кликами вне диалога
    _restartTimers();
  }

  void _restartTimers() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();

    final warningDuration = widget.timeout - widget.warningThreshold;
    _warningTimer = Timer(warningDuration, _showWarningDialog);
    _inactivityTimer = Timer(widget.timeout, widget.onTimeout);
  }

  void _showWarningDialog() {
    if (!mounted) return;
    _warningShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Неактивность'),
          ],
        ),
        content: const Text(
          'Сессия будет автоматически завершена через 30 секунд из-за неактивности.\nПродолжить работу в системе?',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _warningShown = false;
              _restartTimers();
            },
            child: const Text('Я здесь, продолжить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      onPointerSignal: (_) => _onUserActivity(),
      child: widget.child,
    );
  }
}
