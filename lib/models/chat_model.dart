import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'package:ourland_native/models/user_model.dart';

class ChatModel {
  String parentID;
  User _user;

  ChatModel(this.parentID, User this._user);

  Stream<QuerySnapshot> getMessageSnap(Position position, int distanceInKM) {
    Stream<QuerySnapshot> rv;
    if(this.parentID.compareTo(TOPIC_ROOT_ID) !=0) {
      rv = Firestore.instance
            .collection('chat')
            .document(this.parentID)
            .collection("messages")
            .orderBy('created', descending: true)
            .limit(20)
            .snapshots();
    } else {
      // add checking for distanceInKm
      rv = Firestore.instance
            .collection('index')
            .orderBy('created', descending: true)
            .snapshots();
    }
    return rv;
  }

  Future<Map<String, dynamic>> getMessage(String messageId) {
    String _parentID = messageId;
    if(this.parentID.compareTo(TOPIC_ROOT_ID) !=0) {
      _parentID = this.parentID;
    }
    var chatReference = Firestore.instance
            .collection('chat')
            .document(_parentID).collection("messages").document(messageId);
    return chatReference.get().then((onValue) {
      if(onValue.exists) {
        return onValue.data;
      } else {
        return null;
      }
    });
  }

  void sendTopicMessage(GeoPoint position, String topic, List<String> tags, String content, int type, bool isShowGeo) {
    print('SendMessage ${position}');
    var chatReference;
    var indexReference;
    var sendMessageTime = DateTime.now();
    var basicUserMap = _user.toBasicMap();
    String sendMessageTimeString = sendMessageTime.millisecondsSinceEpoch.toString();
    var indexData = {
          'created': sendMessageTime,
          'lastUpdate': sendMessageTime,
          'id': sendMessageTimeString,
          'geotopleft' : new GeoPoint(position.latitude, position.longitude),
          'geobottomright' :new GeoPoint(position.latitude, position.longitude),
          'topic' : topic,
          'tags' : tags,
          'isShowGeo' : isShowGeo,
          'createdUser' : basicUserMap,
    };
    var chatData = {
          'created': sendMessageTime,
          'id': sendMessageTimeString,
          'geo': new GeoPoint(position.latitude, position.longitude),
          'content': content,
          'type': type,
          'createdUser' : basicUserMap,
    };
    indexReference = Firestore.instance
      .collection('index')
      .document(sendMessageTimeString);
    chatReference = Firestore.instance
      .collection('chat')
      .document(sendMessageTimeString).collection("messages").document(sendMessageTimeString);
    try {
    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(indexReference, indexData);
      if(content.length != 0) {
        await transaction.set(chatReference, chatData);
      }
    });          
    } catch (exception) {
      print(exception);
    }
  }

  void sendChildMessage(GeoPoint position, String content, int type) {
      print(this.parentID);
      var sendMessageTime = DateTime.now();
      String sendMessageTimeString = sendMessageTime.millisecondsSinceEpoch.toString();
      DocumentReference chatReference;
      DocumentReference indexReference;
      indexReference = Firestore.instance
        .collection('index')
        .document(this.parentID);
      indexReference.get().then((indexDataSnap) {
        if(indexDataSnap.exists) {
          var indexData = indexDataSnap.data;
          var basicUserMap = _user.toBasicMap();
          indexData['lastUpdate'] = sendMessageTime;
          GeoPoint dest = new GeoPoint(position.latitude, position.longitude);
          Map<String, GeoPoint> enlargeBox = GeoHelper.enlargeBox(indexData['geotopleft'], indexData['geobottomright'], dest);
          indexData['geotopleft'] = enlargeBox['topLeft'];
          indexData['geobottomright'] = enlargeBox['bottomRight'];
          indexData['lastUpdateUser'] = basicUserMap;
          var chatData = {
                'created': sendMessageTime,
                'id': sendMessageTimeString,
                'geo': new GeoPoint(position.latitude, position.longitude),
                'content': content,
                'type': type,
                'createdUser' : basicUserMap,
          };
          chatReference = Firestore.instance
            .collection('chat')
            .document(this.parentID).collection("messages").document(sendMessageTimeString);
          try{
            Firestore.instance.runTransaction((transaction) async {
              await transaction.set(indexReference, indexData);
              await transaction.set(chatReference, chatData);
            });         
          } catch (exception) {
            print(exception);
          } 
        };
      });
  }
}
