import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/constant.dart';

final CollectionReference userCollection = Firestore.instance.collection('users');

class UserService {

  Future<User> createUser(String uuid, String username, File avatarImage, String address) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(userCollection.document());

      QuerySnapshot _query = await userCollection.where("uuid", isEqualTo: uuid).getDocuments();
      
      if(_query.documents.length == 0) {
        String avatarUrl = DEFAULT_AVATAR_IMAGE_PATH;

        if(avatarImage != null) {
          String imagePath = FIRESTORE_USER_AVATAR_IMG_PATH + uuid;
          final StorageReference firebaseStorageRef =  FirebaseStorage.instance.ref().child(imagePath);
          final StorageUploadTask task = firebaseStorageRef.putFile(avatarImage);
          avatarUrl = (await firebaseStorageRef.getDownloadURL()).toString();
        }

        DateTime now = new DateTime.now();
        final User user = new User(uuid, username, avatarUrl, address, now, now);
        final Map<String, dynamic> data = user.toMap();

        await tx.set(ds.reference, data);
        return data;
      } else {
        return _query.documents[0].data;
      }
    };

    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return User.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }
}
