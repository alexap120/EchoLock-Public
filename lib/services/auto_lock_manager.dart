import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdleTimeoutManager extends StatefulWidget {
  final Widget child;
  final VoidCallback onTimeout;

  const IdleTimeoutManager({
    required this.child,
    required this.onTimeout,
    super.key,
  });

  @override
  State<IdleTimeoutManager> createState() => _IdleTimeoutManagerState();
}

class _IdleTimeoutManagerState extends State<IdleTimeoutManager> {
  Timer? _idleTimer;
  int _autoLockMinutes = 1;

  @override
  void initState() {
    super.initState();
    _loadAutoLockMinutes();
  }

  Future<void> _loadAutoLockMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoLockMinutes = prefs.getInt('auto_lock_minutes') ?? 1;
    });
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(Duration(minutes: _autoLockMinutes), widget.onTimeout);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}