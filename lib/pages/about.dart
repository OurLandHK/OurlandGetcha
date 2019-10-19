import 'package:flutter/material.dart';
import 'package:ourland_native/models/constant.dart';

class About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
        title: new Text("About"),
      ),
        body: new Container(
        child: new Text(ABOUT_TEXT),
      )
    );
  }
}