import 'package:cloud_firestore/cloud_firestore.dart';

/* GEO library for distance/bearing/containment/enlarge calculation
Distance between 2 geos
Destination geo by distance and bearing
Geo contain inside a box
Enlarge box with geo.

https://www.movable-type.co.uk/scripts/latlong.html

*/

class GeoHelper {

  GeoHelper();

  static Map<String, GeoPoint> enlargeBox(GeoPoint topLeft, GeoPoint bottomRight, GeoPoint destination) {
    Map<String, GeoPoint> rv = new Map<String, GeoPoint>();
    double top = topLeft.latitude;
    double bottom = bottomRight.latitude;
    double left = topLeft.longitude;
    double right = bottomRight.longitude; 
    // Check top
    if(top < destination.latitude) {
      top = destination.latitude;
    } else if(bottom > destination.latitude) {
      bottom = destination.latitude;
    }
    if(left > destination.longitude) {
      left = destination.longitude;
    } else if(right < destination.longitude) {
      right = destination.longitude;
    }
    rv['topLeft'] = new GeoPoint(top, left);
    rv['bottomRight'] = new GeoPoint(bottom, right);
    return rv;
  }
}