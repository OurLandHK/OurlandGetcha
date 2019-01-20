import 'package:flutter/material.dart';

class About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
        title: new Text("About"),
      ),
        body: new Container(
        child: new Text("About Page"),
      )
    );
  }
}