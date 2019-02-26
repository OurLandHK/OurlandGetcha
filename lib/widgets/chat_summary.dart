
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

  void addMessage(GeoPoint location, String content, String imageUrl, int contentType, User user) {
    if(state.chatMapWidget != null) {
      state.chatMapWidget.addLocation(location, content, contentType, user.username);
    } 
    // Add involved user in the summary;
    bool addUser = true;
    state.userList.map((userObj) {
      if(user.uuid == userObj.uuid) {
        addUser = false;
      }
    });
    if(addUser) {
      state.userList.add(user);
    }
    if(imageUrl.length != 0) {
      state.imageUrlList.add(imageUrl);
    }
    state.messageList.add(content);
    //state.addMessage(content);
  }

  void updateCenter(GeoPoint mapCenter) {
    if(state.chatMapWidget != null) {
      state.chatMapWidget.updateCenter(mapCenter);
    } 
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
/*
  void addMessage(String message) {
    List<String> _messageList = messageList;
    _messageList.add(message);
    this.setState((){messageList = _messageList;});
  }
*/
  void initState() {
    super.initState();
    this.chatMapWidget = new ChatMap(topLeft: this.widget.topLeft, bottomRight: this.widget.bottomRight, height: this.widget.height);
  }

  @override
  Widget build(BuildContext context) {

    Widget rv = this.chatMapWidget;
    RichLinkPreview richList = null;
    if(messageList.length > 0) {
      richList = RichLinkPreview(
              link: messageList.first,
              appendToLink: true,
              backgroundColor: primaryColor,
              borderColor: primaryColor,
              textColor: Colors.white);
    }
    if(rv == null) {
      rv = new CircularProgressIndicator();
    }
    List<Widget> widgets = [rv];
    if(imageUrlList.length == 1) {
      Row row = new Row(children: <Widget>[
        ImageWidget(width: context.size.width/2,height: this.widget.height, imageUrl: imageUrlList.first),
        richList
      ]);
      widgets.add(row);
    } else {
      if(richList != null) {
        widgets.add(richList);
      }
    }
    return new Column(
//      crossAxisAlignment: CrossAxisAlignment.start,
//      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}