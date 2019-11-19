import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'dart:math';
import 'dart:convert';
import 'package:ourland_native/models/constant.dart';

class Topic {
  String _id;
  bool _isShowName;
  bool _isPublic;
  bool _isGlobalHide;
  int _color;
  DateTime _lastUpdate;
  DateTime _created;
  User _createdUser;
  String _imageUrl;
  String _searchingId;
  SearchingMsg searchingMsg;

  User _lastUpdateUser;
  String _topic;
  String _content;
  List<dynamic> _tags;
  GeoPoint _geobottomright;
  GeoPoint _geotopleft;
  GeoPoint _geocenter;
  double distance;
  int _blockLevel;
  String _blockReason;   // null = unmask, false = mask, true = blocked (can't be unmask)

  Topic(this._isPublic, this._createdUser, this._geobottomright, this._geotopleft, this._geocenter,
    this._imageUrl, this._isShowName, this._tags,
    this._topic, this._content, this._color) {
        this._created = DateTime.now();
        this._lastUpdate = this._created;
        this._lastUpdateUser = this._createdUser; 
        this._searchingId = null;
        this.searchingMsg = null;
        this.distance = 0;
        this._isGlobalHide = false;
        this._id = this._created.millisecondsSinceEpoch.toString();
    }

  String get id => _id;
  String get imageUrl => _imageUrl;
  String get topic => _topic;
  String get content => _content;
//  List<String> get tags => _tags;
  List<String> get tags => _tags.cast<String>();

  GeoPoint get geoBottomRight => _geobottomright;
  GeoPoint get geoTopLeft=> _geotopleft;
  DateTime get lastUpdate => _lastUpdate;
  DateTime get created => _created;
  bool get isShowName => _isShowName;
  User get createdUser => _createdUser;
  User get lastUpdateUser => _lastUpdateUser;
  bool get isPublic => _isPublic;
  bool get isGlobalHide => _isGlobalHide;
  int get blockLevel => _blockLevel;
  int get color => _color;
  String get searchingId => _searchingId;
  String get blockReason => _blockReason;
  GeoPoint get geoCenter => (this._geocenter != null)? this._geocenter: GeoHelper.boxCenter(this.geoTopLeft, this.geoBottomRight);
  

  bool isAddressWithin(GeoPoint address) {
    bool rv = false;
    if(GeoHelper.isGeoPointInBoudingBox(address, geoTopLeft, geoBottomRight)) {
      rv = true;
    } else if(GeoHelper.isGeoPointInBoudingBox(address, geoBottomRight, geoTopLeft)){
      rv = true;
    }
    return rv;
  }

  void block(int blockLevel, String blockReason) {
    this._blockLevel = blockLevel;
    this._blockReason = blockReason;
  }
  
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

    if (this._isShowName != null) {
      map['isShowGeo'] = this._isShowName;
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

    if(this._isGlobalHide != null) {
      map['isGlobalHide'] = this._isGlobalHide;
    }

    if(this._blockLevel != null) {
      map['blockLevel'] = this._blockLevel;
    }

    if(this._blockReason != null) {
      map['blockReason'] = this._blockReason;
    }

    return map;
  }

  Topic.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._imageUrl = map['imageUrl'];
    this._topic = map['topic'];
    this._tags = map['tags'];
    this._isShowName = map['isShowGeo'];
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

    if(map['blockLevel'] != null) {
      this._blockLevel = map['blockLevel'];
    } 

    if(map['blockReason'] != null) {
      this._blockReason = map['blockReason'];
    } 

    if(map['color'] != null) {
      this._color = map['color'];
    } else {
      if(this.created !=null) {
        this._color = this.searchingId.hashCode % TOPIC_COLORS.length;
      } else {
        this._color = (this.geoTopLeft.latitude * 1000).round() % TOPIC_COLORS.length;
      }
    }
    if(map['isGlobalHide'] != null) {
      this._isGlobalHide = map['isGlobalHide'];
    } else {
      this._isGlobalHide = false;
    }
    try {
      this._created = map['created'].toDate();
    } catch(Exception) {
      this._created = map['created'];
    }
    try {
      this._lastUpdate = map['lastUpdate'].toDate();
    } catch(Exception) {
      this._lastUpdate = map['lastUpdate'];
    }
    this._isPublic = map['public'];
  }

  Topic.fromSearchingMsg(SearchingMsg searchingMsg) {
    this._id = searchingMsg.key;
    this.searchingMsg = searchingMsg;
    this._imageUrl = searchingMsg.publicImageURL;
    this._topic = searchingMsg.text;
    this._tags = searchingMsg.tagfilter;
    this._isShowName = true;
    this._geocenter = searchingMsg.geolocation;
    this._geobottomright = new GeoPoint(searchingMsg.geolocation.latitude - 0.0032, searchingMsg.geolocation.longitude + 0.005);
    this._geotopleft = new GeoPoint(searchingMsg.geolocation.latitude + 0.0032, searchingMsg.geolocation.longitude - 0.005);
    this._searchingId = searchingMsg.key;
    this._content = searchingMsg.desc;
    this._color = (searchingMsg.uid.hashCode) % TOPIC_COLORS.length ;
    this._isGlobalHide = searchingMsg.hide;
    this._isPublic = true;
    this.distance = searchingMsg.distance;
    this._created = searchingMsg.createdAt;
    this._lastUpdate = searchingMsg.lastUpdate;
    this._createdUser = User.fromSearchingCreateUser(searchingMsg);
    this._lastUpdateUser = this._createdUser;
  }  
}