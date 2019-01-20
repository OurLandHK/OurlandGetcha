import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/widgets/map/index.dart';

class ChatMap extends StatefulWidget {
  GeoPoint mapCenter;
  _ChatMapState state;


  ChatMap({Key key, @required this.mapCenter}) : super(key: key);

  void addLocation(GeoPoint location, String content, int contentType, String username) {
    String label = "";
    switch(contentType) {
      case 0:
        label = content;
        break;
      default:
        label = username;
    }
    // only handle text message now
    if(contentType == 0 && state != null && state.googleMapWidget != null) {
      state.googleMapWidget.addMarker(location, label);
    } 
  }

  void updateCenter(GeoPoint _mapCenter) {
    print('ChatMap called ${_mapCenter}');
    mapCenter = _mapCenter;
    if(state != null && state.googleMapWidget != null) {
      state.googleMapWidget.updateMapCenter(_mapCenter);
    } 
  }

  @override
  _ChatMapState createState() {
    state = new _ChatMapState(mapCenter: this.mapCenter);
    return state;
  }
}

// https://pub.dartlang.org/packages/geolocator

class _ChatMapState extends State<ChatMap> {
  GeoPoint mapCenter;
  GoogleMapWidget googleMapWidget;
  
  @override
  _ChatMapState({Key key, @required this.mapCenter});

  void initState() {
    super.initState();
    this.googleMapWidget = new GoogleMapWidget(mapCenter.latitude, mapCenter.longitude);
  }

  @override
  Widget build(BuildContext context) {

    Widget rv = this.googleMapWidget;
    if(rv == null) {
      rv = new CircularProgressIndicator();
    }
    List<Widget> widgets;
    widgets = [
        rv
      ];
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}