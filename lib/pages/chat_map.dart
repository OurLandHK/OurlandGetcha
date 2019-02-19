
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/widgets/map/index.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'package:geodesy/geodesy.dart';

class ChatMap extends StatefulWidget {
  GeoPoint mapCenter;
  Geodesy geodesy;
  double height;
  double zoom;
  _ChatMapState state;



  ChatMap({Key key, @required GeoPoint topLeft, @required GeoPoint bottomRight, @required this.height}) : super(key: key) {
    this.mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
    this.geodesy = Geodesy();
    zoomAdjustment(topLeft, bottomRight);
  }  

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
    if(state != null && state.googleMapWidget != null) {
      state.googleMapWidget.addMarker(location, label);
    } 
  }

  void updateCenter(GeoPoint _mapCenter) {
    print('ChatMap called ${_mapCenter}');
    mapCenter = _mapCenter;
    if(state != null && state.googleMapWidget != null) {
      state.googleMapWidget.updateMapCenter(_mapCenter, 15);
    } 
  }

  void zoomAdjustment(GeoPoint topLeft, GeoPoint bottomRight) {
    LatLng l1 = LatLng(topLeft.latitude, topLeft.longitude);
    LatLng l2 = LatLng(bottomRight.latitude, bottomRight.longitude);
    double distance = this.geodesy.distanceBetweenTwoGeoPoints(l1, l2, null);
    this.zoom = 15.0;
    if(distance > 1800) {
      this.zoom = 14.0;
      if(distance > 3500) {
        this.zoom = 13.0;
        if(distance > 7000) {
          this.zoom = 12.0;
          if(distance > 15000) {
            this.zoom = 11.0;
          }
        }
      }
    }    
    //print("${this.zoom} + " " + ${distance}");
  }
  void updateMapArea(GeoPoint topLeft, GeoPoint bottomRight) {
    this.mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
    zoomAdjustment(topLeft, bottomRight);
    if(state != null && state.googleMapWidget != null) {
      state.googleMapWidget.updateMapCenter(this.mapCenter, this.zoom);
    } 
  }

  @override
  _ChatMapState createState() {
    state = new _ChatMapState();
    return state;
  }
}

// https://pub.dartlang.org/packages/geolocator

class _ChatMapState extends State<ChatMap> {
  GoogleMapWidget googleMapWidget;
  
  @override
  _ChatMapState({Key key});

  void initState() {
    super.initState();
    this.googleMapWidget = new GoogleMapWidget(widget.mapCenter.latitude, widget.mapCenter.longitude, widget.height, widget.zoom);
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