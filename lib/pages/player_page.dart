import 'dart:async';
import 'dart:ui';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_player/model/song_util.dart';

class PlayerPage extends StatefulWidget {
  final Map song;
  PlayerPage({Key key, @required this.song}) : super(key: key);

  _PlayerPageState createState() => _PlayerPageState();
}

enum PlayerState { stopped, playing, paused }

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  AnimationController _animController;
  AudioPlayer audioPlayer;
  String url;
  int duration = 0;
  int position = 0;
  bool isMuted = false;
  PlayerState playerState = PlayerState.stopped;
  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  bool isTaping = false;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(duration: const Duration(seconds: 16), vsync: this);
    _animController.addStatusListener((status) {
      print("RotationTransition: $status");
      if (status == AnimationStatus.completed) {
        //动画执行结束时反向执行动画
        //_animController.reset();
        //_animController.forward();
      }
    });

    initAudioPlayer();

    url =
        "https://music.163.com/song/media/outer/url?id=${widget.song['id']}.mp3 ";
    play(url: url);
  }

  void initAudioPlayer() {
    audioPlayer = new AudioPlayer();
    _positionSubscription = audioPlayer.onAudioPositionChanged.listen((p) => {
          if (!isTaping) {setState(() => position = p.inSeconds)}
        });
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        if (duration == 0) {
          setState(() => duration = audioPlayer.duration.inSeconds);
          print("AudioPlayer start, duration:$duration");
        }
      } else if (s == AudioPlayerState.STOPPED) {
        onComplete();
        setState(() => position = duration);
      }
      print("AudioPlayer onPlayerStateChanged: $s");
    }, onError: (msg) {
      setState(() {
        playerState = PlayerState.stopped;
        duration = 0;
        position = 0;
      });
      print("AudioPlayer onError: $msg");
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  Future play({String url}) async {
    print("start play: $url");
    if (url != null) {
      this.url = url;
    }

    await audioPlayer.play(this.url);
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() => playerState = PlayerState.paused);
  }

  Future seek(double seconds) async {
    await audioPlayer.seek(seconds);
    if (playerState == PlayerState.paused) {
      play();
    }
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
      position = 0;
    });
  }

  Future mute(bool muted) async {
    await audioPlayer.mute(muted);
    setState(() {
      isMuted = muted;
    });
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    if (playerState == PlayerState.playing) {
      _animController.forward();
      _animController.repeat();
    } else {
      _animController.stop();
    }

    return Scaffold(
      /* appBar: AppBar(
        title: Text('Flutter Music Player'),
      ), */
      body: Stack(children: <Widget>[
        Container(
          // 背景图片
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Image.network(
            "${widget.song['al']['picUrl']}?param=300y300",
            fit: BoxFit.fill,
          ),
        ),
        // 高斯模糊遮罩层
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
          child: Opacity(
            opacity: 0.6,
            child: new Container(
              decoration: new BoxDecoration(
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ),
        SafeArea(
            child: Center(
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                margin: EdgeInsets.only(top: 30.0, bottom: 20.0),
                child: RotationTransition(
                    //设置动画的旋转中心
                    alignment: Alignment.center,
                    //动画控制器
                    turns: _animController,
                    //将要执行动画的子view
                    child: ClipOval(
                        child: GestureDetector(
                      onTap: () => {
                        playerState == PlayerState.playing ? pause() : play()
                      },
                      child: Image.network(
                          "${widget.song['al']['picUrl']}?param=300y300"),
                    )))),
            Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
                child: Text(
                  widget.song['name'],
                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                )),
            Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 40.0),
                child: Text(
                  SongUtil.getArtistNames(widget.song),
                  style: TextStyle(fontSize: 12.0, color: Colors.white60),
                )),
          ],
        ))),
        Positioned(
          bottom: 30.0,
          left: 20.0,
          right: 20.0,
          child: Row(
            children: <Widget>[
              Text(_getFormatTime(position),
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              Expanded(
                child: Slider.adaptive(
                  value: position.toDouble(),
                  min: 0.0,
                  max: duration.toDouble(),
                  onChanged: (double value) {
                    setState(() {
                      position = value.toInt();
                    });
                  },
                  onChangeStart: (double value) {
                    isTaping = true;
                  },
                  onChangeEnd: (double value) {
                    double seekPosition = value;
                    seek(seekPosition);
                    isTaping = false;
                    setState(() {
                      position = seekPosition.toInt();
                    });
                  },
                ),
              ),
              Text(
                _getFormatTime(duration),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        )
      ]),
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
