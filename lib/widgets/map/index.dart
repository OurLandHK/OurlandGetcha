import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class GoogleMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  _GoogleMapWidgetState state;

  GoogleMapWidget(this.latitude, this.longitude);

  void updateMapCenter (Position center) {
    print('GoogleMapWidget called ${center}');
     state.mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: center == null ? LatLng(0, 0) : LatLng(center.latitude, center.longitude), zoom: 15.0)));
  }

  @override
  _GoogleMapWidgetState createState()  {
    state = new _GoogleMapWidgetState();
    return state;
  }
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {

  GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: Column(
        children: <Widget>[
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 240.0,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                options: GoogleMapOptions(
                    myLocationEnabled: true,
                    cameraPosition: new CameraPosition(
                      target: LatLng(widget.latitude, widget.longitude),
                      zoom: 15.0,
                    )
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() { mapController = controller; });
  }
}