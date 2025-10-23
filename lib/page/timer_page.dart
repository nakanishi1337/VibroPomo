import 'package:flutter/material.dart';
import 'dart:async';
import 'setting_page.dart';
import '../viewmodel/settings.dart';
import '../services/native_alarm.dart';

// セッションの状態
enum TimerState {
  none,
  focus,
  shortBreak,
  longBreak,
}

// TimerStateをテキストに変換する関数
String getTimerStateText(TimerState timerState) {
  switch (timerState) {
    case TimerState.none:
      return '';
    case TimerState.focus:
      return 'Focus';
    case TimerState.shortBreak:
      return 'Short Break';
    case TimerState.longBreak:
      return 'Long Break';
  }
}

// ポモドーロタイマー画面のウィジェット
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({Key? key}) : super(key: key);

  @override
  PomodoroScreenState createState() => PomodoroScreenState();
}

// ポモドーロタイマー画面の状態クラス
class PomodoroScreenState extends State<PomodoroScreen> {
  // State variables
  int focusCount = 0;
  TimerState timerState = TimerState.none;
  Timer? timer;
  int totalTime = 0;
  late DateTime alarmTime;
  int remainingTime = 0;
  double progress = 0; // ゲージの進捗度
  bool isTimerRunning = false;
  bool isPaused = false;
  bool isAlarmRinging = false;

