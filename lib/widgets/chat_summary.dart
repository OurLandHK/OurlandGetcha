
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
import 'package:ourland_native/services/message_service.dart';
//import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:ourland_native/widgets/rich_link_preview.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

  enum Chat_Mode {
    MAP_MODE,
    USER_MODE,
    MEDIA_MODE,
    CHAT_MODE  
  }

class ChatSummary extends StatefulWidget {
  final ValueListenable<GeoPoint> topLeft;
  final ValueListenable<GeoPoint> bottomRight;
  final Function updateUser;
  final Function getUserName;
  final Function toggleComment;
  final User user;
  final String imageUrl;
  final Topic topic;
  final double height;
  final double width;
  final Chat_Mode chatMode;
//  final bool expand;
  _ChatSummaryState state;

  ChatSummary({Key key, @required this.topLeft, @required this.bottomRight, @required this.width, @required this.height, @required this.user, @required this.imageUrl, @required this.topic, @required this.chatMode, @required this.toggleComment, @required this.updateUser, @required this.getUserName}) : super(key: key);
  @override
  _ChatSummaryState createState() { 
    state = new _ChatSummaryState();
    return state;
  }
}

class _ChatSummaryState extends State<ChatSummary> with SingleTickerProviderStateMixin {
  
  List<String> messageList;
  List<String> galleryImageUrlList;
  List<OurlandMarker> _markerList;
  Map<String, OurlandMarker> _pendingMarkerList;
  Widget _baseInfo;
  Widget _titleLink;
  ImageWidget _summaryImageWidget;
  bool _progressBarActive;
  bool _isFavour = false;
  MessageService messageService;
  ValueNotifier<Stream> chatStream;

  _ChatSummaryState() {
    _progressBarActive = true;
    this._markerList = [];
    this._pendingMarkerList = {};  
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
    messageList = new List<String>();
    galleryImageUrlList = new List<String>();
    print("initState()");
    messageService = new MessageService(widget.user);
    chatStream = new ValueNotifier(this.messageService.getChatSnap(this.widget.topic.id));
    if(widget.imageUrl != null && widget.imageUrl.length != 0) {
      if(isBeginWithLink(widget.topic.topic)) {
        _summaryImageWidget = new ImageWidget(width: (widget.width * 0.9), imageUrl: widget.imageUrl, link: widget.topic.topic);
      } else {
        _summaryImageWidget = new ImageWidget(width: (widget.width * 0.9), imageUrl: widget.imageUrl);
      }
      //mapWidth /= 2;
    }
    // Check title is duplicate with desc
    if(isBeginWithLink(widget.topic.topic) && _summaryImageWidget == null) {
      _titleLink = RichLinkPreview(
          height: widget.height * 0.50,
          link: widget.topic.topic,
          appendToLink: true,
          backgroundColor: TOPIC_COLORS[widget.topic.color],
          textColor: Colors.black,
          launchFromLink: true);
    }
    UserService _userService = new UserService();
    _userService.getRecentTopic(widget.user.uuid, widget.topic.id).then((recentTopicMap) {
      if(recentTopicMap != null) {
        _isFavour = true;
      }
    });
    buildMessageSummaryWidget();
  }

