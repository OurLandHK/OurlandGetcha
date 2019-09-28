import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firestore_helpers/firestore_helpers.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/polling_model.dart';

final CollectionReference _pollingCollection =
    Firestore.instance.collection('polling');


class PollingService {
  User _user;

  User get user => _user;

  PollingService(this._user);

  Future<PollingResult> getResult(String pollingID) {
    var resultReference = _pollingCollection
            .document(pollingID);
    return resultReference.get().then((onValue) {
      if(onValue.exists) {
        return PollingResult.fromMap(onValue.data);
      } else {
        return null;
      }
    });
  }

  Future<PollingResult> getUserResult(String pollingID, String _userID) {
    if(_userID == null || _userID.length == 0) {
      return null;
    }
    var resultReference = _pollingCollection
            .document(pollingID).collection('userResult').document(_userID);
    return resultReference.get().then((onValue) {
      if(onValue.exists) {
        return PollingResult.fromMap(onValue.data);
      } else {
        return null;
      }
    });
  }  

  Future<void> sendUserPollingResult(String pollingID, PollingResult userResult) async {
      var sendMessageTime = DateTime.now();
      String sendMessageTimeString = sendMessageTime.millisecondsSinceEpoch.toString();
      DocumentReference userResultReference;
      DocumentReference resultReference;
      PollingResult result;
      Map userResultData = userResult.toMap();
      Map resultData = userResultData;
      resultReference = _pollingCollection.document(pollingID);
      return resultReference.get().then((var indexDataSnap) {
        if(indexDataSnap.exists) {
          result = PollingResult.fromMap(indexDataSnap.data);
          resultData = result.toMap();
          for(int i = 0; i < result.upvote.length; i++) {
            resultData['upvote'][i] = result.upvote[i] + userResult.upvote[i];
          }
          resultData['lastUpdate'] = userResultData['lastUpdate'];
        } 
        userResultReference = _pollingCollection.document(pollingID).collection("userResult").document(_user.uuid);
        try{
          return resultReference.setData(resultData).then((var test) {
            return userResultReference.setData(userResultData);
          });
          /*
          print("ID exist ${sendMessageTimeString}.");
          Firestore.instance.runTransaction((transaction) async {
            await transaction.set(indexReference, indexData);
            await transaction.set(chatReference, chatData);
          });         
          */
        } catch (exception) {
          print(exception);
        } 
      });
  }
}