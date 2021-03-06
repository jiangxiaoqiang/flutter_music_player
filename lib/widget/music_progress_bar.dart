import 'package:flutter/material.dart';

class MusicProgressBar extends StatefulWidget {
  
  _MusicProgressBarState _state;
  Function onChanged;
  Function onChangeStart;
  Function onChangeEnd;

  MusicProgressBar({Key key, this.onChanged, this.onChangeStart, this.onChangeEnd}): super(key: key);

  _MusicProgressBarState createState(){
    _state = _MusicProgressBarState();
    return _state;
  }

  void setDuration(int duration){
    _state?.setDuration(duration);
  }

  void updatePosition(int position){
    _state?.setPosition(position);
  }


}

class _MusicProgressBarState extends State<MusicProgressBar> {
  int duration = 0;
  int position = 0;
  bool isTaping = false; // 是否在手动拖动（拖动的时候进度条不要自己动

  void setDuration(int duration){
    setState(() {
     this.duration = duration; 
    });
  }

  void setPosition(int position, {bool byHander:false}){
    if (isTaping && !byHander) {
      return;
    }
    setState(() {
     this.position = position; 
    });
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(_getFormatTime(position),
            style: TextStyle(color: Colors.white, fontSize: 12)),
        Expanded(
          child: SliderTheme(
            data: theme.sliderTheme.copyWith(
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 18.0),
            ),
            child: Slider.adaptive(
              value: position.toDouble(),
              min: 0.0,
              max: duration == 0 ? 1.0 : duration.toDouble(),
              onChanged: (double value) {
                setPosition(value.toInt(), byHander: true);
                widget.onChanged(value);
              },
              onChangeStart: (double value) {
                isTaping = true;
                widget.onChangeStart(value);
              },
              onChangeEnd: (double value) {
                isTaping = false;
                widget.onChangeEnd(value);
              },
            ),
          )
        ),
        Text(
          _getFormatTime(duration),
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  String _getFormatTime(int seconds) {
    int minute = seconds ~/ 60;
    int hour = minute ~/ 60;
    String strHour = hour == 0 ? '' : '$hour:';
    return "$strHour${_getTimeString(minute % 60)}:${_getTimeString(seconds % 60)}";
  }

  String _getTimeString(int value) {
    return value > 9 ? "$value" : "0$value";
  }
}
