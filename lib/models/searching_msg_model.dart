import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'dart:math';
import 'dart:convert';
import 'package:ourland_native/models/constant.dart';

class OpenningHours {
  String _open;
  String _close;
  bool _enable;
  OpenningHours(this._enable, this._open, this._close);
  String get open => _open;
  String get close => _close;
  bool get enable => _enable;

  OpenningHours.fromMap(Map<String, dynamic> map) {
    this._open = map['open'];
    this._close = map['close'];
    this._enable = map['enable'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    if (_open != null) {
      map['open'] = _open;
    } else {
      map['open'] = "00:00";
    }
    if (_close != null) {
      map['close'] = _close;
    } else {
      map['close'] = "23:59";
    }
    if (_enable != null) {
      map['enable'] = _enable;
    } else {
      map['enable'] = false;
    }
  }
}

class GalleryEntry {
  String _publicImageURL;
  String _thumbnailPublicImageURL;

  //internal to firestore
  String _imageURL;
  String _thumbnailImageURL;
  String _caption;

  GalleryEntry(this._publicImageURL, this._imageURL, this._thumbnailPublicImageURL, this._thumbnailImageURL, this._caption);
  String get imageURL => this._imageURL;
  String get thumbnalImageURL => this._thumbnailImageURL;
  String get publicImageURL => this._publicImageURL;
  String get thumbnailPublicImageURL => this._thumbnailPublicImageURL;
  String get caption => this._caption;


  GalleryEntry.fromMap(Map<String, dynamic> map) {
    this._publicImageURL = map['publicImageURL'];
    this._thumbnailPublicImageURL = map['thumbnailPublicImageURL']; 
    this._imageURL = map['imageURL'];
    this._thumbnailImageURL = map['thumbnalImageURL'];
    this._caption = map['caption'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    if(this._publicImageURL != null) {
      map['publicImageURL'] = this._publicImageURL;
    } else {
      map['publicImageURL'] = '';
    }
    if(this._thumbnailPublicImageURL != null) {
      map['thumbnailPublicImageURL'] = this._thumbnailPublicImageURL;
    } else {
      map['thumbnailPublicImageURL'] = '';
    }
    if(this._imageURL != null) {
      map['imageURL'] = this._imageURL;
    } else {
      map['imageURL'] = '';
    }
    if(this._publicImageURL != null) {
      map['thumbnailImageURL'] = this._thumbnailImageURL;
    } else {
      map['thumbnailImageURL'] = '';
    }
    if(this._caption != null) {
      map['caption'] = this._caption;
    } else {
      map['captiop'] = '';
    }
  }
  
}            

class SearchingMsg {
  String _key;
  bool _hide; 
  GeoPoint _geolocation;
  String _text;
  DateTime _createdAt;
  DateTime _lastUpdate;
  String _streetAddress;
  String _imageUrl;
  String _publicImageURL;
  String _thumbnailImageURL;
  String _thumbnailPublicImageURL;
  List<GalleryEntry> _gallery;
  String _status;
  int _viewCount;
  bool _isReportedUrgentEvent;
  bool _isApprovedUrgentEvent;
  bool _isUrgentEvent;

  // User
  String _name;
  String _photoUrl;
  String _uid;
  String _fbuid;

  List<String> _tagfilter;
  String _desc;
  DateTime _start;
  String _startTime;
  String _duration;
  String _interval;
  DateTime _endDate;

  OpenningHours _everydayOpenning;
  List<OpenningHours> _weekdaysOpennings;
  String _link;
  List<dynamic> _polling;

