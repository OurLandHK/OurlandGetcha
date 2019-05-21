import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'dart:math';
import 'package:ourland_native/models/constant.dart';

class Topic {
  String _id;
  bool _isShowGeo;
  bool _isPublic;
  int _color;
  DateTime _lastUpdate;
  DateTime _created;
  User _createdUser;
  String _imageUrl;
  String _searchingId;
  User _lastUpdateUser;
  String _topic;
  String _content;
  List<dynamic> _tags;
  GeoPoint _geobottomright;
  GeoPoint _geotopleft;
  GeoPoint _geocenter;
  double distance;

  Topic(this._isPublic, this._createdUser, this._geobottomright, this._geotopleft, this._geocenter,
    this._imageUrl, this._isShowGeo, this._tags,
    this._topic, this._content, this._color) {
        this._created = DateTime.now();
        this._lastUpdate = this._created;
        this._lastUpdateUser = this._createdUser; 
        this._searchingId = null;
        this.distance = 0;
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
  int get color => _color;
  String get searchingId => _searchingId;
  GeoPoint get geoCenter => (this._geocenter != null)? this._geocenter: GeoHelper.boxCenter(this.geoTopLeft, this.geoBottomRight);
  

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

    if(this._geobottomright != null && this._geotopleft != null) {
      map['geocenter'] = GeoHelper.boxCenter(this._geotopleft, this._geobottomright);
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

    if(this._searchingId != null) {
      map['searchingId'] = this._searchingId;
    }

    if(this._color != null) {
      map['color'] = this._color;
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
    if(map['content'] != null) {
      this._content = map['content'];
    } else {
      this._content = null;
    }
    if(map['searchingId'] != null) {
      this._searchingId = map ['searchingId'];
    } else {
      this._searchingId = null;
    }
    if(map['geocenter'] != null) {
      this._geocenter = map['geocenter'];
    } else {
      this._geocenter = null;
    }
    if(map['color'] != null) {
      this._color = map['color'];
    } else {
      Random rng = new Random();
      this._color = rng.nextInt(TOPIC_COLORS.length);
    }
    this._created = map['created'].toDate();
    this._lastUpdate = map['lastUpdate'].toDate();
    this._isPublic = map['public'];
  }
}