
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/chat_model.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/image_widget.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ChatSummary extends StatefulWidget {
  final ValueListenable<Stream> chatStream; 
  final ValueListenable<GeoPoint> topLeft;
  final ValueListenable<GeoPoint> bottomRight;
  final User user;
  final String imageUrl;
  final Topic topic;
  final double height;
  final double width;
  _ChatSummaryState state;

  ChatSummary({Key key,  @required this.chatStream, @required this.topLeft, @required this.bottomRight, @required this.width, @required this.height, @required this.user, @required this.imageUrl, @required this.topic}) : super(key: key);
  @override
  _ChatSummaryState createState() { 
    state = new _ChatSummaryState();
    return state;
  }
}

class _ChatSummaryState extends State<ChatSummary> with SingleTickerProviderStateMixin {
  
  List<String> messageList;
  List<User> userList;
  List<String> galleryImageUrlList;
  List<Map<String, dynamic>> markerList;
  List<Widget> _tabViews;
  ChatMap chatMapWidget;
  ImageWidget summaryImageWidget;
  bool _progressBarActive;
  int _currentIndex;

  _ChatSummaryState() {
    _progressBarActive = true;
  }  

  bool isBeginWithLink(String iv) {
    if(iv != null) {
      return iv.startsWith("http");
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabViews = new List<Widget>();
    messageList = new List<String>();
    userList = new List<User>();
    galleryImageUrlList = new List<String>();
    markerList = new List<Map<String, dynamic>>();
    double mapWidth = widget.width;

    if(widget.imageUrl != null && widget.imageUrl.length != 0) {
      summaryImageWidget = new ImageWidget(width: null /*widget.width/2*/, height: widget.height, imageUrl: widget.imageUrl);
      //mapWidth /= 2;
      _tabViews.add(summaryImageWidget);
    }

    if(widget.topic != null) {
      // Check title is duplicate with desc
      if(isBeginWithLink(widget.topic.topic)) {
        _tabViews.add(RichLinkPreview(
            link: widget.topic.topic,
            appendToLink: true,
            backgroundColor: greyColor2,
            borderColor: greyColor2,
            textColor: Colors.black,
            launchFromLink: true));
      }
      if(widget.topic.topic.compareTo(widget.topic.content) != 0) {
        if(widget.topic.content.length != 0) {
          if(isBeginWithLink(widget.topic.content)) {
            _tabViews.add(Container(
              child:RichLinkPreview(
                  link: widget.topic.content,
                  appendToLink: true,
                  backgroundColor: greyColor2,
                  borderColor: greyColor2,
                  textColor: Colors.black,
                  launchFromLink: true),
              alignment: Alignment.center));
          } else {
            _tabViews.add(
                new Scrollbar(child: new SingleChildScrollView(
                  child: Text(widget.topic.content))));
          } 
        }
      } 
    }    

    chatMapWidget = new ChatMap(topLeft: widget.topLeft.value, bottomRight:  widget.bottomRight.value, width: mapWidth, height:  widget.height);
    _tabViews.add(chatMapWidget);
  
    buildMessageSummaryWidget();
  }

  void addChat(Chat chat) {
    Map<String, dynamic> marker = {'id': chat.id,
                                   'location':chat.geo,
                                   'content': chat.content,
                                   'contentType': chat.type,
                                   'username': chat.createdUser.username};
    //markerList.add(marker);
    chatMapWidget.addLocation(marker['id'], marker['location'], marker['content'], marker['contentType'], marker['username']);

    // Add involved user in the summary;
    updateUser(chat.createdUser);
    addImage(chat.imageUrl);
    addMessage(chat.content);
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

  List<T> map<T>(List list, Function handler) {
  List<T> result = [];
  for (var i = 0; i < list.length; i++) {
    result.add(handler(i, list[i]));
  }

  return result;
}
  
  @override
  Widget build(BuildContext context) {
    return _progressBarActive == true?const LinearProgressIndicator():
    Stack(
      children: [
        CarouselSlider(
          height: widget.height,
          enlargeCenterPage: true,
          items: _tabViews.map((i) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.amber
                  ),
                  child: i,
                );
              },
            );
          }).toList(),
          viewportFraction: 0.95,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: map<Widget>(_tabViews, (index, url) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index ? Color.fromRGBO(0, 0, 0, 0.9) : Color.fromRGBO(0, 0, 0, 0.4)
                ),
              );
            }),
          )
        )
      ]); 
  }

  buildMessageSummaryWidget() async {
//    for(var stream in widget.chatStream.value {
      Stream<QuerySnapshot> stream = widget.chatStream.value;
      stream.forEach((action){
        for(var entry in action.documents) {
          Map<String, dynamic> document = entry.data;
          Chat chat = Chat.fromMap(document);
          addChat(chat);
        }
      });
      setState(() {
         _progressBarActive = false;
      });

  }
}