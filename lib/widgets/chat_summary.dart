
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/image_widget.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:ourland_native/models/constant.dart';

class ChatSummary extends StatefulWidget {
  GeoPoint topLeft;
  GeoPoint bottomRight;
  final double height;
  final double width;
  _ChatSummaryState state;



  ChatSummary({Key key,  @required GeoPoint this.topLeft, @required GeoPoint this.bottomRight, @required this.width, @required this.height}) : super(key: key) {
  }  

  Future<void> addMessage(GeoPoint location, String content, String imageUrl, int contentType, User user) async {
    if(state.chatMapWidget != null) {
      state.chatMapWidget.addLocation(location, content, contentType, user.username);
    } 
    // Add involved user in the summary;
    state.updateUser(user);
    state.addImage(imageUrl);
    state.addMessage(content);
  }

  void cleanUp() {
    state.cleanUp();
  }

  void updateCenter(GeoPoint mapCenter) {
    if(state.chatMapWidget != null) {
      state.chatMapWidget.updateCenter(mapCenter);
    }
    cleanUp();
  }

  @override
  _ChatSummaryState createState() {
    state = new _ChatSummaryState();
    return state;
  }
}


class _ChatSummaryState extends State<ChatSummary> {
  List<String> messageList;
  List<User> userList;
  List<String> imageUrlList;
  ChatMap chatMapWidget;
  
  @override
  _ChatSummaryState({Key key}){
    messageList = new List<String>();
    userList = new List<User>();
    imageUrlList = new List<String>();
  }

  void cleanUp() {
    setState(() {
      messageList = new List<String>();
      userList = new List<User>();
      imageUrlList = new List<String>();
    });
  }

  void initState() {
    super.initState();
    this.chatMapWidget = new ChatMap(topLeft: this.widget.topLeft, bottomRight: this.widget.bottomRight, height: this.widget.height);
  }

  void updateUser(User user) {
    bool addUser = true;
    userList.map((userObj) {
      if(user.uuid == userObj.uuid) {
        addUser = false;
      }
    });
    if(addUser) {
      List<User> tempUserList = userList;
      tempUserList.add(user);
  //    setState(() {
       this.userList = tempUserList; 
  //    });
      print('User ${this.messageList.length} + " " + ${this.imageUrlList.length} + " " ${this.userList.length}');

    }
  }

  void addImage(String imageUrl) {
    if(imageUrl.length != 0) {
      List<String> tempImageUrlList = imageUrlList;      
      tempImageUrlList.add(imageUrl);
  //    setState(() {
        this.imageUrlList =tempImageUrlList;
  //    });
    print('Iamge ${this.messageList.length} + " " + ${this.imageUrlList.length} + " " ${this.userList.length}');

    }

  }

  void addMessage(String message) {
    List<String> tempMessageList = messageList;
    tempMessageList.add(message);
 //   setState(() {
      this.messageList =tempMessageList;
 //   });
     print('Message ${this.messageList.length} + " " + ${this.imageUrlList.length} + " " ${this.userList.length}');

  }
  
  @override
  Widget build(BuildContext context) {
    Widget rv = this.chatMapWidget;
    if(rv == null) {
      rv = new CircularProgressIndicator();
    }
    
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
    
    List<Widget> widgets = [rv];
    print('${this.messageList.length} + " " + ${this.imageUrlList.length} + " " ${this.userList.length}');
    if(imageUrlList.length == 1) {
      print(imageUrlList.first);
      Row row = new Row(children: <Widget>[
        ImageWidget(width: context.size.width/2,height: this.widget.height, imageUrl: imageUrlList.first),
//        richList
      ]);
      widgets.add(row);
    } else {
      /*
      if(richList != null) {
        widgets.add(richList);
      }
      */
    }
    return new Column(
//      crossAxisAlignment: CrossAxisAlignment.start,
//      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}