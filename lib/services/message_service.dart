import 'dart:async';
import 'dart:io';

import 'package:image/image.dart' as Img;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firestore_helpers/firestore_helpers.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';

final CollectionReference _topicCollection =
    Firestore.instance.collection('topic');

final CollectionReference _chatCollection =
    Firestore.instance.collection('chat');

class MessageService {
  User _user;

  User get user => _user;

  MessageService(this._user);

  Stream<List<Topic>> getTopicSnap(GeoPoint position, double distanceInMeter, String firstTag) {
    Stream<List<Topic>> rv;
    if(position != null) {
      Area area = new Area(position, distanceInMeter/1000);
      rv = getDataInArea(
        source: _topicCollection, 
        area: area, 
        locationFieldNameInDB: 'geocenter',
        mapper: (doc) => Topic.fromMap(doc.data),
        serverSideOrdering: [OrderConstraint('lastUpdate', false)],
        locationAccessor: (item) => item.geoCenter,
          // The distancemapper is applied after the mapper
          distanceMapper: (item, dist) {
              item.distance = dist;
              return item;
          });     
    }  
    return rv;
  }

  

  Future<Topic> getTopic(String topicID) {
    var topicReference = _topicCollection
            .document(topicID);
    return topicReference.get().then((onValue) {
      if(onValue.exists) {
        return Topic.fromMap(onValue.data);
      } else {
        return null;
      }
    });
  }

  Stream<QuerySnapshot> getBroadcastSnap() {
    Stream<QuerySnapshot> rv;
    rv = _topicCollection.where("public", isEqualTo: true)
          .orderBy('lastUpdate', descending: true)
          .snapshots();
    return rv;
  }  

  Stream<QuerySnapshot> getChatSnap(String parentID) {
    Stream<QuerySnapshot> rv;
    rv = _chatCollection.document(parentID)
          .collection("messages")
          .orderBy('created', descending: true)
          .snapshots();
    return rv;
  }  


  Future sendTopicMessage(GeoPoint position, Topic topic, File imageFile) async {
    var chatReference;
    var indexReference;
    String imageUrl;
    if(imageFile != null) {
      imageUrl = await uploadImage(imageFile);
      if(imageUrl != null) {
      }
    }
    
    var indexData = topic.toMap();
    if(imageUrl != null) {
      indexData['imageUrl'] =  imageUrl;
    }
    //indexData['public'] = false;
    String chatText = topic.content;
    if(chatText == null || chatText.length == 0) {
      chatText = topic.topic;
    }
    var chatData = {
          'created': topic.created,
          'id': topic.id,
          'geo': new GeoPoint(position.latitude, position.longitude),
          'content': chatText,
          'type': 0,
          'createdUser' : topic.createdUser.toBasicMap(),
    };
    indexReference = _topicCollection.document(topic.id);
    chatReference = _chatCollection.document(topic.id).collection("messages").document(topic.id);
    try {
    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(indexReference, indexData);
      await transaction.set(chatReference, chatData);
    });          
    } catch (exception) {
      print(exception);
    }
  }

  void sendChildMessage(String parentID, GeoPoint position, String content, int type) {
      var sendMessageTime = DateTime.now();
      String sendMessageTimeString = sendMessageTime.millisecondsSinceEpoch.toString();
      DocumentReference chatReference;
      DocumentReference indexReference;
      indexReference = _topicCollection.document(parentID);
      indexReference.get().then((indexDataSnap) {
        if(indexDataSnap.exists) {
          Topic topic = Topic.fromMap(indexDataSnap.data);
          var basicUserMap = _user.toBasicMap();
          GeoPoint dest = new GeoPoint(position.latitude, position.longitude);

          Map<String, GeoPoint> enlargeBox = GeoHelper.enlargeBox(topic.geoTopLeft, topic.geoBottomRight, dest, 1000);
          Map<String, dynamic> indexData = topic.toMap();
          indexData['geotopleft'] = enlargeBox['topLeft'];
          indexData['geobottomright'] = enlargeBox['bottomRight'];
          indexData['geocenter'] = GeoHelper.boxCenter(enlargeBox['topLeft'], enlargeBox['bottomRight']);
          indexData['lastUpdateUser'] = basicUserMap;
          indexData['lastUpdate'] = sendMessageTime;
          var chatData = {
                'created': sendMessageTime,
                'id': sendMessageTimeString,
                'geo': new GeoPoint(position.latitude, position.longitude),
                'content': content,
                'type': type,
                'createdUser' : basicUserMap,
          };
          chatReference = _chatCollection.document(parentID).collection("messages").document(sendMessageTimeString);
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

  Future<String> uploadImage(File imageFile) async {
    File uploadImage = imageFile;
    List<int> blob = uploadImage.readAsBytesSync();
    
    Img.Image originImage = Img.decodeImage(blob);
    Img.Image image = originImage;

    bool newImage = false;
    if(originImage.width > 1280) {
      image = Img.copyResize(originImage, 1280);
      newImage = true;
    } else {
      if(originImage.height > 1280) {
        int width = (originImage.width * 1280 / originImage.height).round();
        image = Img.copyResize(originImage, width, 1280);  
        newImage = true;     
      }
    }

    if(newImage) {
  //    uploadImage = new File('temp.png').writeAsBytesSync(Img.encodePng(image));
//      blob = new Img.PngEncoder({level: 3}).encodeImage(image);
      blob = new Img.JpegEncoder(quality: 75).encodeImage(image);
    }
    String fileName = 'getCha//' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putData(blob);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  } 
}