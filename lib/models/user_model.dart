import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String _uuid;
  String _username;
  String _avatarUrl;
  GeoPoint _homeAddress;
  GeoPoint _officeAddress;
  DateTime _createdAt;
  DateTime _updatedAt;

  User(this._uuid, this._username, this._avatarUrl, this._homeAddress,
      this._officeAddress, this._createdAt, this._updatedAt);

  User.map(dynamic obj) {
    this._uuid = obj['uuid'];
    this._username = obj['_username'];
    this._avatarUrl = obj['avatarUrl'];
    this._homeAddress = obj['homeAddress'];
    this._createdAt = obj['createdAt'];
    this._updatedAt = obj['updatedAt'];
  }

  String get uuid => _uuid;
  String get username => _username;
  String get avatarUrl => _avatarUrl;
  GeoPoint get homeAddress => _homeAddress;
  GeoPoint get officeAddress => _officeAddress;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;

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
  }



  User.fromMap(Map<String, dynamic> map) {
    this._uuid = map['uuid'];
    this._username = map['user'];
    this._avatarUrl = map['avatarUrl'];
    this._homeAddress = map['homeAddress'];
    this._officeAddress = map['officeAddress'];
    this._createdAt = map['createdAt'].toDate();
    this._updatedAt = map['updatedAt'].toDate();
  }
}
