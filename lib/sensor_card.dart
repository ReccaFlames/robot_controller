import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String subtitle;

  SensorCard({this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Card(
        margin: EdgeInsets.all(8),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

}