import 'package:cloud_firestore/cloud_firestore.dart';

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

  User(this._uuid, this._username, this._avatarUrl, this._homeAddress,
      this._officeAddress, this._createdAt, this._updatedAt) {
        this._sendBroadcastRight = false;
        this._fcmToken = '';
      }

  User.map(dynamic obj) {
    this._uuid = obj['uuid'];
    this._username = obj['_username'];
    this._avatarUrl = obj['avatarUrl'];
    this._homeAddress = obj['homeAddress'];
    this._createdAt = obj['createdAt'];
    this._updatedAt = obj['updatedAt'];
    try {
      this._sendBroadcastRight = obj['sendBroadcastRight'];
    } catch (exception) {
      this._sendBroadcastRight = false;
    }
    try {
      this._fcmToken = obj['fcm'];
    } catch (exception) {
      this._fcmToken = "";
    }
  }

  String get uuid => _uuid;
  String get username => _username;
  String get avatarUrl => _avatarUrl;
  GeoPoint get homeAddress => _homeAddress;
  GeoPoint get officeAddress => _officeAddress;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;
  String get fcmToken => _fcmToken;
  bool get sendBroadcastRight => _sendBroadcastRight;

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

    if(_fcmToken != '') {
     map['fcmToken'] = _fcmToken; 
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



  User.fromMap(Map<String, dynamic> map) {
    this._uuid = map['uuid'];
    this._username = map['user'];
    this._avatarUrl = map['avatarUrl'];
    this._homeAddress = map['homeAddress'];
    this._officeAddress = map['officeAddress'];
    this._createdAt = map['createdAt'].toDate();
    this._updatedAt = map['updatedAt'].toDate();
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
      if(map['fcmToken'] == null) {
        this._fcmToken = '';
      } else {
        this._fcmToken = map['fcmToken'];
      }
    } catch (exception) {
      this._fcmToken = '';
    }
  }
}

class RecentTopic {
  String _id;
  DateTime _lastUpdate;
  GeoPoint _messageLocation;

  RecentTopic(this._id, this._lastUpdate, this._messageLocation);

  String get id => _id;
  DateTime get lastUpdate => _lastUpdate;
  GeoPoint get messageLocation => _messageLocation;

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

    return map;
  }

  RecentTopic.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._messageLocation = map['messageLocation'];
    this._lastUpdate = map['lastUpdate'].toDate();
  }
}

