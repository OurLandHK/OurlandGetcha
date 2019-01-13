import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ourland_native/widgets/map/index.dart';

class ChatMap extends StatefulWidget {
  final Position mapCenter;

  ChatMap({Key key, @required this.mapCenter}) : super(key: key);

  @override
  _ChatMapState createState() => new _ChatMapState(mapCenter: this.mapCenter);
}

// https://pub.dartlang.org/packages/geolocator

class _ChatMapState extends State<ChatMap> {
  final Position mapCenter;
  
  @override
  _ChatMapState({Key key, @required this.mapCenter});

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets;
    widgets = [
        new GoogleMapWidget(this.mapCenter.latitude, this.mapCenter.longitude)
      ];
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}