import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geodesy/geodesy.dart';

/* GEO library for distance/bearing/containment/enlarge calculation
Distance between 2 geos
Destination geo by distance and bearing
Geo contain inside a box
Enlarge box with geo.

https://www.movable-type.co.uk/scripts/latlong.html

*/

class GeoHelper {

  GeoHelper();

  static Map<String, GeoPoint> findBoxGeo(GeoPoint geoCenter, double distanceInMetter) {
    Map<String, GeoPoint> rv = new Map<String, GeoPoint>(); 
    Geodesy geodesy = Geodesy();
    LatLng center = new LatLng(geoCenter.latitude, geoCenter.longitude);
    LatLng llTopLeft = geodesy.destinationPointByDistanceAndBearing(center, 1000.0, 315.0, null);
    LatLng llBottomRight = geodesy.destinationPointByDistanceAndBearing(center, 1000.0, 135.0, null);
    rv['topLeft'] = new GeoPoint(llTopLeft.latitude, llTopLeft.longitude);
    rv['bottomRight'] = new GeoPoint(llBottomRight.latitude, llBottomRight.longitude);
    return rv;
  }

  static Map<String, GeoPoint> enlargeBox(GeoPoint topLeft, GeoPoint bottomRight, GeoPoint destination, double distanceInMetter) {
    Map<String, GeoPoint> rv = new Map<String, GeoPoint>();
    double top = topLeft.latitude;
    double bottom = bottomRight.latitude;
    double left = topLeft.longitude;
    double right = bottomRight.longitude; 
    Map<String, GeoPoint> destBox = findBoxGeo(destination, distanceInMetter);
    // Check top
    if(top < destBox['topLeft'].latitude) {
      top = destBox['topLeft'].latitude;
    } else if(bottom > destBox['bottomRight'].latitude) {
      bottom = destBox['bottomRight'].latitude;
    }
    if(left > destBox['topLeft'].longitude) {
      left = destBox['topLeft'].longitude;
    } else if(right < destBox['bottomRight'].longitude) {
      right = destBox['bottomRight'].longitude;
    }
    rv['topLeft'] = new GeoPoint(top, left);
    rv['bottomRight'] = new GeoPoint(bottom, right);
    return rv;
  }

  static GeoPoint boxCenter(GeoPoint topLeft, GeoPoint bottomRight) {
    return GeoPoint((topLeft.latitude + bottomRight.latitude) / 2, (topLeft.longitude + bottomRight.longitude) / 2);
  }

  static bool isGeoPointInBoudingBox(GeoPoint l, GeoPoint topLeft, GeoPoint bottomRight) {
    return topLeft.latitude >= l.latitude &&
            l.latitude >= bottomRight.latitude &&
            topLeft.longitude <= l.longitude &&
            l.longitude <= bottomRight.longitude
        ? true
        : false;
  }
}