import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double height;
  double zoom;
  _GoogleMapWidgetState state;

  GoogleMapWidget(
      this.latitude, this.longitude, @required this.height, this.zoom);

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
    return new Container(
      child: Column(
        children: <Widget>[
          Center(
            child: SizedBox(
              width: double.infinity,
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
    setState(() {
      mapController = controller;
      pendingMarkerList.forEach((option) {
        mapController.addMarker(option);
      });
    });
  }
}
