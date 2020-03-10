import 'dart:math';
import 'dart:convert';
import 'package:ourland_native/models/constant.dart';

class SubscribeRecord {
  List<String> unsubscribedChannels;
  String fcmToken;
  DateTime lastLogin;

  SubscribeRecord(this.unsubscribedChannels, this.fcmToken) {
    lastLogin = DateTime.now();
  }

  SubscribeRecord.fromMap(Map<String, dynamic> map) {
    fcmToken = map['fcmToken'];
    this.lastLogin = DateTime.fromMicrosecondsSinceEpoch(map['lastLogin'].microsecondsSinceEpoch);
    unsubscribedChannels = [];
    for(int i = 0; i< map['unsubscribedChannels'].length; i++) {
      unsubscribedChannels.add(map['unsubscribedChannels'][i]);
    } 
  }

  Map<String, dynamic> toMap() {
    lastLogin = DateTime.now();
    var map = new Map<String, dynamic>();
    map['fcmToken'] = fcmToken;
    map['lastLogin'] = lastLogin;
    map['unsubscribedChannels'] = unsubscribedChannels;
    return map;
  }
}
