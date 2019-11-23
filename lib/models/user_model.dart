import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/searching_msg_model.dart';

class User {
  String _uuid;
  String _username;
  String _avatarUrl;
  String _fcmToken;
  GeoPoint _homeAddress;
  GeoPoint _officeAddress;
  DateTime _createdAt;
  DateTime _updatedAt;
  bool _sendBroadcastRight;
  bool _globalHideRight;
  List<String> _blockUsers;

  User(this._uuid, this._username, this._avatarUrl, this._homeAddress,
      this._officeAddress, this._createdAt, this._updatedAt) {
        this._sendBroadcastRight = false;
        this._globalHideRight = false;
        this._fcmToken = '';
        this._blockUsers = [];
      }
/*
  User.map(dynamic obj) {
    this._uuid = obj['uuid'];
    this._username = obj['_username'];
    this._avatarUrl = obj['avatarUrl'];
    this._homeAddress = obj['homeAddress'];
    this._createdAt = obj['createdAt'];
    this._updatedAt = obj['updatedAt'];
    try {
      this._sendBroadcastRight = obj['sendBroadcastRight'];
      if(this._sendBroadcastRight == null) {
        this._sendBroadcastRight = false;
      }
    } catch (exception) {
      this._sendBroadcastRight = false;
    }
    try {
      this._globalHideRight= obj['globalHideRight'];
      if(this._globalHideRight == null) {
        this._globalHideRight = false;
      }
    } catch (exception) {
      this._globalHideRight = false;
    }    
    try {
      this._fcmToken = obj['fcm'];
      if(this._fcmToken == null) {
        this._fcmToken = "";
      }
    } catch (exception) {
      this._fcmToken = "";
    }
    try {
      this._blockUsers = obj['blockUsers'];
      if(this._blockUsers == null) {
        this._blockUsers = [];
      }
    } catch (exception) {
      this._blockUsers = [];
    }
  }
*/

  String get uuid => _uuid;
  String get username => _username;
  String get avatarUrl => _avatarUrl;
  GeoPoint get homeAddress => _homeAddress;
  GeoPoint get officeAddress => _officeAddress;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;
  String get fcmToken => _fcmToken;
  bool get sendBroadcastRight => _sendBroadcastRight;
  bool get globalHideRight => _globalHideRight;
  List<String> get blockUsers => _blockUsers;

  void setHomeAddress(GeoPoint geoPoint) {
    this._homeAddress = geoPoint;
  }

  void setOfficeAddress(GeoPoint geoPoint) {
    this._officeAddress = geoPoint;
  }

  void addBlockUser(String uuid) {
    if(!this._blockUsers.contains(uuid)) {
      _blockUsers.add(uuid);
    }
  }

  void removeBlockUser(String uuid) {
    if(this._blockUsers.contains(uuid)) {
      _blockUsers.remove(uuid);
    }
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    if (_uuid != null) {
      map['uuid'] = _uuid;
    }

    if (_username != null) {
      map['user'] = _username;
    }

    if (_avatarUrl != null) {
      map['avatarUrl'] = _avatarUrl;
    }

    if (_homeAddress != null) {
      map['homeAddress'] = _homeAddress;
    }

    if (_officeAddress != null) {
      map['officeAddress'] = _officeAddress;
    }

    if (_createdAt != null) {
      map['createdAt'] = _createdAt;
    }

    if (_updatedAt != null) {
      map['updatedAt'] = _updatedAt;
    }

    if(_sendBroadcastRight != null) {
      map['sendBroadcastRight'] = _sendBroadcastRight;
    }

    if(_globalHideRight != null) {
      map['globalHideRight'] = _globalHideRight;
    }

    if(_fcmToken != '') {
     map['fcmToken'] = _fcmToken; 
    }

    if(_blockUsers.length > 0 ) {
      map['blockUsers'] = _blockUsers;
    }

    return map;
  }

  Map<String, dynamic> toBasicMap() {
    var map = new Map<String, dynamic>();
    if (_uuid != null) {
      map['uuid'] = _uuid;
    }

    if (_username != null) {
      map['user'] = _username;
    }

    if (_avatarUrl != null) {
      map['avatarUrl'] = _avatarUrl;
    }
    return map;
  }

  User.fromBasicMap(Map<dynamic, dynamic> map) {
    this._uuid = map['uuid'];
    this._username = map['user'];
    this._avatarUrl = map['avatarUrl'];
    this._homeAddress = null;
    this._officeAddress = null;
    this._createdAt = DateTime.now();
    this._updatedAt = this._createdAt;
    this._fcmToken = '';
  }

  User.fromSearchingCreateUser(SearchingMsg searchingMsg) {
    this._uuid = searchingMsg.fbuid;
    this._username = searchingMsg.name;
    this._avatarUrl = searchingMsg.photoUrl;
    this._homeAddress = null;
    this._officeAddress = null;
    this._createdAt = DateTime.now();
    this._updatedAt = this._createdAt;
    this._fcmToken = '';   
  }


  User.fromMap(Map<String, dynamic> map) {
    this._uuid = map['uuid'];
    this._username = map['user'];
    this._avatarUrl = map['avatarUrl'];
    this._homeAddress = map['homeAddress'];
    this._officeAddress = map['officeAddress'];
    if(map['createdAt'] != null) {
      this._createdAt = map['createdAt'].toDate();
    } else {
      this._createdAt = DateTime.now();
    }
    if(map['updatedAt'] != null) {
      this._updatedAt = map['updatedAt'].toDate();
    } else {
      this._updatedAt = DateTime.now();
    }
    try {
      if(map['sendBroadcastRight'] == null) {
        this._sendBroadcastRight = false;
      } else {
        this._sendBroadcastRight = map['sendBroadcastRight'];
      }
    } catch (exception) {
      this._sendBroadcastRight = false;
    }

    try {
      if(map['globalHideRight'] == null) {
        this._globalHideRight = false;
      } else {
        this._globalHideRight = map['globalHideRight'];
      }
    } catch (exception) {
      this._globalHideRight = false;
    }
    
    try {
      if(map['fcmToken'] == null) {
        this._fcmToken = '';
      } else {
        this._fcmToken = map['fcmToken'];
      }
    } catch (exception) {
      this._fcmToken = '';
    }
    try {
      List<dynamic> tmp = map['blockUsers'];
      if(tmp == null) {
        this._blockUsers = [];
      } else {
        this._blockUsers = tmp.cast<String>().toList();
      }
    } catch (exception) {
      this._blockUsers = [];
    }
  }
}

class RecentTopic {
  String _id;
  DateTime _lastUpdate;
  GeoPoint _messageLocation;
  bool _interest;

  RecentTopic(this._id, this._lastUpdate, this._messageLocation, this._interest);

  String get id => _id;
  DateTime get lastUpdate => _lastUpdate;
  GeoPoint get messageLocation => _messageLocation;
  bool get interest => _interest;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    if (_id != null) {
      map['id'] = _id;
    }

    if (this._messageLocation != null) {
      map['messageLocation'] = this._messageLocation;
    }

    if (this._lastUpdate != null) {
      map['lastUpdate'] = this._lastUpdate;
    }

    if (this._interest != null) {
      map['interest'] = this._interest;
    }

    return map;
  }

  RecentTopic.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._messageLocation = map['messageLocation'];
    if(map['lastUpdate'] != null) {
      this._lastUpdate = map['lastUpdate'].toDate();
    } else {
      this._lastUpdate = DateTime.now();
    }
    if(map['interest'] == null) {
      this._interest = true;
    } else {
      this._interest = map['interest'];
    }
  }
}

