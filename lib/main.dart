import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';

import 'rollAverage.dart';
import 'jsonSender.dart';
import 'movement.dart';
import 'sensor_card.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Scaffold(body: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<double> _accelerometerValues;
  List<double> _gyroscopeValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  RollAverage rollAverage = new RollAverage();

  bool saveData = false;
  String url = 'https://jsonplaceholder.typicode.com/posts';

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
          Scaffold.of(context)
              .hideCurrentSnackBar(); // Some code to undo the change.
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
      if (value) {
        Scaffold.of(context)
            .showSnackBar(buildSnackBarInfo(text: 'STARTED sending data'));
      } else {
        Scaffold.of(context)
            .showSnackBar(buildSnackBarInfo(text: 'STOPED sending data'));
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
                  top: ((screenHeight / 2) - 60) / 2,
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
                  top: planeTop ?? (screenHeight - 60) / 4,
                  left: planeLeft ?? (screenWidth - 60) / 2,
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                SensorCard(title: 'Accelerometer', subtitle: '$accelerometer'),
                SensorCard(title: 'Gyroscope', subtitle: '$gyroscope'),
              ],
            ),

            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Card(
                    elevation: 1,
                    margin: EdgeInsets.all(8),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Sender',
                          ),
                        ),
                        Switch(
                          value: saveData,
                          onChanged: sendData,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Endpoint',
                          ),
                        ),
                        FlatButton(
                          child: Text(url),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ],
            )
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
          JsonSender.createPost(json, url);
        }
      });
    }));
    _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
        rotate = rollAverage.calculate(event.x);
      });
    }));
  }
}
