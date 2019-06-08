import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';

final CollectionReference userCollection =
    Firestore.instance.collection('getChatUsers');

class UserService {
  Future register(
      String uuid, String username, File avatarImage) async {
    if (avatarImage != null) {
      return await uploadAvatar(uuid, avatarImage).then((avatarUrl) {
        return createUser(uuid, username, avatarImage, avatarUrl);
      });
    } else {
      return await createUser(
          uuid, username, avatarImage, DEFAULT_AVATAR_IMAGE_PATH);
    }
  }

  Future<User> createUser(String uuid, String username, File avatarImage,
      String avatarUrl) async {
    DateTime now = new DateTime.now();
    final User user =
          new User(uuid, username, avatarUrl, null, null, now, now);
    final Map<String, dynamic> data = user.toMap();
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(userCollection.document(uuid));
      await tx.set(ds.reference, data);
      return data;
    };

    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      if(data.length == mapData.length) {
        return user;
      } else {
        return null;
      }
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Future<void> updateUser(String uuid, var newValues) {
    return getUserMap(uuid).then((Map userMap) {
      newValues.forEach((k, v) {
        userMap[k] = v;
      });
      userMap['updatedAt'] = new DateTime.now();
      return userCollection.document(uuid).updateData(userMap);
    });
  }

  Future<User> updateRecentTopic(String userID, String topicID, GeoPoint messageLocation) 
    async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(userCollection.document(userID).collection('recentTopic').document(topicID));

      DateTime now = new DateTime.now();
      final RecentTopic recentTopic = 
          new RecentTopic(topicID, now, messageLocation);
      final Map<String, dynamic> data = recentTopic.toMap();
      await tx.set(ds.reference, data);
      return data;
    };

    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return User.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Stream<QuerySnapshot> getRecentTopicSnap(String userID) {
    Stream<QuerySnapshot> rv;
    rv = userCollection.document(userID).collection('recentTopic')
          .orderBy('lastUpdate', descending: true)
          .snapshots();
    return rv;
  }

  Future<Map> getRecentTopic(String userID, String topicID) async {
    userCollection.document(userID).collection('recentTopic').document(topicID).get().then((onValue) {
      if (onValue.exists) {
        return onValue.data;
      } else {
        return null;
      }
    });
  }

  Future<Map> getUserMap(String uuid) async {
    var userReference = userCollection.document(uuid);
    return userReference.get().then((onValue) {
      if (onValue.exists) {
        return onValue.data;
      } else {
        return null;
      }
    });
  }

  Future<User> getUser(String uuid) async {
    var userReference = userCollection.document(uuid);
    return userReference.get().then((onValue) {
      if (onValue.exists) {
        User user = User.fromMap(onValue.data);
        return user;
      } else {
        return null;
      }
    });
  }

  Future<dynamic> userExist(uuid) async {
    final TransactionHandler th = (Transaction tx) async {
      // check if user exists
      QuerySnapshot _query =
          await userCollection.where("uuid", isEqualTo: uuid).getDocuments();
      // create one if not
      Map<String, dynamic> map = new Map<String, dynamic>();
      map['userExist'] = _query.documents.length == 1 ? true : false;
      return map;
    };

    return Firestore.instance.runTransaction(th).then((map) {
      return map['userExist'];
    }).catchError((error) {
      print('error: $error');
      return false;
    });
  }

  // Upload Avatar images to firestore
  Future uploadAvatar(uuid, avatarImage) async {
    String imagePath = FIRESTORE_USER_AVATAR_IMG_PATH;
    String imageFile = uuid + JPEG_EXTENSION;
    final StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(imagePath).child(imageFile);
    final StorageUploadTask task = firebaseStorageRef.putFile(avatarImage);
    return await (await task.onComplete).ref.getDownloadURL();
  }

  Future<void> logout() async {
    return FirebaseAuth.instance.signOut();
  }
}
