import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/helper/geo_helper.dart';

class Topic {
  String _id;
  bool _isShowGeo;
  bool _isPublic;
  DateTime _lastUpdate;
  DateTime _created;
  User _createdUser;
  String _imageUrl;
  User _lastUpdateUser;
  String _topic;
  String _content;
  List<dynamic> _tags;
  GeoPoint _geobottomright;
  GeoPoint _geotopleft;

  Topic(this._isPublic, this._createdUser, this._geobottomright, this._geotopleft,
    this._imageUrl, this._isShowGeo, this._tags,
    this._topic, this._content) {
        this._created = DateTime.now();
        this._lastUpdate = this._created;
        this._lastUpdateUser = this._createdUser; 
        this._id = this._created.millisecondsSinceEpoch.toString();
    }

  String get id => _id;
  String get imageUrl => _imageUrl;
  String get topic => _topic;
  String get content => _content;
  List<String> get tags => _tags;
  GeoPoint get geoBottomRight => _geobottomright;
  GeoPoint get geoTopLeft=> _geotopleft;
  DateTime get lastUpdate => _lastUpdate;
  DateTime get created => _created;
  bool get isShowGeo => _isShowGeo;
  User get createdUser => _createdUser;
  User get lastUpdateUser => _lastUpdateUser;
  bool get isPublic => _isPublic;

  GeoPoint get geoCenter => 
    GeoHelper.boxCenter(this.geoTopLeft, this.geoBottomRight);
  

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

    if (this._content != null) {
      map['content'] = this._content;
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

    if(this._isPublic != null) {
      map['public'] = this._isPublic;
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
    if(map['lastUpdateUser'] != null) {
      this._lastUpdateUser =  User.fromBasicMap(map['lastUpdateUser']);
    } else {
      this._lastUpdateUser = this._createdUser;
    }
    this._created = map['created'].toDate();
    this._lastUpdate = map['lastUpdate'].toDate();
    this._isPublic = map['public'];
  }
}