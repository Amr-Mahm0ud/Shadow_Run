import 'package:flutter/widgets.dart';

import '../../game/runner/runner_entities.dart';

typedef RunnerGestureHandler = void Function(RunnerInput input, {double power});

/// Maps swipes / taps / holds / double-taps to runner inputs.
///
/// Double-tap → ability (or ultimate when fully charged).
class RunnerGestureLayer extends StatefulWidget {
  const RunnerGestureLayer({
    super.key,
    required this.enabled,
    required this.onGesture,
    required this.child,
    this.ultimateReady = false,
    this.abilityReady = true,
  });

  final bool enabled;
  final RunnerGestureHandler onGesture;
  final Widget child;
  final bool ultimateReady;
  final bool abilityReady;

  @override
  State<RunnerGestureLayer> createState() => _RunnerGestureLayerState();
}

class _RunnerGestureLayerState extends State<RunnerGestureLayer> {
  Offset? _start;
  DateTime? _downAt;
  bool _holdFired = false;
  DateTime? _lastTapAt;

  static const _swipeMin = 28.0;
  static const _holdMs = 280;
  static const _doubleTapMs = 280;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: widget.enabled
          ? (e) {
              _start = e.localPosition;
              _downAt = DateTime.now();
              _holdFired = false;
            }
          : null,
      onPointerMove: widget.enabled
          ? (e) {
              if (_holdFired || _start == null || _downAt == null) return;
              final held =
                  DateTime.now().difference(_downAt!).inMilliseconds >= _holdMs;
              final delta = e.localPosition - _start!;
              if (held && delta.distance < _swipeMin) {
                _holdFired = true;
                widget.onGesture(RunnerInput.ranged, power: 1);
              }
            }
          : null,
      onPointerUp: widget.enabled
          ? (e) {
              if (_holdFired || _start == null) {
                _start = null;
                return;
              }
              final delta = e.localPosition - _start!;
              _start = null;
              final ax = delta.dx.abs();
              final ay = delta.dy.abs();
              if (ax < _swipeMin && ay < _swipeMin) {
                final now = DateTime.now();
                final isDouble = _lastTapAt != null &&
                    now.difference(_lastTapAt!).inMilliseconds <= _doubleTapMs;
                _lastTapAt = now;
                if (isDouble) {
                  _lastTapAt = null;
                  if (widget.ultimateReady) {
                    widget.onGesture(RunnerInput.ultimate, power: 1);
                  } else if (widget.abilityReady) {
                    widget.onGesture(RunnerInput.ability, power: 1);
                  }
                  return;
                }
                widget.onGesture(RunnerInput.melee, power: 1);
                return;
              }
              if (ay >= ax) {
                if (delta.dy < 0) {
                  final power = (ay / 90).clamp(0.75, 1.25);
                  widget.onGesture(RunnerInput.jump, power: power);
                } else {
                  widget.onGesture(RunnerInput.slide, power: 1);
                }
              } else {
                widget.onGesture(
                  delta.dx < 0 ? RunnerInput.dodgeLeft : RunnerInput.dodgeRight,
                  power: 1,
                );
              }
            }
          : null,
      onPointerCancel: (_) {
        _start = null;
        _holdFired = false;
      },
      child: widget.child,
    );
  }
}
