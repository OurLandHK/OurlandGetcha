import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ourland_native/firestore_helpers/firestore_helpers.dart';
import 'package:ourland_native/firestore_helpers/geo_helpers.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/searching_msg_model.dart';

final CollectionReference _viewCollection =
    Firestore.instance.collection('view');

class ViewRecord {
  int count;
  DateTime lastUpdate;

  ViewRecord() {
    lastUpdate = DateTime.now();
    count = 0;
  }
  
  ViewRecord.fromMap(Map<String, dynamic> map) {
    this.lastUpdate = DateTime.fromMicrosecondsSinceEpoch(map['lastUpdate'].microsecondsSinceEpoch);
    this.count = map['count'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['lastUpdate'] = lastUpdate;
    map['count'] = count;
    return map;
  }
}
class ViewService {
  ViewService();

  Future<ViewRecord> updateViewRecord(String topicID, String fcmToken) {
    ViewRecord rv = new ViewRecord();
    var viewReference = _viewCollection
            .document(topicID);
    var userViewReference = viewReference.collection('userView').document(fcmToken);
    return userViewReference.get().then((onValue) {
      if(!onValue.exists) {
        userViewReference.setData(rv.toMap());
        return _getViewRecord(topicID).then((value) {
          value.lastUpdate = rv.lastUpdate;
          value.count++;
          return viewReference.setData(value.toMap()).then((dummy) {
            return value;
          });
        });
      } else {
        return _getViewRecord(topicID).then((value)  {return value;});
      }
    });
  }


  Future<ViewRecord> _getViewRecord(String topicID) {
    var viewReference = _viewCollection
            .document(topicID);
    return viewReference.get().then((onValue) {
      if(onValue.exists) {
        return ViewRecord.fromMap(onValue.data);
      } else {
        ViewRecord rv = new ViewRecord();
        return rv;
      }
    });
  }
}