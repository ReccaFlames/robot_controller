import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';

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
        left = ((event.x * (-12)) + ((width - 60) / 2));
        top = event.y * 12 + 145;
      });
    }));
    _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
        // ToDo Need to calculate better result
        rotate = (-1)*event.z;
      });
    }));
  }
}
