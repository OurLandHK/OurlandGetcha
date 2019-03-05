
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
  final String imageUrl;
  final double height;
  final double width;
  _ChatSummaryState state;

  ChatSummary({Key key,  @required this.chatStream, @required this.topLeft, @required this.bottomRight, @required this.width, @required this.height, @required this.user, @required this.imageUrl}) : super(key: key);  
  @override
  _ChatSummaryState createState() { 
    state = new _ChatSummaryState();
    return state;
  }
  void addChat(GeoPoint location, String content, String imageUrl, int contentType, User user) {
    state.addChat(location, content, imageUrl, contentType, user);
  }
}

class _ChatSummaryState extends State<ChatSummary> {
  
  List<String> messageList;
  List<User> userList;
  List<String> galleryImageUrlList;
  List<Map<String, dynamic>> markerList;
  ChatMap chatMapWidget;
  ImageWidget summaryImageWidget;
  bool _progressBarActive;

  _ChatSummaryState() {
    _progressBarActive = true;
  }  

  @override
  void initState() {
    super.initState();
    
    messageList = new List<String>();
    userList = new List<User>();
    galleryImageUrlList = new List<String>();
    markerList = new List<Map<String, dynamic>>();
    double mapWidth = widget.width;
    if(widget.imageUrl != null && widget.imageUrl.length != 0) {
      summaryImageWidget = new ImageWidget(width: widget.width/2, height: widget.height, imageUrl: widget.imageUrl);
      mapWidth /= 2;
    }
    chatMapWidget = new ChatMap(topLeft: widget.topLeft.value, bottomRight:  widget.bottomRight.value, width: mapWidth, height:  widget.height);
    buildMessageSummaryWidget();
  }

  void addChat(GeoPoint location, String content, String imageUrl, int contentType, User user) {
    Map<String, dynamic> marker = {'location':location,
                                   'content': content,
                                   'contentType': contentType,
                                   'username': user.username};
                                   print('$content');
    markerList.add(marker);
    // Add involved user in the summary;
    updateUser(user);
    addImage(imageUrl);
    addMessage(content);
    setState(() {});
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
      galleryImageUrlList.add(imageUrl);
    }

  }

  void addMessage(String message) {
    this.messageList.add(message);
  }

  Widget buildSummaryFooter(BuildContext context) {
    List<Widget> widgetList = new List<Widget>();
    print('${this.messageList.length} + " " + ${this.galleryImageUrlList.length} + " " ${this.userList.length}');
    if(messageList.length > 0) {
      print(messageList.first);
      widgetList.add(RichLinkPreview(
              link: messageList.first,
              appendToLink: true,
              backgroundColor: primaryColor,
              borderColor: primaryColor,
              textColor: Colors.white));
    }
    Row rv = new Row(children: widgetList);
    return rv;
  }
  
  @override
  Widget build(BuildContext context) {
    Widget firstRow = this.chatMapWidget;
    if(this.summaryImageWidget != null) {
      firstRow = new Row(children: [this.summaryImageWidget, this.chatMapWidget]);
    }
    if(chatMapWidget != null) {
      chatMapWidget.clearMarkers();
      for(var marker in markerList) {
        chatMapWidget.addLocation(marker['location'], marker['content'], marker['contentType'], marker['username']);
      }
    } 
    return _progressBarActive == true?const CircularProgressIndicator():
      new Column(
        children: [
          firstRow,
          buildSummaryFooter(context),
        ],
      );
      

  }

  buildMessageSummaryWidget() async {
//    for(var stream in widget.chatStream.value {
      Stream<QuerySnapshot> stream = widget.chatStream.value;
      stream.forEach((action){
        for(var entry in action.documents) {
        Map<String, dynamic> document = entry.data;
        GeoPoint location = document['geo'];
        String imageUrl ="";
        if(document['imageUrl'] != null) {
          imageUrl = document['imageUrl'];
        }
        User chatUser = User.fromBasicMap(document['createdUser']);
        addChat(location, document['content'], imageUrl, document['type'], chatUser);
        }
      });
      setState(() {
         _progressBarActive = false;
      });

  }

/*
  buildMessageSummaryWidget() async {
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
    setState(() {});
  }
  */
}