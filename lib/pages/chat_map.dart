import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ourland_native/widgets/map/index.dart';

class ChatMap extends StatefulWidget {
  Position mapCenter;

  ChatMap({Key key, @required this.mapCenter}) : super(key: key);
  void updateCenter(Position _mapCenter) {
    print('ChatMap called ${_mapCenter}');
    this.createState().updateCenter(_mapCenter);
  }

  @override
  _ChatMapState createState() => new _ChatMapState(mapCenter: this.mapCenter);
}

// https://pub.dartlang.org/packages/geolocator

class _ChatMapState extends State<ChatMap> {
  Position mapCenter;
  
  @override
  _ChatMapState({Key key, @required this.mapCenter});

  void initState() {
    super.initState();
  }

  void updateCenter(Position _mapCenter) {
    print('ChatMapState called ${_mapCenter}');
    this.mapCenter = _mapCenter;
  }

  @override
  Widget build(BuildContext context) {
    /*
    Widget rv = new GoogleMapWidget(this.mapCenter.latitude, this.mapCenter.longitude);
    return rv;
    */
    List<Widget> widgets;
    widgets = [
        GoogleMapWidget(this.mapCenter.latitude, this.mapCenter.longitude)
      ];
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}