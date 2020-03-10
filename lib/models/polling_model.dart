import 'dart:math';
import 'dart:convert';
import 'package:ourland_native/models/constant.dart';

class Polling {
  int numOfMaxPolling; // default is 1
  List<String> pollingOptionValues = [];
  int pollingRange; // in km
  String pollingTitle;
  int type; // default is 0
  Polling({this.numOfMaxPolling = 1, this.pollingOptionValues, this.pollingRange = 1, this.pollingTitle = "", this.type = 0}) {
  }

  bool valid() {
    bool rv = false;
    if(this.pollingTitle.length > 0 && this.numOfMaxPolling > 0 && this.pollingRange > 0 && this.pollingOptionValues.length >= this.numOfMaxPolling) {
      rv = true;
    }
    return rv;
  }

  Polling.fromMap(Map<dynamic, dynamic> map) {
    if(map['type'] != null) {
      type = map['type'];
    } else {
      type = 0;
    }
    if(map['numOfMaxPolling'] == null) {
      numOfMaxPolling = 1;
    } else {
      try{
        numOfMaxPolling = map['numOfMaxPolling']; // default is 1
      } catch(exception) {
        numOfMaxPolling = int.parse(map['numOfMaxPolling']);
      }
    }
    pollingOptionValues = [];
    for(int i = 0; i < map['pollingOptionValues'].length; i++) {
      pollingOptionValues.add(map['pollingOptionValues'][i]);
    }
    try {
      pollingRange = map['pollingRange']; // in km
    } catch(exception) {
      pollingRange = 1;
    }
    pollingTitle = map['pollingTitle'];    
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['type'] = type;
    map['numOfMaxPolling'] = numOfMaxPolling;
    map['pollingOptionValues'] = [];
    for(int i = 0; i < pollingOptionValues.length; i++) {
      map['pollingOptionValues'].add(pollingOptionValues[i]);
    }
    map['pollingRange'] = pollingRange;
    map['pollingTitle'] = pollingTitle;  
    return map;
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
