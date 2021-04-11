import 'dart:async';

import 'package:flutter/material.dart';
import 'package:background_location/background_location.dart';
import 'package:latlong/latlong.dart';
import 'package:audioplayers/audio_cache.dart';

class Main extends StatefulWidget {
  Main({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainState createState() => _MainState();
}

String formatTime(int milliseconds) {
  var secs = milliseconds ~/ 1000;
  var hours = (secs ~/ 3600).toString().padLeft(2, '0');
  var minutes = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
  var seconds = (secs % 60).toString().padLeft(2, '0');
  return "$hours:$minutes:$seconds";
}

class _MainState extends State<Main> {
  Timer renderTimer;

  int runTargetPace = 300000;
  List<Location> runLocationsList = [];
  double runTotalDistanceInM = 0;
  int runLastMinuteAvgPace = 0;
  Stopwatch runStopwatch;
  Timer runMotivationTimer;

  static AudioCache player = new AudioCache();

  @override
  void initState() {
    super.initState();
    runStopwatch = Stopwatch();

    renderTimer = new Timer.periodic(new Duration(milliseconds: 100), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _stopRun();
    renderTimer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _startRun() async {
    setState(() {
      runStopwatch.start();
      runLocationsList = [];
      runTotalDistanceInM = 0;
      runLastMinuteAvgPace = 0;

      runMotivationTimer =
          new Timer.periodic(new Duration(seconds: 30), (timer) {
        int lastMinute = DateTime.now().millisecondsSinceEpoch - 60000;
        List<Location> lastMinuteLocationsList = runLocationsList
            .where((location) => location.time > lastMinute)
            .toList();
        final Distance distance = new Distance();
        double _lastMinuteDistanceInM = 0;

        for (var i = 0; i < lastMinuteLocationsList.length - 1; i++) {
          _lastMinuteDistanceInM += distance(
              LatLng(lastMinuteLocationsList[i].latitude,
                  lastMinuteLocationsList[i].longitude),
              LatLng(lastMinuteLocationsList[i + 1].latitude,
                  lastMinuteLocationsList[i + 1].longitude));
        }

        setState(() {
          runLastMinuteAvgPace =
              ((1000 / _lastMinuteDistanceInM) * 60000).toInt();
        });

        if (runLastMinuteAvgPace > runTargetPace) {
          player.play('faster.mp3');
        } else {
          player.play('slow_down.mp3');
        }
      });
    });

    await BackgroundLocation.setAndroidNotification(
      title: "Running",
      message: "Running in progress",
      icon: "@mipmap/ic_launcher",
    );
    await BackgroundLocation.setAndroidConfiguration(50);
    await BackgroundLocation.startLocationService();
    BackgroundLocation.getLocationUpdates((location) {
      final Distance distance = new Distance();
      double _totalDistanceInM = 0;

      setState(() {
        runLocationsList.add(location);

        for (var i = 0; i < runLocationsList.length - 1; i++) {
          _totalDistanceInM += distance(
              LatLng(
                  runLocationsList[i].latitude, runLocationsList[i].longitude),
              LatLng(runLocationsList[i + 1].latitude,
                  runLocationsList[i + 1].longitude));
        }

        runTotalDistanceInM = _totalDistanceInM;
      });
    });

    player.play('run_started.mp3');
  }

  void _stopRun() {
    setState(() {
      runStopwatch.stop();
      runStopwatch.reset();
      runMotivationTimer.cancel();
    });

    player.play('run_finished.mp3');

    BackgroundLocation.stopLocationService();
  }

  void _toggleRun() {
    runStopwatch.isRunning ? _stopRun() : _startRun();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Target pace (min per km):'),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: !runStopwatch.isRunning
                    ? () {
                        setState(() {
                          runTargetPace += 5000;
                        });
                      }
                    : null,
                child: Text('+'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    _formatDuration(new Duration(milliseconds: runTargetPace))),
              ),
              ElevatedButton(
                onPressed: !runStopwatch.isRunning
                    ? () {
                        setState(() {
                          runTargetPace -= 5000;
                        });
                      }
                    : null,
                child: Text('-'),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          if (this.runStopwatch.isRunning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Time:'),
            ),
          if (this.runStopwatch.isRunning)
            Text(
              formatTime(runStopwatch.elapsedMilliseconds),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
              textAlign: TextAlign.center,
            ),
          if (this.runStopwatch.isRunning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Distance (km):'),
            ),
          if (this.runStopwatch.isRunning)
            Text(
              (this.runTotalDistanceInM / 1000).toStringAsFixed(2),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
              textAlign: TextAlign.center,
            ),
          if (this.runStopwatch.isRunning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Average pace last min. (min/km):'),
            ),
          if (this.runStopwatch.isRunning)
            Text(
              formatTime(runLastMinuteAvgPace),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  color: runLastMinuteAvgPace == 0
                      ? Colors.black
                      : runLastMinuteAvgPace > runTargetPace
                          ? Colors.red
                          : Colors.green),
              textAlign: TextAlign.center,
            )
        ],
      )),
      floatingActionButton: FloatingActionButton(
          child: Icon(
              (this.runStopwatch.isRunning) ? Icons.stop : Icons.play_arrow),
          onPressed: _toggleRun),
    );
  }
}
