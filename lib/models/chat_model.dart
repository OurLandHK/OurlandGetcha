import 'dart:async';
import 'dart:io';

import 'package:image/image.dart' as Img;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'package:ourland_native/models/user_model.dart';

class ChatModel {
  String parentID;
  String imageUrl;
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

  void sendTopicMessage(GeoPoint position, String topic, List<String> tags, String content, File imageFile, int type, bool isShowGeo) {
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

  Future uploadFile(File imageFile) async {
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
    String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putData(blob);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
/*      setState(() {
        isLoading = false;
        imageUrl = downloadUrl;
      });
      */
    });
/*    , onError: (err) {
      setState(() {
        isLoading = false;
      });
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(CHAT_FILE_NOT_IMG)));
    });
 */   
  } 
}
