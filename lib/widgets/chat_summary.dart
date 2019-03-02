
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/image_widget.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:ourland_native/models/constant.dart';

class ChatSummary extends StatefulWidget {
  final ValueListenable<Stream> chatStream; 
  final ValueListenable<GeoPoint> topLeft;
  final ValueListenable<GeoPoint> bottomRight;
  final User user;
  final double height;
  final double width;

  ChatSummary({Key key,  @required this.chatStream, @required this.topLeft, @required this.bottomRight, @required this.width, @required this.height, @required this.user}) : super(key: key);  
  @override
  _ChatSummaryState createState() => new _ChatSummaryState();
}

class _ChatSummaryState extends State<ChatSummary> {
  
  List<String> messageList;
  List<User> userList;
  List<String> imageUrlList;
  ChatMap chatMapWidget;
  bool _progressBarActive;

  _ChatSummaryState() {
    _progressBarActive = true;
  }  

  @override
  void initState() {
    super.initState();
    messageList = new List<String>();
    userList = new List<User>();
    imageUrlList = new List<String>();
    chatMapWidget = new ChatMap(topLeft: widget.topLeft.value, bottomRight:  widget.bottomRight.value, height:  widget.height);
    buildMessageSummaryWidget();
    _progressBarActive = false;
  }

  void addChat(GeoPoint location, String content, String imageUrl, int contentType, User user) {    
    if(chatMapWidget != null) {
      chatMapWidget.addLocation(location, content, contentType, user.username);
    } 
    // Add involved user in the summary;
    updateUser(user);
    addImage(imageUrl);
    addMessage(content);
  }

  void updateUser(User user) {
    bool addUser = true;
    userList.map((userObj) {
      print("update User ${user.uuid}  == ${userObj.uuid}");
      if(user.uuid == userObj.uuid) {
        addUser = false;
      }
    });
    if(addUser) {
      this.userList.add(user);
    }
  }

  void addImage(String imageUrl) {
    if(imageUrl.length != 0) {
      imageUrlList.add(imageUrl);
    }

  }

  void addMessage(String message) {
    this.messageList.add(message);
  }

  Widget buildSummaryFooter(BuildContext context) {
    Widget rv = const CircularProgressIndicator();
    RichLinkPreview richList;
    if(messageList.length > 0) {
      print(messageList.first);
      richList = RichLinkPreview(
              link: messageList.first,
              appendToLink: true,
              backgroundColor: primaryColor,
              borderColor: primaryColor,
              textColor: Colors.white);
    }
    print('${this.messageList.length} + " " + ${this.imageUrlList.length} + " " ${this.userList.length}');
    if(imageUrlList.length == 1) {
        print(imageUrlList.first);
        Row row = new Row(children: <Widget>[
          ImageWidget(width: MediaQuery.of(context).size.width/2,height: widget.height, imageUrl: imageUrlList.first),
          richList
        ]);
        rv = row;
    } else {
      if(richList != null) {
        rv = richList;
      }
    }
    return rv;
  }
  
  @override
  Widget build(BuildContext context) {
    return _progressBarActive == true?const CircularProgressIndicator() :
      new Column(
        children: [
          this.chatMapWidget,
          buildSummaryFooter(context),
        ],
      );
  }

  Future buildMessageSummaryWidget() async {
    await for(var stream in widget.chatStream.value) {
      for(var entry in stream.documents) {
        Map<String, dynamic> document = entry.data;
        GeoPoint location = document['geo'];
        String imageUrl ="";
        if(document['imageUrl'] != null) {
          imageUrl = document['imageUrl'];
        }
        User chatUser = User.fromBasicMap(document['createdUser']);
        addChat(location, document['content'], imageUrl, document['type'], chatUser);
      }
    }
  }

    Widget buildMessageSummary(BuildContext context) {
    return Flexible(
      child: StreamBuilder(
              stream: widget.chatStream.value,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  return ListView.builder(
                    //padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) {
                        Map<String, dynamic> document = snapshot.data.documents[index].data;
                        GeoPoint location = document['geo'];
                        String imageUrl ="";
                        if(document['imageUrl'] != null) {
                          imageUrl = document['imageUrl'];
                        }
                        User chatUser = User.fromBasicMap(document['createdUser']);
                        addChat(location, document['content'], imageUrl, document['type'], chatUser);
                        if(index == 0) {
                          return Container();
                        } else {
                          return null;
                        }
                    },
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                  );
                }
              },
            ),
    );
  }
}