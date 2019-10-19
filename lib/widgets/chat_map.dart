import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/widgets/map/index.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'package:geodesy/geodesy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as GoogleMap;


class OurlandMarker {
  final GeoPoint location;
  String label;
  String messageId;
  String username;
  int type;
  OurlandMarker(this.messageId, this.location, this.type, this.label, this.username) {
  }
}
class ChatMap extends StatefulWidget {
  GeoPoint mapCenter;
  Geodesy geodesy;
  double height;
  double width;
  double zoom;
  Function updateCenter;
  final List<OurlandMarker> markerList;
  _ChatMapState state;

  ChatMap(
      {Key key,
      @required GeoPoint topLeft,
      @required GeoPoint bottomRight,
      this.width,
      @required this.height,
      this.markerList,
      this.updateCenter})
      : super(key: key) {
    this.mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
    this.geodesy = Geodesy();
    zoomAdjustment(topLeft, bottomRight);
  }

  void zoomAdjustment(GeoPoint topLeft, GeoPoint bottomRight) {
    LatLng l1 = LatLng(topLeft.latitude, topLeft.longitude);
    LatLng l2 = LatLng(bottomRight.latitude, bottomRight.longitude);
    double distance = this.geodesy.distanceBetweenTwoGeoPoints(l1, l2, null);
    this.zoom = 15.0;
    if (distance > 1800) {
      this.zoom = 14.0;
      if (distance > 3500) {
        this.zoom = 13.0;
        if (distance > 7000) {
          this.zoom = 12.0;
          if (distance > 15000) {
            this.zoom = 11.0;
          }
        }
      }
    }
    //print("${this.zoom} + " " + ${distance}");
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
    this.googleMapWidget = createMapWithMarker();
  }

  void upCenter(double longitude, double latitude) {
    if(widget.updateCenter != null) {
      widget.updateCenter(GeoPoint(latitude, longitude));
    }
  }

  GoogleMapWidget createMapWithMarker() {
    Map<GoogleMap.MarkerId, GoogleMap.Marker> googleMarkers = <GoogleMap.MarkerId, GoogleMap.Marker>{};
    for(int i = 0; i < widget.markerList.length; i++) {
      GoogleMap.MarkerId markerId = GoogleMap.MarkerId(widget.markerList[i].messageId);
      GoogleMap.Marker marker = null;
      switch(widget.markerList[i].type) {
        case 0:
          marker = GoogleMap.Marker(
            markerId: markerId,
            position: GoogleMap.LatLng(widget.markerList[i].location.latitude, widget.markerList[i].location.longitude),
            infoWindow: GoogleMap.InfoWindow(title: widget.markerList[i].label, snippet: '*'),
            //icon: GoogleMap.BitmapDescriptor.fromAsset('assets/images/smallnote.png')
    /*      onTap: () {
            _onMarkerTapped(markerId);
          },*/
          );
          break;
        default: 
          marker = GoogleMap.Marker(
            markerId: markerId,
            position: GoogleMap.LatLng(widget.markerList[i].location.latitude, widget.markerList[i].location.longitude),
            infoWindow: GoogleMap.InfoWindow(title: widget.markerList[i].label, snippet: '*'),
    /*      onTap: () {
            _onMarkerTapped(markerId);
          },*/
          );
          break;        
      }
      googleMarkers[markerId] = marker;
    }
    Function _updateCenter = null;
    if(widget.updateCenter != null) {
      _updateCenter = upCenter;
    }
    return new GoogleMapWidget(widget.mapCenter.latitude,
        widget.mapCenter.longitude, widget.width, widget.height, widget.zoom, googleMarkers, upCenter);    
  }

  @override
  Widget build(BuildContext context) {
    Widget rv = createMapWithMarker();
    if (rv == null) {
      rv = new CircularProgressIndicator();
    }
    return rv;
  }
}
