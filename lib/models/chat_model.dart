import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/helper/geo_helper.dart';

class Chat {
  String _id;
  int _type;
  DateTime _created;
  User _createdUser;
  String _content;
  String _imageUrl;
  GeoPoint _geo;

  Chat(this._createdUser, this._geo, this._content, this._type) {
        this._created = DateTime.now();
        this._id = this._created.millisecondsSinceEpoch.toString();
    }

  String get id => _id;
  String get content => _content;
  String get imageUrl => _imageUrl;
  GeoPoint get geo => _geo;
  DateTime get created => _created;
  User get createdUser => _createdUser;
  int get type => _type;  

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    if (_id != null) {
      map['id'] = _id;
    }

    if (this._content != null) {
      map['content'] = this._content;
    }

    if (this._geo != null) {
      map['geo'] = this._geo;
    }

    if (this._created != null) {
      map['created'] = this._created;
    }

    if (this._createdUser != null) {
      map['createdUser'] = this._createdUser.toBasicMap();
    }

    if(this._type != null) {
      map['type'] = this._type;
    }

    if(this._imageUrl != null) {
      map['imageUrl'] = this._imageUrl;
    }

    return map;
  }

  Chat.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._type = map['type'];
    this._geo = map['geo'];
    this._createdUser = User.fromBasicMap(map['createdUser']);
    this._created = map['created'].toDate();
    this._content = map['content'];
    if(map['imageUrl'] != null) {
      this._imageUrl = map['imageUrl'];
    }
  }
}