  void addChat(Chat chat) {
    OurlandMarker ourlandMarker = this._pendingMarkerList[chat.createdUser.uuid];
    if(ourlandMarker == null) {
      this._pendingMarkerList[chat.createdUser.uuid] = OurlandMarker(chat.id, chat.geo, chat.type, chat.content, chat.createdUser.username);
    }// Add involved user in the summary;
    widget.updateUser(chat.createdUser);
    addImage(chat.imageUrl);
    addMessage(chat.content);
    setState(() {});
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
//      Stream<QuerySnapshot> stream = widget.chatStream.value;
      Stream<QuerySnapshot> stream = chatStream.value;
      print("stream ${stream.length}");
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
    WidgetsBinding.instance
      .addPostFrameCallback((_) => _swapMap(context));    
    // _cratedDate
    Text _createdDate = Text(
        DateFormat('dd MMM kk:mm').format(
            new DateTime.fromMicrosecondsSinceEpoch(
                widget.topic.created.microsecondsSinceEpoch)),
        style: Theme.of(context).textTheme.subtitle);
    _baseInfo = new Row(children: <Widget>[
      new BaseProfile(user: widget.topic.createdUser), 
      new Column(children: <Widget>[
        _createdDate,
        new Text(LABEL_MUST_SHOW_NAME_SIMPLE + ": " +widget.topic.isShowName.toString(), style: Theme.of(context).textTheme.subtitle),
        ])]); // need to show hash tag
    


    List<Widget> widgetList = [];
    List<Widget> finalWidgetList = [];
    // display Map
    if(widget.chatMode == Chat_Mode.MAP_MODE) {
          print("build Marker Length 2 ${this._markerList.length} ${this._pendingMarkerList.length}");
      if(this._markerList.length == this._pendingMarkerList.length) {
        widgetList.add(ChatMap(topLeft: widget.topLeft.value, bottomRight:  widget.bottomRight.value, width: widget.width, height:  widget.height * 0.95, markerList: this._markerList));
      } else {
        widgetList.add(ChatMap(topLeft: widget.topLeft.value, bottomRight:  widget.bottomRight.value, width: widget.width, height:  widget.height * 0.95, markerList: this._pendingMarkerList.values.toList()));
      }
      if(_titleLink != null) {
        widgetList.add(_titleLink);
      }    
    }
    widgetList.add(_baseInfo);
    // dsiaply Image if the Topic has it's image
    if(widget.chatMode == Chat_Mode.MAP_MODE) {
      if(_summaryImageWidget != null) {
        {
          widgetList.add(_summaryImageWidget);
        }
      }
    }
    // Display the Content for the Topic.
      if(widget.topic.content != null && widget.topic.content.length != 0) {
        Widget _contentText = new Container(child: Text(widget.topic.content,
            style: Theme.of(context).textTheme.body2));
        widgetList.add(_contentText);
    }
    // Display tool bar
    Color favorColor = primaryColor;
    if(this._isFavour) {
      favorColor = Colors.red;
    }
    Row _toolBar = new Row(children: <Widget>[
              Material(
                child: new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 8.0),
                  child: new IconButton(
                    icon: new Icon(Icons.info),
                    onPressed: (() {   
                      widget.toggleComment(Chat_Mode.MAP_MODE);
                    }),
                    color: widget.chatMode == Chat_Mode.MAP_MODE ? primaryColor:greyColor,
                  ),
                ),
                color: TOPIC_COLORS[widget.topic.color],
              ),
              Material(
                child: new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 8.0),
                  child: new IconButton(
                    icon: new Icon(Icons.photo_album),
                    onPressed: (() {   
                      widget.toggleComment(Chat_Mode.MEDIA_MODE);
                    }),
                    color: widget.chatMode == Chat_Mode.MEDIA_MODE ? primaryColor:greyColor,
                  ),
                ),
                color: TOPIC_COLORS[widget.topic.color],
              ),                        // Button send message
              Material(
                child: new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 8.0),
                  child: new IconButton(
                    icon: new Icon(Icons.comment),
                    onPressed: (() {   
                      widget.toggleComment(Chat_Mode.CHAT_MODE);
                    }),
                    color: widget.chatMode == Chat_Mode.CHAT_MODE ? primaryColor:greyColor,
                  ),
                ),
                color: TOPIC_COLORS[widget.topic.color],
              ),
              Expanded(child: Container()),         // Button mark interest to receive notification
              Material(
                child: new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 8.0),
                  child: new IconButton(
                    icon: new Icon(Icons.favorite),
//                    onPressed: () => onSendMessage(textEditingController.text, 0),
                    color: favorColor,
                  ),
                ),
                color: TOPIC_COLORS[widget.topic.color],
              ), ]);
    widgetList.add(_toolBar);
    Widget summaryPostit = Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              padding: EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: TOPIC_COLORS[widget.topic.color],
                border: Border.all(width: 1, color: Colors.grey),
                boxShadow: [
                  new BoxShadow(
                    color: Colors.grey,
                    offset: new Offset(0.0, 2.5),
                    blurRadius: 4.0,
                    spreadRadius: 0.0
                  )
                ],
                //borderRadius: BorderRadius.circular(6.0)
                ),
              child: Column(children: widgetList)
            )); 
    finalWidgetList.add(summaryPostit);
    int colorIndex = widget.topic.color;
    // Display all image in the chat.
    print("galleryImageUrlList ${galleryImageUrlList.length}");
    if(widget.chatMode == Chat_Mode.MEDIA_MODE) {
      galleryImageUrlList.map((imageUrl) {
        colorIndex++;
        colorIndex%=TOPIC_COLORS.length;
        Widget _imageWidget =  new ImageWidget(width: (widget.width * 0.9), imageUrl: imageUrl);
        Widget _imagePostit = Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                padding: EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: TOPIC_COLORS[colorIndex],
                  border: Border.all(width: 1, color: Colors.grey),
                  boxShadow: [
                    new BoxShadow(
                      color: Colors.grey,
                      offset: new Offset(0.0, 2.5),
                      blurRadius: 4.0,
                      spreadRadius: 0.0
                    )
                  ],
                  //borderRadius: BorderRadius.circular(6.0)
                  ),
                child: _imageWidget
              ));
        finalWidgetList.add(_imagePostit);
      });
    }
    return _progressBarActive == true?const LinearProgressIndicator():
      //summaryPostit;
      new Container(child: Column(children: finalWidgetList), color: TOPIC_COLORS[widget.topic.color],);
  }
   void _swapMap(BuildContext context) {
    print("_swapMap Marker Length 2 ${this._markerList.length} ${this._pendingMarkerList.length}");
    if(this._markerList.length != this._pendingMarkerList.length) {
      List<OurlandMarker> tempList = new List<OurlandMarker>();
      for(String key in this._pendingMarkerList.keys) {
        tempList.add(this._pendingMarkerList[key]);
      }
      setState(() {
        this._markerList = tempList;
      });      
    }
  } 
  
}