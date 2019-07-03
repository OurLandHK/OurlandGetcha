import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/chat_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/widgets/chat_message.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class ChatList extends StatelessWidget {
  final ValueListenable<Stream> chatStream; 
  final String parentId;
  final User user;
  final ScrollController listScrollController;
  final Topic topic;
  final Function updateUser;
  final Function getUserName;
  final Function getColor;
  //Map<String, Colors> _colorMap;
  int lastColorIndex = -1;
  var listMessage;
  ChatList({Key key, @required this.chatStream, @required this.parentId, @required this.user, @required this.topic, @required this.listScrollController, @required this.updateUser, @required this.getUserName, @required this.getColor}) : super(key: key) {
    //this._colorMap = new Map<String, Colors>();
  }

  Widget buildItem(Chat document, Function _onTap, BuildContext context) {
    Widget rv;
    updateUser(document.createdUser);
    rv = new ChatMessage(user: user, messageBody: document, color: getColor(document.createdUser.uuid), parentId: this.parentId, messageId: document.id, onTap: _onTap, getUserName: getUserName);
    return rv;
  }
/*
  Colors getColor(User user) {
    if(lastColorIndex == -1) {
      lastColor
    }
  }
*/

  @override
  Widget build(BuildContext context) {
    Map<String, int> colorMap = new Map();
    int lastColorIdx = this.topic.color;
    return Flexible(
      child: StreamBuilder(
              stream: this.chatStream.value,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) {
                        Map<String, dynamic> chatDocument = snapshot.data.documents[index].data;
                        Chat chat = Chat.fromMap(chatDocument);
                        print("${index} ${chat.id}");
                        print("type ${chat.type} ${chat.content} ${chat.imageUrl}");
                        return buildItem(chat, null, context);
                    },
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }
}
