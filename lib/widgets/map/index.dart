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

  void addMarker(GeoPoint location, String label ,String messageId) {
    final MarkerId markerId = MarkerId(messageId);
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(location.latitude, location.longitude),
      infoWindow: InfoWindow(title: label, snippet: '*'),
      icon: BitmapDescriptor.fromAsset('assets/images/app-logo.png')
/*      onTap: () {
        _onMarkerTapped(markerId);
      },*/
    );    
    state.addMarker(markerId, marker);
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
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  List<Marker> pendingMarkers = new List<Marker>();
  bool _isCleanUp = false;
  _GoogleMapWidgetState() {
  }

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


  GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    double width = double.infinity;
    if(widget.width != 0) {
      width = widget.width; 
    }
    WidgetsBinding.instance
    .addPostFrameCallback((_) => updateAnyMarkerChange(context));
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
                markers: Set<Marker>.of(markers.values),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void updateAnyMarkerChange(BuildContext context) {
    print('updateAnyMarkerChange ${pendingMarkers.length} ${markers.length}');
    bool isSetState = false;
    Map<MarkerId, Marker> newmarkers = markers;
    if(_isCleanUp) {
      print('updateAnyMarkerChange cleanup');
      isSetState = true;
      _isCleanUp = false;
      newmarkers = <MarkerId, Marker>{};
    }
    if(pendingMarkers.length > 0) {
      isSetState = true;
      for(Marker marker in pendingMarkers) {
        newmarkers[marker.markerId] = marker;
      }
      pendingMarkers = new List<Marker>();
    }
    if(isSetState) {
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
