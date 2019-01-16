import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../helper/geo_helper.dart';

class ChatModel {
  String parentID;

  ChatModel(this.parentID);

  Stream<QuerySnapshot> getMessageSnap(Position position, int distanceInKM) {
    Stream<QuerySnapshot> rv;
    if(this.parentID.length != 0) {
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
    if(this.parentID.length != 0) {
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

  void sendMessage(Position position, String content, int type) {
    print('SendMessage ${position}');
    var chatReference;
    var indexReference;
    var sendMessageTime = DateTime.now();
    String sendMessageTimeString = sendMessageTime.millisecondsSinceEpoch.toString();
    if(this.parentID.length == 0) {
      var indexData = {
            'created': sendMessageTime,
            'lastUpdate': sendMessageTime,
            'id': sendMessageTimeString,
            'geotopleft' : new GeoPoint(position.latitude, position.longitude),
            'geobottomright' :new GeoPoint(position.latitude, position.longitude),
      };
      var chatData = {
            'created': sendMessageTime,
            'id': sendMessageTimeString,
            'geo': new GeoPoint(position.latitude, position.longitude),
            'content': content,
            'type': type
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
        await transaction.set(chatReference, chatData);
      });          
      } catch (exception) {
        print(exception);
      }
    } else {
      sendChildMessage(position, content, type, sendMessageTime);
    }
  }

  void sendChildMessage(Position position, String content, int type, var sendMessageTime) {
      print(this.parentID);
      String sendMessageTimeString = sendMessageTime.millisecondsSinceEpoch.toString();
      DocumentReference chatReference;
      DocumentReference indexReference;
      indexReference = Firestore.instance
        .collection('index')
        .document(this.parentID);
      indexReference.get().then((indexDataSnap) {
        if(indexDataSnap.exists) {
          var indexData = indexDataSnap.data;
          indexData['lastUpdate'] = sendMessageTime;
          GeoPoint dest = new GeoPoint(position.latitude, position.longitude);
          Map<String, GeoPoint> enlargeBox = GeoHelper.enlargeBox(indexData['geotopleft'], indexData['geobottomright'], dest);
          indexData['geotopleft'] = enlargeBox['topLeft'];
          indexData['geobottomright'] = enlargeBox['bottomRight'];
          var chatData = {
                'created': sendMessageTime,
                'id': sendMessageTimeString,
                'geo': new GeoPoint(position.latitude, position.longitude),
                'content': content,
                'type': type
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