  SearchingMsg(this._key, this._geolocation, this._streetAddress, this._text, 
      this._name, this._photoUrl, this._uid, this._fbuid,
      this._tagfilter, this._desc, this._link,
      this._imageUrl, this._publicImageURL, this._thumbnailImageURL, this._thumbnailPublicImageURL, 
      this._start, this._startTime, this._duration, this._interval, this._endDate,
      this._everydayOpenning, this._weekdaysOpennings, this._polling,
      this._gallery) {
    this._hide = false;
    this._viewCount = 0;
    this._status = "開放"; 
    this._isReportedUrgentEvent = false;
    this._isApprovedUrgentEvent = false;
    this._isUrgentEvent = false;
    this._createdAt = DateTime.now();
    this._lastUpdate =  this._createdAt;
  }

  String get key => _key;
  bool get hide => _hide; 
  GeoPoint get geolocation => _geolocation;
  String get text => _text;
  DateTime get createdAt => _createdAt;
  DateTime get lastUpdate => _lastUpdate;
  String get stressAddress => _streetAddress;
  String get imageUrl => _imageUrl;
  String get publicImageURL => _publicImageURL;
  String get thumbnailImageURL => _thumbnailImageURL;
  String get thumbnailPublicImageURL => _thumbnailPublicImageURL;
  List<GalleryEntry> get gallery => _gallery;
  String get status => _status;
  int get viewCount => _viewCount; 
  bool get isReportedUrgentEvent => _isReportedUrgentEvent;
  bool get isApprovedUrgentEvent => _isApprovedUrgentEvent;
  bool get isUrgentEvent => _isUrgentEvent;

  // User
  String get name => _name;
  String get photoUrl => _photoUrl;
  String get uid => _uid;
  String get fbuid => _fbuid;

  List<String> get tagfilter => _tagfilter;
  String get desc => _desc;
  DateTime get start => _start;
  String get startTime => _startTime;
  String get duration => _duration;
  String get interval => _interval;
  DateTime get endDate => _endDate;

  OpenningHours get everydayOpenning => _everydayOpenning;
  List<OpenningHours> get weekdaysOpennings => _weekdaysOpennings;
  String get link => _link;
  List<dynamic> get polling => _polling;


  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['key'] = _key;
    map['hide'] = _hide; 
    map['geolocation'] = _geolocation;
    map['text'] = _text;
    map['createdAt'] = _createdAt;
    map['lastUpdate'] = lastUpdate;
    if(_streetAddress != null){
      map['stressAddress'] = _streetAddress;
    }
    if (_imageUrl != null) {
      map['imageUrl'] = _imageUrl;
    }
    if (_publicImageURL != null) {
      map['publicImageURL'] = _publicImageURL;
    }
    if (_thumbnailImageURL != null) {
      map['thumbnailImageURL'] = _thumbnailImageURL;
    }
    if (_thumbnailPublicImageURL != null) {
      map['thumbnailPublicImageURL'] = _thumbnailPublicImageURL;
    }
    if(_gallery != null && _gallery.length != 0) {
      List<Map> galleryEntryList = new List<Map>();
      for(int i = 0; i < _gallery.length; i++) {
        galleryEntryList.add(_gallery.elementAt(i).toMap());
      }
      map['gallery'] = galleryEntryList;
    }
    map['status'] = _status;
    map['viewCount'] = _viewCount; 
    map['isReportedUrgentEvent'] = _isReportedUrgentEvent;
    map['isApprovedUrgentEvent'] = _isApprovedUrgentEvent;
    map['isUrgentEvent'] = _isUrgentEvent;

    // User
    map['name'] = _name;
    map['photoUrl'] = _photoUrl;
    map['uid'] = _uid;
    map['fbuid'] = _fbuid;

    if(_tagfilter != null) {
      map['tagfilter'] = new Map<String, int>();
      for(int i = 0; i < _tagfilter.length; i++) {
        map['tagfilter'][_tagfilter.elementAt(i)] = 1;
      }
    }
    map['desc'] = _desc;
    map['start'] = _start;
    map['startTime'] = _startTime;
    map['duration'] = _duration;
    map['interval'] = _interval;
    map['endDate'] = _endDate;

