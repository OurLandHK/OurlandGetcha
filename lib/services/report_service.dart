import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ourland_native/models/user_model.dart';

final CollectionReference _reportCollection =
    Firestore.instance.collection('report');


class ReportService {
  User _user;

  User get user => _user;

  ReportService(this._user);

  Future<Map> getSummary(String topicID) {
    var summaryReference = _reportCollection
            .document(topicID);
    return summaryReference.get().then((onValue) {
      if(onValue.exists) {
        return onValue.data;
      } else {
        return null;
      }
    });
  }

  Future<Map> getUserReport(String topicID, String _userID) {
    if(_userID == null || _userID.length == 0) {
      return null;
    }
    var resultReference = _reportCollection
            .document(topicID).collection('userReport').document(_userID);
    return resultReference.get().then((onValue) {
      if(onValue.exists) {
        return onValue.data;
      } else {
        return null;
      }
    });
  }  

  Future<void> sendUserReportResult(String topicID, String field) async {
      var sendMessageTime = DateTime.now();
      DocumentReference userReportReference;
      DocumentReference summaryReference;
      summaryReference = _reportCollection.document(topicID);
      return summaryReference.get().then((var indexDataSnap) {
        Map<String, dynamic> summaryData;
        if(indexDataSnap.exists) {
          summaryData = indexDataSnap.data;
          summaryData[field]['value']++;
        } else {
          summaryData = new Map<String, dynamic>();
          summaryData[field] = new Map<String, dynamic>();
          summaryData[field]['value'] = 1;
          summaryData[field]['field'] = field;
        }
        summaryData[field]['lastUpdate'] = DateTime.now();
        userReportReference = _reportCollection.document(topicID).collection("userReport").document(_user.uuid);
        try{
          return summaryReference.setData(summaryData).then((var test) {
            return userReportReference.setData(summaryData[field]);
          });
        } catch (exception) {
          print(exception);
        } 
      });
  }
}