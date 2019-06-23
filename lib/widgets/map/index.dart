import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double width;
  final double height;
  final Map<MarkerId, Marker> googleMarkers;
  double zoom;
  _GoogleMapWidgetState state;

  GoogleMapWidget(
      this.latitude, this.longitude, this.width, this.height, this.zoom, this.googleMarkers);
/*
  void updateMapCenter(GeoPoint center, double zoom) {
    this.zoom = zoom;
//    print('GoogleMapWidget called ${center} ${zoom}');
    state.mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: center == null
                ? LatLng(0, 0)
                : LatLng(center.latitude, center.longitude),
            zoom: this.zoom)));
  }

  void addMarker(GeoPoint location, String label ,String messageId) {
    final MarkerId markerId = MarkerId(messageId);
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(location.latitude, location.longitude),
      infoWindow: InfoWindow(title: label, snippet: '*'),
      icon: BitmapDescriptor.fromAsset('assets/images/smallnote.png')
/*      onTap: () {
        _onMarkerTapped(markerId);
      },*/
    );    
    state.addMarker(markerId, marker);
  }

  void clearMarkers() {
    state.clearMarkers();
  }
*/
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
    double width = double.infinity;
    if(widget.width != 0) {
      width = widget.width; 
    }
    
    WidgetsBinding.instance
    .addPostFrameCallback((_) => updateAnyMarkerChange(context));
    
//    print("Google Marker Length 3 ${markers.length}");
//    print("Google Marker Length 4 ${widget.googleMarkers.length}");
//    print("Google Map Center 1 ${widget.latitude} ${widget.longitude}");
    _gMap = GoogleMap(
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
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
