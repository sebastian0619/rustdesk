import 'package:flutter/material.dart';
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';

/// A relative-motion touchpad for the lower half of a foldable device in
/// tabletop posture (replaces the soft keyboard when toggled).
///
/// - one finger drag: move the remote cursor
/// - tap: left click
/// - two finger drag: scroll
/// - bottom buttons: left / right button (hold the left button with one finger
///   and drag with another to drag-and-drop)
class TabletopTouchpad extends StatefulWidget {
  final FFI ffi;
  const TabletopTouchpad({Key? key, required this.ffi}) : super(key: key);

  @override
  State<TabletopTouchpad> createState() => _TabletopTouchpadState();
}

class _TabletopTouchpadState extends State<TabletopTouchpad> {
  static const double _cursorGain = 1.6;
  static const double _scrollStep = 18.0; // logical pixels per wheel notch
  double _scrollAcc = 0;
  int _maxPointers = 0;
  Offset _totalMove = Offset.zero;

  InputModel get _input => widget.ffi.inputModel;

  void _onScaleStart(ScaleStartDetails d) {
    _maxPointers = d.pointerCount;
    _totalMove = Offset.zero;
    _scrollAcc = 0;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount > _maxPointers) _maxPointers = d.pointerCount;
    _totalMove += d.focalPointDelta;
    if (d.pointerCount >= 2) {
      _scrollAcc += d.focalPointDelta.dy;
      while (_scrollAcc.abs() >= _scrollStep) {
        final up = _scrollAcc > 0;
        _input.scroll(up ? -1 : 1);
        _scrollAcc += up ? -_scrollStep : _scrollStep;
      }
    } else if (_maxPointers < 2) {
      widget.ffi.cursorModel
          .updatePan(d.focalPointDelta * _cursorGain, d.localFocalPoint, false);
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    // A short two-finger touch without much movement acts as a right click.
    if (_maxPointers == 2 && _totalMove.distance < 8) {
      _input.tap(MouseButtons.right);
    }
  }

  Widget _button(String label, MouseButtons button) {
    return Expanded(
      child: Listener(
        onPointerDown: (_) => _input.tapDown(button),
        onPointerUp: (_) => _input.tapUp(button),
        onPointerCancel: (_) => _input.tapUp(button),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _input.tap(MouseButtons.left),
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.touch_app,
                    color: Colors.white24, size: 48),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: Row(children: [
              _button('L', MouseButtons.left),
              _button('R', MouseButtons.right),
            ]),
          ),
        ],
      ),
    );
  }
}