  // アラーム、タイマーを開始または再開する
  Future<void> startTimer({bool resumeFromRemaining = false}) async {
    // 既にタイマーが動作中の場合はキャンセル
    if (isTimerRunning) {
      await cancelAlarm();
    }

    // タイマーの状態を更新
    setState(() {
      final seconds = (resumeFromRemaining && remainingTime > 0) ? remainingTime : totalTime;
      alarmTime = DateTime.now().add(Duration(seconds: seconds));
      remainingTime = alarmTime.difference(DateTime.now()).inSeconds;
      isAlarmRinging = false;
      isPaused = false;
      isTimerRunning = true;
      progress = remainingTime / totalTime;
    });

    // アラームをセット
    await NativeAlarm.startAt(
      endAtEpochMs: alarmTime.millisecondsSinceEpoch,
      title: getTimerStateText(timerState),
      vibrate: appSettings.flagVibration,
      sound: appSettings.soundFilePath,
    );

    // タイマーをセット
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        remainingTime = alarmTime.difference(DateTime.now()).inSeconds;
        progress = remainingTime / totalTime;
      });

      if (remainingTime < 0) {
        setState(() {
          remainingTime = 0;
          progress = 0;
          isAlarmRinging = true;
        });
      }
    });
  }

  // アラーム、タイマーをキャンセル
  Future<void> cancelAlarm() async {
    timer?.cancel();
    await NativeAlarm.cancel();
  }

  // フォーカスセッションを開始
  void startFocus() {
    setState(() {
      focusCount++;
      totalTime = 60 * appSettings.focusTime;
      timerState = TimerState.focus;
    });
    startTimer();
  }

  // ショートブレイクセッションを開始
  void startShortBreak() {
    setState(() {
      totalTime = remainingTime = 60 * appSettings.shortBreakTime;
      timerState = TimerState.shortBreak;
    });
    startTimer();
  }

  // ロングブレイクセッションを開始
  void startLongBreak() {
    setState(() {
      focusCount = 0;
      totalTime = 60 * appSettings.longBreakTime;
      timerState = TimerState.longBreak;
    });
    startTimer();
  }

  // セッションを再開
  void resumeSession() {
    if (timerState == TimerState.none) {
      return;
    }

    startTimer(resumeFromRemaining: true);

    setState(() {
      isPaused = false;
    });
  }

  // セッションを一時停止
  void pauseSession() {
    if (timerState == TimerState.none) {
      return;
    }

    cancelAlarm();

    setState(() {
      isTimerRunning = false;
      isPaused = true;
    });
  }

  // セッションを停止
  void stopSession() {
    if (timerState == TimerState.none) {
      return;
    }

    if (isAlarmRinging) {
      NativeAlarm.stopRingtone();
    }

    cancelAlarm();

    setState(() {
      remainingTime = 0;
      progress = 0;
      isTimerRunning = false;
      isAlarmRinging = false;
      timerState = TimerState.none;
    });
  }

  // セッションを取り消し
  void replaySession() {
    if (timerState == TimerState.none) {
      return;
    }

    if (isAlarmRinging) {
      NativeAlarm.stopRingtone();
    }

    cancelAlarm();

    // フォーカスセッションをリプレイする場合、focusCountを調整
    if (timerState == TimerState.focus && focusCount > 0) {
      focusCount -= 1;
    }

    setState(() {
      remainingTime = 0;
      progress = 0;
      isTimerRunning = false;
      isPaused = false;
      isAlarmRinging = false;
      timerState = TimerState.none;
    });
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final mainColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'VibroPomo',
            style: TextStyle(fontSize: 25),
          ),
          backgroundColor: mainColor,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const SettingPage();
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Column(
                  children: [
                    DottedProgressBar(
                      totalDots: appSettings.longBreakInterval,
                      filledDots: focusCount,
                      width: size.width * 0.05 * appSettings.longBreakInterval,
                      height: 12.0,
                    ),
                    const SizedBox(height: 40),
                    Center(
                        child: (timerState != TimerState.none)
                            ? Text(
                                '${getTimerStateText(timerState)} Time',
                                style: const TextStyle(
                                  fontSize: 25,
                                ),
                              )
                            : const Text(
                                '',
                                style: TextStyle(
                                  fontSize: 25,
                                ),
                              )),
                  ],
                )),
            const SizedBox(height: 10),
            Container(
              width: size.width * 0.85,
              alignment: AlignmentDirectional.center,
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: Stack(
                    alignment: AlignmentDirectional.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Align(
                          alignment: Alignment.bottomLeft,
                          child: Stack(alignment: AlignmentDirectional.center, children: <Widget>[
                            Container(
                              width: size.width * 0.7 * 0.33,
                              height: size.width * 0.7 * 0.33,
                              decoration: BoxDecoration(
                                color: mainColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (isAlarmRinging) {
                                  setState(() {
                                    stopSession();
                                  });
                                } else if (isTimerRunning) {
                                  setState(() {
                                    pauseSession();
                                  });
                                } else {
                                  setState(() {
                                    resumeSession();
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                shape: const CircleBorder(),
                              ),
                              child: isPaused
                                  ? Icon(Icons.play_arrow, size: size.width * 0.1)
                                  : Icon(Icons.pause, size: size.width * 0.1),
                            ),
                          ])),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Stack(
                          alignment: AlignmentDirectional.center,
                          children: <Widget>[
                            Container(
                              width: size.width * 0.7 * 0.33,
                              height: size.width * 0.7 * 0.33,
                              decoration: BoxDecoration(
                                color: mainColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  replaySession();
                                });
                              },
                              style: TextButton.styleFrom(
                                shape: const CircleBorder(),
                              ),
                              child: Icon(Icons.replay, size: size.width * 0.1),
                            ),
                          ],
                        ),
                      ),
                      Align(
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: size.width * 0.7,
                                height: size.width * 0.7,
                                decoration: BoxDecoration(
                                  color: mainColor.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(
                                width: size.width * 0.6,
                                height: size.width * 0.6,
                                child: CircularProgressIndicator(
                                    strokeWidth: 8.0,
                                    value: progress,
                                    backgroundColor: mainColor.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(mainColor)),
                              ),
                              Text(
                                '${remainingTime ~/ 60}:${(remainingTime % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 36),
                              ),
                              Visibility(
                                visible: isAlarmRinging,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      stopSession();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    shape: const CircleBorder(),
                                  ),
                                  child: Icon(
                                    Icons.stop,
                                    size: size.width * 0.4,
                                    color: mainColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ]),
              ),
            ),
            const SizedBox(
              height: 0,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(100, 100),
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      startFocus();
                    });
                  },
                  child: const Text('Focus',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(100, 100),
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      startShortBreak();
                    });
                  },
                  child: const Text('Short Break',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(100, 100),
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      startLongBreak();
                    });
                  },
                  child: const Text('Long Break',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                ),
              ]),
            )
          ],
        ),
      ),
    );
  }
}

// ドットで進捗を表示するウィジェット
class DottedProgressBar extends StatelessWidget {
  final int totalDots;
  final int filledDots;
  final double width;
  final double height;

  const DottedProgressBar({
    Key? key,
    required this.totalDots,
    required this.filledDots,
    this.width = double.infinity,
    this.height = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double dotWidth = width / totalDots;

    return SizedBox(
      width: width,
      height: height,
      child: Row(
        children: List.generate(totalDots, (index) {
          bool isFilled = index < filledDots;
          Color dotColor = isFilled ? Colors.black : Colors.grey;
          return Container(
            width: dotWidth,
            height: height,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          );
        }),
      ),
    );
  }
}
