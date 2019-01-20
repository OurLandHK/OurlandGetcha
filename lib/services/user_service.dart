import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';

final CollectionReference userCollection = Firestore.instance.collection('users');

class UserService {

  Future register(String uuid, String username, File avatarImage, String address) async {
    if(avatarImage != null) {
      return await uploadAvatar(uuid, avatarImage).then((avatarUrl) {
        return createUser(uuid, username, avatarImage, avatarUrl, address);
      });
    } else {
      return await createUser(uuid, username, avatarImage, DEFAULT_AVATAR_IMAGE_PATH, address);
    }
  }

  Future<User> createUser(String uuid, String username, File avatarImage, String avatarUrl, String address) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(userCollection.document());

      DateTime now = new DateTime.now();
      final User user = new User(uuid, username, avatarUrl, address, now, now);
      final Map<String, dynamic> data = user.toMap();
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

  Future<dynamic> userExist(uuid) async{
    final TransactionHandler th = (Transaction tx) async {
      // check if user exists
      QuerySnapshot _query = await userCollection.where("uuid", isEqualTo: uuid).getDocuments();
      // create one if not
      Map<String,dynamic> map = new Map<String,dynamic>();
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
    final StorageReference firebaseStorageRef =  FirebaseStorage.instance.ref().child(imagePath).child(imageFile);
    final StorageUploadTask task = firebaseStorageRef.putFile(avatarImage);
    return await (await task.onComplete).ref.getDownloadURL();
  }

  Future<void> logout() async {
    return FirebaseAuth.instance.signOut();
  }
}