    map['everydayOpenning'] = _everydayOpenning;
    if(_weekdaysOpennings != null && _weekdaysOpennings.length != 0) {
      List<Map> entryList = new List<Map>();
      for(int i = 0; i < _gallery.length; i++) {
        entryList.add(_weekdaysOpennings.elementAt(i).toMap());
      }
      map['weekdaysOpennings'] = entryList;
    }
    map['link'] = _link;
    //List<dynamic> get polling => _polling;
    return map;
  }

  SearchingMsg.fromMap(Map<String, dynamic> map) {
    _key = map['key'];
    _hide = map['hide']; 
    _geolocation = map['geolocation'];
    _text = map['text'];
    _createdAt =  DateTime.fromMicrosecondsSinceEpoch(map['createdAt'].microsecondsSinceEpoch);
    _lastUpdate = DateTime.fromMicrosecondsSinceEpoch(map['lastUpdate'].microsecondsSinceEpoch);
    if(map['stressAddress'] != null){
      _streetAddress = map['stressAddress'];
    }
    if (map['imageUrl'] != null) {
       _imageUrl = map['imageUrl'];
    }
    if (map['publicImageURL'] != null) {
       _publicImageURL = map['publicImageURL'];
    }
    if (map['thumbnailImageURL'] != null) {
       _thumbnailImageURL = map['thumbnailImageURL'];
    }
    if (map['thumbnailPublicImageURL'] != null) {
       _thumbnailPublicImageURL = map['thumbnailPublicImageURL'];
    }
    if(map['gallery'] != null && map['gallery'].length != 0) {
      _gallery = new List<GalleryEntry>();
      for(int i = 0; i < map['gallery'].length; i++) {
        Map<String, dynamic> galleryEntry = new Map<String, dynamic>();
        map['gallery'].elementAt(i).forEach((key, value) => {
          galleryEntry[key] = value
        });
        _gallery.add(GalleryEntry.fromMap(galleryEntry));
      }

    }
    _status = map['status'];
    _viewCount = map['viewCount']; 
    if(map['isReportedUrgentEvent'] != null) {
      _isReportedUrgentEvent = map['isReportedUrgentEvent'];
    }
    if(map['isApprovedUrgentEvent'] != null) {
      _isApprovedUrgentEvent = map['isApprovedUrgentEvent'];
    }
    if(map['isUrgentEvent'] != null) {
      _isUrgentEvent = map['isUrgentEvent'];
    }

    // User
    map['name'] = _name;
    map['photoUrl'] = _photoUrl;
    map['uid'] = _uid;
    map['fbuid'] = _fbuid;

    if(map['tagfilter'] != null) {
      _tagfilter = new List<String>();
      map['tagfilter'].forEach((key, valu) => {_tagfilter.add(key)});
    }

    if(map['desc'] != null) {
      _desc = map['desc'];
    }
    if(map['start'] != null) {
      _start = DateTime.fromMicrosecondsSinceEpoch(map['start'].microsecondsSinceEpoch);
    }
    if(map['startTime'] != null) {
      _startTime = map['startTime'];
    }
    if(map['duration'] != null) {
      _duration = map['duration'];
    }
    if(map['interval'] != null) {
      _interval = map['interval'];
    }
    if(map['endDate'] != null) {
      _endDate = DateTime.fromMicrosecondsSinceEpoch(map['endDate'].microsecondsSinceEpoch);
    }
    if(map['link'] != null) {
      _link = map['link'];
    }

    if(map['everydayOpenning'] != null) {
      _everydayOpenning = OpenningHours.fromMap(map['everydayOpenning']);
    }
    if(map['weekdaysOpennings']!= null) {
      _weekdaysOpennings = new List<OpenningHours>();
      map['weekdaysOpennings'].forEach((key, value) => {_weekdaysOpennings.add(OpenningHours.fromMap(value))});
    }
    //List<dynamic> get polling => _polling;
  }
}