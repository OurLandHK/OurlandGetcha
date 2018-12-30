import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class GoogleMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  GoogleMapWidget(this.latitude, this.longitude);

  @override
  _GoogleMapWidgetState createState() => new _GoogleMapWidgetState();
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