import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/subscribe_model.dart';


final CollectionReference subscribeCollection =
    Firestore.instance.collection('subscribe');

class SubscribeService {

  Future<void> updateSubscribeRecord(SubscribeRecord record) async {
    var recordReference = subscribeCollection.document(record.fcmToken);
    Map output = record.toMap();
    return recordReference.setData(output).then((outValue) {
      return ;
    });
  }

  Future<void> updateLogin(String fcmToken) async {
    return getSubscribeRecord(fcmToken).then((rv) {
      if (rv == null) {
        rv = new SubscribeRecord([], fcmToken);
      }
      return updateSubscribeRecord(rv);
    });
  }

  Future<SubscribeRecord> getSubscribeRecord(String fcmToken) async {
    var recordReference = subscribeCollection.document(fcmToken);
    return recordReference.get().then((onValue) {
      SubscribeRecord rv;
      if (onValue.exists) {
        rv = SubscribeRecord.fromMap(onValue.data);
      } 
      return rv;
    });
  }
}
