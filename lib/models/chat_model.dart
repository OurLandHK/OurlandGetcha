import 'dart:async';
import 'dart:io';

import 'package:image/image.dart' as Img;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'package:ourland_native/models/user_model.dart';

/*
class Topic {
  String _id;
  bool _isShowGeo;
  DateTime _lastUpdate;
  DateTime _created;
  User _createdUser;
  String _imageUrl;
  User _lastUpdateUser;
  String _topic;
  String[] _tags;
  GeoPoint _geobottomright;
  GeoPoint _geotopleft;

  Topic(this._created, this._createdUser, this._geobottomright, this._geotopleft,
    this._id, this._imageUrl, this._isShowGeo, this._lastUpdate, this._lastUpdateUser, this._tags,
    this._topic);

  String get id => _id;
  String get imageUrl => _imageUrl;
  String get topic => _topic;
  String[] get tags => _tags;
  GeoPoint get geoBottomRight => _geobottomright;
  GeoPoint get geoTopLeft=> _geotopleft;
  DateTime get lastUpdate => _lastUpdate;
  DateTime get created => _created;
  bool isShowGeo => _isShowGeo;
  User createdUser => _createdUser;
  User lastUpdateUser => _lastUpdateUser;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    if (_id != null) {
      map['id'] = _id;
    }

    if (_imageUrl != null) {
      map['imageUrl'] = _imageUrl;
    }

    if (this._topic != null) {
      map['topic'] = this._topic;
    }

    if (this._tags != null) {
      map['tags'] = this._tags;
    }

    if (this._isShowGeo != null) {
      map['isShowGeo'] = this._isShowGeo;
    }

    if (this._geobottomright != null) {
      map['geobottomright'] = this._geobottomright;
    }

    if (this._geotopleft != null) {
      map['geotopleft'] = this._geotopleft;
    }

    if (this._lastUpdate != null) {
      map['lastUpdate'] = this._lastUpdate;
    }

    if (this._created != null) {
      map['created'] = this._created;
    }

    if (this._createdUser != null) {
      map['createdUser'] = this._createdUser.toBasicMap();
    }
    if (this._lastUpdateUser != null) {
      map['lastUpdateUser'] = this._lastUpdateUser.toBasicMap();
    }

    return map;
  }

  Topic.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._imageUrl = map['imageUrl'];
    this._topic = map['topic'];
    this._tags = map['tags'];
    this._isShowGeo = map['isShowGeo'];
    this._geobottomright = map['geobottomright'];
    this._geotopleft = map['geotopleft'];
    this._createdUser = User.fromBasicMap(map['createdUser']);
    this._lastUpdateUser =  User.fromBasicMap(map['lastUpdateUser']);
    this._created = map['created'].toDate();
    this._lastUpdate = map['lastUpdate'].toDate();
  }
}
*/
class ChatModel {
  String parentID;
  String imageUrl;
  User _user;

  ChatModel(this.parentID, this._user);

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

  Future sendTopicMessage(GeoPoint position, String topic, List<String> tags, String content, File imageFile, int type, bool isShowGeo) async {
    //print('SendMessage ${position}');
    var chatReference;
    var indexReference;
    var sendMessageTime = DateTime.now();
    var basicUserMap = _user.toBasicMap();
    String imageUrl;
    if(imageFile != null) {
      imageUrl = await uploadImage(imageFile);
      if(imageUrl != null) {
      }
    }
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
          'imageUrl' : imageUrl,
    };
    var chatData = {
          'created': sendMessageTime,
          'id': sendMessageTimeString,
          'geo': new GeoPoint(position.latitude, position.longitude),
          'content': content,
//          'imageUrl' : imageUrl,
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
    String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putData(blob);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  } 
}