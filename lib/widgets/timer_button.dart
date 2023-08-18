library timer_button;

import 'dart:async';
import 'package:flutter/material.dart';

const int aSec = 1;
const String secPostFix = 's';
const String labelSplitter = " |  ";

class TimerButton extends StatefulWidget {
  final String label;
  final int timeOutInSeconds;
  final VoidCallback onPressed;
  final Color color;
  final Color disabledColor;
  final TextStyle activeTextStyle;
  final TextStyle disabledTextStyle;
  final bool resetTimerOnPressed;

  const TimerButton({
    Key key,
    @required this.label,
    @required this.onPressed,
    @required this.timeOutInSeconds,
    this.color = Colors.blue,
    this.resetTimerOnPressed = true,
    this.disabledColor,
    this.activeTextStyle = const TextStyle(color: Colors.white),
    this.disabledTextStyle = const TextStyle(color: Colors.black45),
  })  : assert(label != null),
        assert(activeTextStyle != null),
        assert(disabledTextStyle != null),
        super(key: key);

  @override
  _TimerButtonState createState() => _TimerButtonState();
}

class _TimerButtonState extends State<TimerButton> {
  bool timeUpFlag = false;
  int timeCounter = 0;

  String get _timerText => '$timeCounter$secPostFix';

  @override
  void initState() {
    super.initState();
    timeCounter = widget.timeOutInSeconds;
    _timerUpdate();
  }

  _timerUpdate() {
    Timer(const Duration(seconds: aSec), () async {
      setState(() {
        timeCounter--;
      });
      if (timeCounter != 0) {
        _timerUpdate();
      } else {
        timeUpFlag = true;
      }
    });
  }

  Widget _buildChild() {
    return Container(
      child: timeUpFlag
          ? Text(
              widget.label,
              style: widget.activeTextStyle,
            )
          : Text(
              widget.label + labelSplitter + _timerText,
              style: widget.disabledTextStyle,
            ),
    );
  }

  _onPressed() {
    if (timeUpFlag) {
      if (widget.onPressed != null) {
        widget.onPressed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _onPressed,
      child: _buildChild(),
    );
  }
}
