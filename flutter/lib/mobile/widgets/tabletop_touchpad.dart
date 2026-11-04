import 'package:flutter/material.dart';
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';

/// Handheld-grip touchpad for the lower half of a foldable device in tabletop
/// posture (replaces the soft keyboard when toggled).
///
/// Left half (left thumb): drag to move the remote cursor, tap to left click.
/// Right half (right thumb): left / right buttons and a scroll strip. Hold the
/// left button with the right thumb and drag with the left thumb to drag items.
class TabletopTouchpad extends StatelessWidget {
  final FFI ffi;
  const TabletopTouchpad({Key? key, required this.ffi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        Expanded(child: _MovePad(ffi: ffi)),
        const SizedBox(width: 8),
        Expanded(child: _ButtonsPad(ffi: ffi)),
      ]),
    );
  }
}

class _MovePad extends StatelessWidget {
  static const double _cursorGain = 1.6;
  final FFI ffi;
  const _MovePad({required this.ffi});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ffi.inputModel.tap(MouseButtons.left),
      onPanUpdate: (d) =>
          ffi.cursorModel.updatePan(d.delta * _cursorGain, d.localPosition, false),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.open_with, color: Colors.white24, size: 48),
      ),
    );
  }
}

class _ButtonsPad extends StatelessWidget {
  final FFI ffi;
  const _ButtonsPad({required this.ffi});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(children: [
          Expanded(
              flex: 3,
              child: _MouseButton(
                  label: 'L', button: MouseButtons.left, input: ffi.inputModel)),
          const SizedBox(height: 8),
          Expanded(
              flex: 2,
              child: _MouseButton(
                  label: 'R',
                  button: MouseButtons.right,
                  input: ffi.inputModel)),
        ]),
      ),
      const SizedBox(width: 8),
      SizedBox(width: 56, child: _ScrollStrip(input: ffi.inputModel)),
    ]);
  }
}

class _MouseButton extends StatefulWidget {
  final String label;
  final MouseButtons button;
  final InputModel input;
  const _MouseButton(
      {required this.label, required this.button, required this.input});

  @override
  State<_MouseButton> createState() => _MouseButtonState();
}

class _MouseButtonState extends State<_MouseButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
    if (down) {
      widget.input.tapDown(widget.button);
    } else {
      widget.input.tapUp(widget.button);
    }
  }

  @override
  void dispose() {
    // Never leave a button stuck down on the remote side.
    if (_down) widget.input.tapUp(widget.button);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Container(
        decoration: BoxDecoration(
          color: _down ? Colors.blue.withOpacity(0.7) : Colors.white12,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(widget.label,
            style: const TextStyle(color: Colors.white70, fontSize: 22)),
      ),
    );
  }
}

class _ScrollStrip extends StatefulWidget {
  final InputModel input;
  const _ScrollStrip({required this.input});

  @override
  State<_ScrollStrip> createState() => _ScrollStripState();
}

class _ScrollStripState extends State<_ScrollStrip> {
  static const double _step = 14.0; // logical pixels per wheel notch
  double _acc = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _acc = 0,
      onVerticalDragUpdate: (d) {
        _acc += d.delta.dy;
        while (_acc.abs() >= _step) {
          final down = _acc > 0;
          // Dragging down scrolls the content up, like a touchscreen.
          widget.input.scroll(down ? -1 : 1);
          _acc += down ? -_step : _step;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.unfold_more, color: Colors.white38, size: 28),
      ),
    );
  }
}
