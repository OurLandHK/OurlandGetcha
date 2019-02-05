class User {
  String _uuid;
  String _username;
  String _avatarUrl;
  String _address;
  DateTime _createdAt;
  DateTime _updatedAt;

  User(this._uuid, this._username, this._avatarUrl, this._address, this._createdAt, this._updatedAt);

  User.map(dynamic obj) {
    this._uuid = obj['uuid'];
    this._username = obj['_username'];
    this._avatarUrl = obj['avatarUrl'];
    this._address = obj['address'];
    this._createdAt = obj['createdAt'];
    this._updatedAt = obj['updatedAt'];
  }

  String get uuid => _uuid;
  String get username => _username;
  String get avatarUrl => _avatarUrl;
  String get address => _address;
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

    if (_address != null) {
      map['address'] = _address;
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


  User.fromMap(Map<String, dynamic> map) {
    this._uuid = map['uuid'];
    this._username = map['user'];
    this._avatarUrl = map['avatarUrl'];
    this._address = map['address'];
    this._createdAt = map['createdAt'];
    this._updatedAt = map['updatedAt'];
  }
}