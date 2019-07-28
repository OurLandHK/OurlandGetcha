
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
import 'package:intl/intl.dart';

  enum Chat_Mode {
    MAP_MODE,
    USER_MODE,
    MEDIA_MODE,
    COMMENT_MODE  
  }

class ChatSummary extends StatefulWidget {
  final ValueListenable<GeoPoint> topLeft;
  final ValueListenable<GeoPoint> bottomRight;
  final GeoPoint messageLocation;
  final Function updateUser;
  final Function getUserName;
  final Function getAllUserList;
  final Function getColor;
  final Function toggleComment;
  final User user;
  final String imageUrl;
  Topic topic;
  final double height;
  final double width;
  final Chat_Mode chatMode;
//  final bool expand;
  _ChatSummaryState state;

  ChatSummary({Key key, @required this.topLeft, @required this.bottomRight, @required this.width, @required this.height, @required this.user, @required this.imageUrl, @required this.topic, @required this.messageLocation, @required this.chatMode, @required this.toggleComment, @required this.updateUser, @required this.getUserName, @required this.getAllUserList, @required this.getColor}) : super(key: key);
  @override
  _ChatSummaryState createState() { 
    state = new _ChatSummaryState();
    return state;
  }
}

class _ChatSummaryState extends State<ChatSummary> with SingleTickerProviderStateMixin {
  
  List<String> messageList;
  Map<String, String> _galleryImageUrlList;
  List<OurlandMarker> _markerList;
  UserService _userService;
  Map<String, OurlandMarker> _pendingMarkerList;
  Widget _baseInfo;
  Widget _titleLink;
  ImageWidget _summaryImageWidget;
  bool _progressBarActive;
  bool _isBookmark = false;
  MessageService messageService;
  ValueNotifier<Stream> chatStream;

  _ChatSummaryState() {
    _progressBarActive = true;
    this._markerList = [];
    _userService = new UserService();
    this._pendingMarkerList = {}; 
    this._galleryImageUrlList = {};
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
    buildMessageSummaryWidget();
  }

  void addChat(Chat chat) {
    OurlandMarker ourlandMarker = this._pendingMarkerList[chat.createdUser.uuid];
    if(ourlandMarker == null) {
      this._pendingMarkerList[chat.createdUser.uuid] = OurlandMarker(chat.id, chat.geo, chat.type, chat.content, chat.createdUser.username);
    }// Add involved user in the summary;
    widget.updateUser(chat.createdUser);
    _addImage(chat);
    addMessage(chat.content);
  }

