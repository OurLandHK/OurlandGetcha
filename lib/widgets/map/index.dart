import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double width;
  final double height;
  final Map<MarkerId, Marker> googleMarkers;
  final Function upCenter;
  double zoom;
  _GoogleMapWidgetState state;

  GoogleMapWidget(
      this.latitude, this.longitude, this.width, this.height, this.zoom, this.googleMarkers, this.upCenter);
  @override
  _GoogleMapWidgetState createState() {
    state = new _GoogleMapWidgetState(googleMarkers);
    return state;
  }
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  Map<MarkerId, Marker> markers;
  bool _isCleanUp = false;
  GoogleMap _gMap;
  double latitude;
  double longitude;
  _GoogleMapWidgetState(this.markers) {
//    print("Marker Length 2 ${markers.length}");
  }
/*
  void addMarker(MarkerId markerId, Marker marker) {
    try {
      setState(() {
        markers[markerId] = marker;
      });
    } catch (exception) {
      print('addMarker exception');
      pendingMarkers.add(marker);
    }
  }
*/

  GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    void updateCamera(CameraPosition camPos) {
      this.longitude = camPos.target.longitude;
      this.latitude = camPos.target.latitude;
    }

    void updateLatLng() {
      //print("updateLatLng ${longitude} ${latitude}");
      widget.upCenter(longitude, latitude);
    }

    double width = double.infinity;
    if(widget.width != 0) {
      width = widget.width; 
    }
    
    WidgetsBinding.instance
    .addPostFrameCallback((_) => updateAnyMarkerChange(context));
    
//    print("Google Marker Length 3 ${markers.length}");
//    print("Google Marker Length 4 ${widget.googleMarkers.length}");
//    print("Google Map Center 1 ${widget.latitude} ${widget.longitude}");
    Function onCameraMove = null;
    Function onCameraIdle = null;
    bool _isMyLocation = false;
    if(widget.upCenter != null) {
      onCameraMove = updateCamera;
      onCameraIdle = updateLatLng;
      _isMyLocation = true;
    }
    _gMap = GoogleMap(
                onMapCreated: _onMapCreated,
                myLocationEnabled: _isMyLocation,
                myLocationButtonEnabled: _isMyLocation,
                scrollGesturesEnabled: _isMyLocation,
                onCameraMove: onCameraMove,
                onCameraIdle: onCameraIdle,
                initialCameraPosition: new CameraPosition(
                  target: LatLng(widget.latitude, widget.longitude),
                  zoom: widget.zoom,
                ),
                markers: Set<Marker>.of(markers.values));
    return new Container(
      child: Column(
        children: <Widget>[
          Center(
            child: SizedBox(
              width: width,
              height: widget.height,
              child: _gMap
            ),
          ),
        ],
      ),
    );
  }
  
  void updateAnyMarkerChange(BuildContext context) {
    bool isSetState = false;
    //_gMap.initialCameraPosition.target.longitude
    if(mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: widget.zoom)));
    }
    Map<MarkerId, Marker> newmarkers = {};
    if(widget.googleMarkers.length != markers.length) {
      isSetState = true;
    } else {
      for(MarkerId markerId in widget.googleMarkers.keys) {
        if(markers[markerId] == null) {
          isSetState = true;
          break;
        }
      }
    }
  //  print("Is SetState ${isSetState}");
    if(isSetState) {
      for(MarkerId markerId in widget.googleMarkers.keys) {
        newmarkers[markerId] = widget.googleMarkers[markerId];
      }
      setState(() {
        markers = newmarkers;
      });
    }
  }

  void clearMarkers() {
    _isCleanUp = true;
  }

  void _onMapCreated(GoogleMapController controller) {
      mapController = controller;
  }
}
