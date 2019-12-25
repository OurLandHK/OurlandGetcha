import 'dart:math';
import 'dart:convert';
import 'package:ourland_native/models/constant.dart';

class Polling {
  int _numOfMaxPolling; // default is 1
  List<String> _pollingOptionValues;
  int _pollingRange; // in km
  String _pollingTitle;
  int _type; // default is 0
  Polling(this._numOfMaxPolling, this._pollingOptionValues, this._pollingRange, this._pollingTitle, this._type) {
  }
  
  int get numOfMaxPolling => this._numOfMaxPolling;
  List<String> get pollingOptionValues => this._pollingOptionValues;
  int get pollingRange => this._pollingRange;
  int get type => this._type;
  String get pollingTitle => this._pollingTitle;

  Polling.fromMap(Map<dynamic, dynamic> map) {
    if(map['type'] != null) {
      _type = map['type'];
    } else {
      _type = 0;
    }
    if(map['numOfMaxPolling'] == null) {
      _numOfMaxPolling = 0;
    } else {
      _numOfMaxPolling = map['numOfMaxPolling']; // default is 1
    }
    _pollingOptionValues = [];
    for(int i = 0; i < map['pollingOptionValues'].length; i++) {
      _pollingOptionValues.add(map['pollingOptionValues'][i]);
    }
    try {
      _pollingRange = map['pollingRange']; // in km
    } catch(exception) {
      _pollingRange = 1;
    }
    _pollingTitle = map['pollingTitle'];    
  }
}

class PollingResult {
  List<int> _upvote;
  DateTime _lastUpdate;

  PollingResult(this._upvote) {
    _lastUpdate = DateTime.now();
  }

  List<int> get upvote => this._upvote;
  DateTime get lastUpdate => this._lastUpdate;

  PollingResult.fromMap(Map<String, dynamic> map) {
    this._lastUpdate = DateTime.fromMicrosecondsSinceEpoch(map['lastUpdate'].microsecondsSinceEpoch);
    _upvote = [];
    for(int i = 0; i< map['upvote'].length; i++) {
      _upvote.add(map['upvote'][i]);
    } 
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['lastUpdate'] = _lastUpdate;
    map['upvote'] = _upvote;
    return map;
  }
}
