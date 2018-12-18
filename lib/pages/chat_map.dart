import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class ChatMap extends StatefulWidget {
  @override
  _ChatMapState createState() => new _ChatMapState();
}

// https://pub.dartlang.org/packages/geolocator

class _ChatMapState extends State<ChatMap> {
  Position _startLocation;
  Position _currentLocation;

  StreamSubscription<Position> _positionStream;

  Geolocator _geolocator = new Geolocator();
  LocationOptions locationOptions = new LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  GeolocationStatus geolocationStatus = GeolocationStatus.denied;
  String error;

  bool currentWidget = true;

  Image image1;

  @override
  void initState() {
    super.initState();

    initPlatformState();

    _positionStream = _geolocator.getPositionStream(locationOptions).listen(
      (Position position) {
        if(position != null) {
          setState(() {
            _currentLocation = position;
          });
        }
      });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    Position location;
    // Platform messages may fail, so we use a try/catch PlatformException.

    try {
      geolocationStatus = await _geolocator.checkGeolocationPermissionStatus();
      location = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);


      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error = 'Permission denied - please ask the user to enable it from the app settings';
      }

      location = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    //if (!mounted) return;

    setState(() {
        _startLocation = location;
    });

  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets;


    if (_currentLocation == null) {
      widgets = new List();
    } else {
      widgets = [
        new Image.network(
            "https://maps.googleapis.com/maps/api/staticmap?center=${_currentLocation.latitude},${_currentLocation.longitude}&zoom=18&size=640x400&key=AIzaSyB9zmMt3yKs_cIs-mPrFesuZIflJP5KFJU")
      ];
    }

    widgets.add(new Center(
        child: new Text(_startLocation != null
            ? 'Start location: $_startLocation\n'
            : 'Error: $error\n')));

    widgets.add(new Center(
        child: new Text(_currentLocation != null
            ? 'Continuous location: $_currentLocation\n'
            : 'Error: $error\n')));

    widgets.add(new Center(
      child: new Text(geolocationStatus == GeolocationStatus.granted
            ? 'Has permission : Yes' 
            : "Has permission : No")));

    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}