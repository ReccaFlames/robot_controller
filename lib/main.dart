import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'package:http/http.dart' as http;

import 'movement.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Controller',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Scaffold(body: MyHomePage(title: 'Controller')),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<double> _accelerometerValues;
  List<double> _gyroscopeValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  static const int MAX_SAMPLE_SIZE = 3;
  List<double> _rollingAvgGyroZ = <double>[];

  List<double> roll(List<double> list, double newValue) {
    if (list == null) {
      return list;
    }
    if (list.length == MAX_SAMPLE_SIZE) {
      list.removeAt(0);
    }
    list.add(newValue);
    return list;
  }

  averageList(List<double> tallyUp) {
    if (tallyUp == null) {
      return 0.0;
    }
    double total = tallyUp.reduce((a, b) => a + b);
    return total / tallyUp.length;
  }

  Future<String> createPost(String data) async {
    String url = 'https://jsonplaceholder.typicode.com/posts';
    return http.post(
      url,
      body: data,
      headers: {"Content-type": "application/json; charset=UTF-8"},
    ).then((http.Response response) {
      final int statusCode = response.statusCode;
      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return "Success";
    });
  }

  bool saveData = false;

  double planeTop;
  double planeLeft;

  double screenWidth;
  double screenHeight;
  double rotate = 0.0;

  buildSnackBarInfo({String text}) {
    return SnackBar(
      content: Text(text),
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          Scaffold.of(context).hideCurrentSnackBar();// Some code to undo the change.
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    final List<String> accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(2))?.toList();
    final List<String> gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(2))?.toList();

    void sendData(bool value) {
      if(value) {
        Scaffold.of(context).showSnackBar(
            buildSnackBarInfo(text: 'STARTED sending data')
        );
      } else {
        Scaffold.of(context).showSnackBar(
            buildSnackBarInfo(text: 'STOPED sending data')
        );
      }
      setState(() {
        saveData = value;
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Stack(
              children: [
                // Empty container given a width and height to set the size of the stack
                Container(
                  height: screenHeight / 2,
                  width: screenWidth,
                  color: Colors.lightBlue[100],
                ),
                Positioned(
                  top: ((screenHeight/2)-60)/2,
                  left: (screenWidth - 100) / 2,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2.0),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                Positioned(
                  top: planeTop ?? (screenHeight -60) / 4,
                  left: planeLeft ?? (screenHeight - 60) / 2,
                  // the container has a color and is wrapped in a ClipOval to make it round
                  child: ClipOval(
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.transparent,
                      child: Center(
                        child: Icon(
                          Icons.local_airport,
                          color: Colors.red,
                          size: 48.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Accelerometer: $accelerometer',
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Gyroscope: $gyroscope',
              ),
            ),
            Text(
              'rotate: $rotate',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                'Sender',
              ),
            ),
            Switch(
              value: saveData,
              onChanged: (value) {
                sendData(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
        //set Circle Position
        double cpw = ((screenWidth - 60) / 2);
        planeLeft = ((event.x * (-cpw / 10.0)) + cpw);
        double cph = (screenHeight - 60) / 4;
        planeTop = event.y * (cph / 10.0) + cph;
        if (saveData) {
          String json = jsonEncode(Movement(event.y, event.x, rotate));
          createPost(json);
        }
      });
    }));
    _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
        _rollingAvgGyroZ = roll(_rollingAvgGyroZ, event.x);
        rotate = averageList(_rollingAvgGyroZ);
      });
    }));
  }
}