  void _addImage(Chat chat) {
    if(_galleryImageUrlList[chat.id] == null) {
      String imageUrl;
      if(chat.type == 1) {
        imageUrl = chat.content;
      } else {
        imageUrl = chat.imageUrl;
      }
      if(imageUrl != null && imageUrl.length != 0) {
        _galleryImageUrlList[chat.id] = imageUrl;
      }
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
  Future<User> updateBookmark(bool newState) async  {
    return _userService.updateRecentTopic(widget.user.uuid, widget.topic.id, widget.messageLocation, newState).then((User temp){
      setState(() {
        _isBookmark = newState; 
      });
      return(temp);
    });
  }

  Future updateVisible(bool newState) async {
    int type = 4; // Hide
    String content = MESSAGE_HIDE; 
    if(newState) {
      type = 5; //visible
      content = MESSAGE_SHOW; 
    }
    await messageService.sendChildMessage(widget.topic.id, widget.messageLocation, content, null, type);
    return _userService.addRecentTopic(messageService.user.uuid, widget.topic.id, widget.messageLocation).then((User temp1) {
        Map topicMap = widget.topic.toMap();
        topicMap['isGlobalHide'] = !newState;
        setState(() {
          widget.topic = Topic.fromMap(topicMap);
        }); 
        return temp1;
      });
  }

  buildMessageSummaryWidget() async {
    if(widget.user != null) {
    _userService.getRecentTopic(widget.user.uuid, widget.topic.id).then((recentTopic) {
      if(recentTopic != null) {
        print("recentTopic ${recentTopic.interest}");
        if(_isBookmark != recentTopic.interest) {
          setState(() {
            _isBookmark = recentTopic.interest;
          });
        }
      } else {
        print("recentTopic is null");
      }
      _buildMessageSummaryWidget();
    });
   } else {
     _buildMessageSummaryWidget();
   }
  }
  void _buildMessageSummaryWidget() {
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
    Icon icon = Icon(Icons.visibility);
    Icon hideIconButton = Icon(Icons.visibility_off);
    if(widget.topic.isGlobalHide) {
      icon = Icon(Icons.visibility_off);
      hideIconButton = Icon(Icons.visibility);
    }
    Material hideIcon = Material(child: new Container(
        margin: new EdgeInsets.symmetric(horizontal: 8.0),
        child: new IconButton(
          icon: icon,
          color: primaryColor,
        ),
      ),
      color: TOPIC_COLORS[widget.topic.color]);

    Text _createdDate = Text(
        DateFormat('dd MMM kk:mm').format(
            new DateTime.fromMicrosecondsSinceEpoch(
                widget.topic.created.microsecondsSinceEpoch)),
        style: Theme.of(context).textTheme.subtitle);
    _baseInfo = new Row(children: <Widget>[
      new BaseProfile(user: widget.topic.createdUser), 
      hideIcon,
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
    Color bookmarkColor = primaryColor;
    if(this._isBookmark) {
      bookmarkColor = Colors.red;
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
                    icon: new Icon(Icons.people),
                    onPressed: (() {   
                      widget.toggleComment(Chat_Mode.USER_MODE);
                    }),
                    color: widget.chatMode == Chat_Mode.USER_MODE ? primaryColor:greyColor,
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
                      widget.toggleComment(Chat_Mode.COMMENT_MODE);
                    }),
                    color: widget.chatMode == Chat_Mode.COMMENT_MODE ? primaryColor:greyColor,
                  ),
                ),
                color: TOPIC_COLORS[widget.topic.color],
              ),
              Expanded(child: Container()),         // Button mark interest to receive notification
              (widget.user != null) ? Material(
                child: new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 8.0),
                  child: new IconButton(
                    icon: new Icon(Icons.bookmark),
                     onPressed: () => updateBookmark(!_isBookmark),
                    color: bookmarkColor,
                  ),
                ),
                color: TOPIC_COLORS[widget.topic.color],
              ):Container(),
              (widget.user != null && widget.user.globalHideRight == true) ? Material(
                child: new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 8.0),
                  child: new IconButton(
                    icon: hideIconButton,
                     onPressed: () => updateVisible(widget.topic.isGlobalHide),
                    color: bookmarkColor,
                  ),
                ),
                color: TOPIC_COLORS[widget.topic.color],
              ):Container() ]);  
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
    if(widget.chatMode == Chat_Mode.MEDIA_MODE) {
      List<String> _urlList = this._galleryImageUrlList.values.toList();
      print("galleryImageUrlList ${_urlList.length}");
      for(int i = 0; i< _urlList.length; i++) {
        String imageUrl = _urlList[i];
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
      }
    }
    if(widget.chatMode == Chat_Mode.USER_MODE) {  
      List<String> userIdList = widget.getAllUserList();
      print("userIdListt ${userIdList.length}");
      for(int i = 0; i< userIdList.length; i++) {
        String userId = userIdList[i];
        String userName = widget.getUserName(userId);
        int color = widget.getColor(userId);
        Widget _userWidget = Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                padding: EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: TOPIC_COLORS[color],
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
                child: Row ( children: <Widget>[
                  Text(userName, style: Theme.of(context).textTheme.headline)
                ])
              ));
        finalWidgetList.add(_userWidget);
      }      
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