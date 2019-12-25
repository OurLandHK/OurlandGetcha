import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

//import 'package:firestore_helpers/firestore_helpers.dart';
import 'package:ourland_native/models/user_model.dart';

final CollectionReference _rankingCollection =
    Firestore.instance.collection('ranking');


class RankingService {
  User _user;

  User get user => _user;

  RankingService(this._user);

  Future<Map> getRanking(String rankingID) {
    var resultReference = _rankingCollection
            .document(rankingID);
    return resultReference.get().then((onValue) {
      if(onValue.exists) {
        return onValue.data;
      } else {
        return null;
      }
    });
  }

  Future<Map> getLatestUserRanking(String rankingID, String _userID) async {
    if(_userID == null || _userID.length == 0) {
      return null;
    }
    var resultReference = _rankingCollection
            .document(rankingID).collection("userReport").where('userId', isEqualTo: _userID);
    return resultReference.getDocuments().then((onValue) {
      if(onValue.documents.length > 0) {
        Map rv;
        onValue.documents.forEach((userReport) {
          if(rv == null) {
            rv = userReport.data;
          } else {
            if(userReport.data['lastUpdate'].toDate().millisecondsSinceEpoch > rv['lastUpdate'].toDate().millisecondsSinceEpoch) {
              rv = userReport.data;
            }
          }
        });
        return rv;
      } else {
        return null;
      }
    });
  } 

  Future<void> updateRecentRanking(String rankingID, List<String> upFields, List<String> downFields) async {
     var sendMessageTime = DateTime.now();
      DocumentReference summaryReference;
      summaryReference = _rankingCollection.document(rankingID);
      return summaryReference.get().then((var indexDataSnap) {
        Map<String, dynamic> summaryData;
        summaryData = indexDataSnap.data;
        Map recentMap = new Map();
        if(summaryData['recent'] == null || 
          summaryData['recent']['firstUpdate'] != null && (sendMessageTime.millisecondsSinceEpoch - summaryData['recent']['firstUpdate'].millisecondsSinceEpoch) > Duration(days: 120).inMilliseconds)
        {
          return summaryReference.collection("userReport").where('lastUpdate', isGreaterThan: sendMessageTime.subtract(Duration (days: 120))).getDocuments().then((onValue){
            
            DateTime firstUpdate = DateTime.now();
            onValue.documents.forEach((document) {
              DateTime lastUpdate = document['lastUpdate'].toDate();
              if(lastUpdate.millisecondsSinceEpoch < firstUpdate.millisecondsSinceEpoch) {
                firstUpdate = lastUpdate;
              }
              document['upValue'].forEach((field){
                if(recentMap[field] != null) {
                  if(recentMap[field]['value'] != null) {
                    recentMap[field]['value']++;
                  } else {
                    recentMap[field]['value']=1;
                  }
                } else {
                  recentMap[field] = new Map<String, dynamic>();
                  recentMap[field]['value'] = 1;
                  recentMap[field]['field'] = field;  
                  recentMap[field]['lastUpdate'] = sendMessageTime;          
                }  
              });
              document['downValue'].forEach((field){
                if(recentMap[field] != null) {
                  if(recentMap[field]['downValue'] != null) {
                    recentMap[field]['downValue']++;
                  } else {
                    recentMap[field]['downValue'] = 1;
                  }
                } else {
                  recentMap[field] = new Map<String, dynamic>();
                  recentMap[field]['downValue'] = 1;
                  recentMap[field]['field'] = field;  
                  recentMap[field]['lastUpdate'] = sendMessageTime;          
                }  
              });  
              recentMap['firstUpdate'] = firstUpdate;
              summaryData['recent'] = recentMap;
              return summaryReference.setData(summaryData);            
            });
          });
        } else {
          recentMap = summaryData['recent'];
          upFields.forEach((field) {
            if(recentMap[field] != null) {
              if(recentMap[field]['value'] != null) {
                recentMap[field]['value']++;
              } else {
                recentMap[field]['value'] = 1;
              }
            } else {
              recentMap[field] = new Map<String, dynamic>();
              recentMap[field]['value'] = 1;
              recentMap[field]['field'] = field;  
              recentMap[field]['lastUpdate'] = sendMessageTime;          
            }   
          });
          downFields.forEach((field) {
            if(recentMap[field] != null) {
              if(recentMap[field]['downValue'] != null) {
                recentMap[field]['downValue']++;
              } else {
                recentMap[field]['downValue'] = 1;
              }
              recentMap[field]['lastUpdate'] = sendMessageTime;
            } else {
              recentMap[field] = new Map<String, dynamic>();
              recentMap[field]['downValue'] = 1;
              recentMap[field]['field'] = field;        
              recentMap[field]['lastUpdate'] = sendMessageTime;    
            }   
          });
        }
        try{
          summaryData['recent'] = recentMap;
          return summaryReference.setData(summaryData);
        } catch (exception) {
          print(exception);
        } 
      });    
  }

  Future<void> sendUserRankingResult(String rankingID, List<String> upFields, List<String> downFields) async {
      var sendMessageTime = DateTime.now();
      DocumentReference summaryReference;
      summaryReference = _rankingCollection.document(rankingID);
      return summaryReference.get().then((var indexDataSnap) {
        Map<String, dynamic> summaryData;
        if(indexDataSnap.exists) {
          summaryData = indexDataSnap.data;
          upFields.forEach((field) {
            if(summaryData[field] != null) {
              if(summaryData[field]['value'] != null) {
                summaryData[field]['value']++;
              } else {
                summaryData[field]['value'] = 1;
              }
            } else {
              summaryData[field] = new Map<String, dynamic>();
              summaryData[field]['value'] = 1;
              summaryData[field]['field'] = field;  
              summaryData[field]['lastUpdate'] = sendMessageTime;          
            }   
          });
          downFields.forEach((field) {
            if(summaryData[field] != null) {
              if(summaryData[field]['downValue'] != null) {
                summaryData[field]['downValue']++;
              } else {
                summaryData[field]['downValue'] = 1;
              }
              summaryData[field]['lastUpdate'] = sendMessageTime;
            } else {
              summaryData[field] = new Map<String, dynamic>();
              summaryData[field]['downValue'] = 1;
              summaryData[field]['field'] = field;        
              summaryData[field]['lastUpdate'] = sendMessageTime;    
            }   
          });     
        } else {
          summaryData = new Map<String, dynamic>();
          upFields.forEach((field) {
            summaryData[field] = new Map<String, dynamic>();
            summaryData[field]['value'] = 1;
            summaryData[field]['field'] = field;
            summaryData[field]['lastUpdate'] = DateTime.now();       
          }); 
          downFields.forEach((field) {
            summaryData[field] = new Map<String, dynamic>();
            summaryData[field]['downValue'] = 1;
            summaryData[field]['field'] = field;
            summaryData[field]['lastUpdate'] = DateTime.now();         
          });           
        }
        Map<String, dynamic> userRankingEntry = new Map<String, dynamic>();
        userRankingEntry['userId'] = _user.uuid;
        userRankingEntry['upValue'] = upFields;
        userRankingEntry['downValue'] = downFields;
        userRankingEntry['lastUpdate'] = DateTime.now(); 
        try{
          return summaryReference.setData(summaryData).then((var test) {
            return summaryReference.collection("userReport").add(userRankingEntry).then((onValue) {
              return updateRecentRanking(rankingID, upFields, downFields).then((temp) {
                return;
              });
            });
          });
        } catch (exception) {
          print(exception);
        } 
      });
  }
}