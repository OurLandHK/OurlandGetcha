
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/chat_model.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/image_widget.dart';
import 'package:ourland_native/widgets/base_profile.dart';
import 'package:ourland_native/models/user_model.dart';
//import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:ourland_native/widgets/rich_link_preview.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

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
  Widget _titleLink;
  Widget _contentLink;
  ChatMap _chatMapWidget;
  ImageWidget _summaryImageWidget;
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

    List<Widget> summaryInfoWidgets = new List<Widget>();
    if(widget.imageUrl != null && widget.imageUrl.length != 0) {
      if(isBeginWithLink(widget.topic.topic)) {
        _summaryImageWidget = new ImageWidget(width: null /*widget.width/2*/, height: widget.height, imageUrl: widget.imageUrl, link: widget.topic.topic);
      } else {
        _summaryImageWidget = new ImageWidget(width: null /*widget.width/2*/, height: widget.height, imageUrl: widget.imageUrl);
      }
      //mapWidth /= 2;
    }
    Text createdDate = Text(
        DateFormat('dd MMM kk:mm').format(
            new DateTime.fromMicrosecondsSinceEpoch(
                widget.topic.created.microsecondsSinceEpoch)),
        style: TextStyle(
            color: greyColor, fontSize: 12.0, fontStyle: FontStyle.italic),
    );
    Widget baseInfo = new Column(children: <Widget>[
      new BaseProfile(user: widget.topic.createdUser),
      createdDate,
      new Text(LABEL_MUST_SHOW_NAME_SIMPLE + ": " +widget.topic.isShowGeo.toString()),
    ], crossAxisAlignment: CrossAxisAlignment.start,); // need to show hash tag
    
    // Check title is duplicate with desc
    if(isBeginWithLink(widget.topic.topic) && _summaryImageWidget == null) {
      _titleLink = RichLinkPreview(
          height: widget.height * 0.50,
          link: widget.topic.topic,
          appendToLink: true,
          backgroundColor: TOPIC_COLORS[widget.topic.color],
//          borderColor: greyColor2,
          textColor: Colors.black,
          launchFromLink: true);
    }
    if(_summaryImageWidget != null) {
      summaryInfoWidgets = [_summaryImageWidget, baseInfo];
      _tabViews.add(SizedBox(height: widget.height, child: new Row(children: summaryInfoWidgets)));
      if(_titleLink != null) {
        _tabViews.add(_titleLink);
      }
    } else {
        if(_titleLink != null) {
        _tabViews.add(_titleLink);
      }
      _tabViews.add(SizedBox(height: widget.height, child: baseInfo));
    }
    if(widget.topic.topic.compareTo(widget.topic.content) != 0) {
      if(widget.topic.content.length != 0) {
        if(isBeginWithLink(widget.topic.content)) {
          _contentLink = RichLinkPreview(
                //height: widget.height * 0.90,
                link: widget.topic.content,
                appendToLink: true,
                backgroundColor: greyColor2,
                borderColor: greyColor2,
                textColor: Colors.black,
                launchFromLink: true);
          _tabViews.add(Container(
                  child: _contentLink,
                  alignment: Alignment.center));

        } else {

          _tabViews.add(
              new Scrollbar(child: 
              new SingleChildScrollView(
                child:  Column(children: <Widget>[
                        Text(LABEL_DETAIL, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.0), textAlign: TextAlign.left,),
                        Text(widget.topic.content, textAlign: TextAlign.left)], crossAxisAlignment: CrossAxisAlignment.start,))));

        } 
      }
    }   

    _chatMapWidget = new ChatMap(topLeft: widget.topLeft.value, bottomRight:  widget.bottomRight.value, width: mapWidth, height:  widget.height * 0.95);
    _tabViews.add(_chatMapWidget);
  
    buildMessageSummaryWidget();
  }

  void addChat(Chat chat) {
    Map<String, dynamic> marker = {'id': chat.id,
                                   'location':chat.geo,
                                   'content': chat.content,
                                   'contentType': chat.type,
                                   'username': chat.createdUser.username};
    //markerList.add(marker);
    _chatMapWidget.addLocation(marker['id'], marker['location'], marker['content'], marker['contentType'], marker['username']);

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
    if(imageUrl != null && imageUrl.length != 0) {
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
  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [];
    if(_chatMapWidget != null) {
      widgetList.add(_chatMapWidget);
    } else {
      widgetList.add(new Container(height: widget.height));
    }
    if(_titleLink != null) {
      widgetList.add(_titleLink);
    }    
    if(_summaryImageWidget != null) {
      if(widget.topic.content.length != 0) {
        Row row;
        if(_contentLink != null) {
          row = new Row(children: [_summaryImageWidget, _contentLink]);          
        } else {
          Widget _contentText = new Container(child: Text(widget.topic.content,
             style: Theme.of(context).textTheme.body2));
          row = new Row(children: [_summaryImageWidget, _contentText]); 
        }
        widgetList.add(row);
      } else {
        widgetList.add(_summaryImageWidget);
      }
    } else {
      if(_contentLink != null) {
        widgetList.add(_contentLink);
      } else {
        if(widget.topic.content != null && widget.topic.content.length != 0) {
          Widget _contentText = new Container(child: Text(widget.topic.content,
             style: Theme.of(context).textTheme.body2));
          widgetList.add(_contentText);
        }
      }
    }
    return _progressBarActive == true?const LinearProgressIndicator():
      Column(children: widgetList);
  }




/*  
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


*/  
}