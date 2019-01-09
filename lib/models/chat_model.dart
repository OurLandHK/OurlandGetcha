import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void sendMessage(Position position, String content, int type) {
      print('SendMessage ${position}');
      var chatReference;
      var indexReference;
      var sendMessageTime = DateTime.now();
      String sendMessageTimeString = sendMessageTime.millisecondsSinceEpoch.toString();
      var indexData = {
            'created': sendMessageTime,
            'lastUpdate': sendMessageTime,
            'id': sendMessageTimeString,
            'content': content,
            'type': type,
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
      if(this.parentID.length == 0) {
        indexReference = Firestore.instance
          .collection('index')
          .document(sendMessageTimeString);
        chatReference = Firestore.instance
          .collection('chat')
          .document(sendMessageTimeString).collection("messages").document(sendMessageTimeString);
      } else {
        indexReference = Firestore.instance
          .collection('index')
          .document(this.parentID);
        chatReference = Firestore.instance
          .collection('chat')
          .document(this.parentID).collection("messages").document(sendMessageTimeString);
      }

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(indexReference, indexData);
        await transaction.set(chatReference, chatData);
      });
  }
}

