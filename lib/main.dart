import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Controller',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Controller'),
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

  double top = 125;
  double left;

  double width;
  double height;
  double rotate = 0.0;

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    final List<String> accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(2))?.toList();
    final List<String> gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(2))?.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            children: [
              // Empty container given a width and height to set the size of the stack
              Container(
                height: height / 2,
                width: width,
                color: Colors.lightBlue[100],
              ),
              Positioned(
                top: 125,
                left: (width - 100) / 2,
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
                top: top,
                left: left ?? (width - 100) / 2,
                // the container has a color and is wrapped in a ClipOval to make it round
                child: ClipOval(
                  child: Transform.rotate(
                    angle: rotate,
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
        ],
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
        double cpw = ((width - 60) / 2);
        left = ((event.x * (-cpw / 10.0)) + cpw);
        double cph = (height - 60) / 4;
        top = event.y * (cph / 10.0) + cph;
        Movement movement = new Movement(event.y, event.x, rotate);
        String json = jsonEncode(movement);
        createPost(json);
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

class Movement {
  final double move;
  final double strafe;
  final double rotate;

  Movement(this.move, this.strafe, this.rotate);

  Map<String, dynamic> toJson() => {
        'move': move,
        'strafe': strafe,
        'rotate': rotate,
      };
}
