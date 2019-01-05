import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/user_model.dart';

final CollectionReference userCollection = Firestore.instance.collection('users');

class UserService {

  Future<User> createUser(String uuid, String username, String avatarUrl, String address) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(userCollection.document());

      QuerySnapshot _query = await userCollection.where("uuid", isEqualTo: uuid).getDocuments();
      
      if(_query.documents.length == 0) {
        final User user = new User(uuid, username, avatarUrl, address);
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
