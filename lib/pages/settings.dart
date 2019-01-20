import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
            title: new Text("Settings"),
            ),
        body: new Container(
            child: new Text("Settings Page"),
            )
    );
  }
}