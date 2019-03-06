import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double width;
  final double height;
  double zoom;
  _GoogleMapWidgetState state;

  GoogleMapWidget(
      this.latitude, this.longitude, this.width, this.height, this.zoom);

  void updateMapCenter(GeoPoint center, double zoom) {
    this.zoom = zoom;
    print('GoogleMapWidget called ${center} ${zoom}');
    state.mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: center == null
                ? LatLng(0, 0)
                : LatLng(center.latitude, center.longitude),
            zoom: this.zoom)));
  }

  void addMarker(GeoPoint location, String label) {
//    print('addMarker ${label}');
    final markerOptions = MarkerOptions(
      position: LatLng(location.latitude, location.longitude),
      infoWindowText: InfoWindowText(label, null),
//              icon: BitmapDescriptor.fromAsset('images/flutter.png',),
//              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    state.addMarker(markerOptions);
  }

  void clearMarkers() {
    state.clearMarkers();
  }

  @override
  _GoogleMapWidgetState createState() {
    state = new _GoogleMapWidgetState();
    return state;
  }
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  List<MarkerOptions> pendingMarkerList;
  _GoogleMapWidgetState() {
    pendingMarkerList = new List<MarkerOptions>();
  }

  GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    double width = double.infinity;
    if(widget.width != 0) {
      width = widget.width; 
    }
    return new Container(
      child: Column(
        children: <Widget>[
          Center(
            child: SizedBox(
              width: width,
              height: widget.height,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                initialCameraPosition: new CameraPosition(
                  target: LatLng(widget.latitude, widget.longitude),
                  zoom: widget.zoom,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addMarker(MarkerOptions options) {
  //  print('$options');
    if (mapController != null) {
      mapController.addMarker(options);
    } else {
      pendingMarkerList.add(options);
    }
  }

  void clearMarkers() {
    if (mapController != null) {
      mapController.clearMarkers();
    } else {
      pendingMarkerList.clear();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    //setState(() {
      mapController = controller;
 //     print('create map $pendingMarkerList.length');
      pendingMarkerList.forEach((option) {
        mapController.addMarker(option);
      });
    //});
  }
}
