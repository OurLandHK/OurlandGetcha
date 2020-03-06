import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:ourland_native/widgets/chat_list.dart';
import 'package:ourland_native/widgets/chat_popup_menu.dart';
import 'package:ourland_native/widgets/chat_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ourland_native/services/user_service.dart';

import '../widgets/send_message.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class ChatScreen extends StatelessWidget {
  final String parentTitle;
  final Topic topic;
  final GeoPoint messageLocation;
  final SharedPreferences preferences;
//  final bool enableSendButton;
  final User user;
  ChatScreen({Key key, @required this.preferences, @required this.user, @required this.topic, @required this.parentTitle, this.messageLocation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
          key: _scaffoldKey,
          appBar: new AppBar(
            backgroundColor: TOPIC_COLORS[topic.color],
            title: new Text(
              this.parentTitle,
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            actions: this.user != null ? <Widget>[
              new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
              ),
              new ChatPopupMenu(this.topic, this.user)
            ] : null,
            centerTitle: true,
            elevation: 0.7,
          ),
          body: Container(
            //color: TOPIC_COLORS[topic.color],
            child: new ChatScreenBody(
              preferences: preferences,
              user: this.user,
              topic: this.topic,
              parentTitle: this.parentTitle,
              messageLocation: this.messageLocation,
            ),
          ),
        );
  }
}

class ChatScreenBody extends StatefulWidget {
  final String parentTitle;
  final GeoPoint messageLocation;
  final Topic topic;
  SearchingMsg _searchingMsg;
  final SharedPreferences preferences;
  final User user;

  ChatScreenBody({Key key, @required this.preferences, @required this.user, @required this.topic, @required this.parentTitle, this.messageLocation}) : super(key: key);

  @override
  State createState() => new ChatScreenBodyState(messageLocation: this.messageLocation);
}

class ChatScreenBodyState extends State<ChatScreenBody> with TickerProviderStateMixin  {
  MessageService messageService;
  ValueNotifier<Stream> chatStream;
  Map<String, User> _userList;
  UserService _userService;
  Chat_Mode _chatMode;
  bool _enableSendButton = false;
  var listMessage;

  SharedPreferences prefs;
  bool isLoading;

  Position _currentLocation;

  // use to get current location
  GeoPoint messageLocation;
  StreamSubscription<Position> _positionStream;

  Geolocator _geolocator = new Geolocator();

  LocationOptions locationOptions = new LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  GeolocationStatus geolocationStatus = GeolocationStatus.denied;
  String error;
  final TextEditingController textEditingController = new TextEditingController();

  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();
  ChatScreenBodyState({Key key, this.messageLocation});

  void toggleComment(Chat_Mode chatMode) {
    setState(() {
      _chatMode = chatMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<GeoPoint> summaryTopLeft = new ValueNotifier<GeoPoint>(widget.topic.geoTopLeft);
    ValueNotifier<GeoPoint> summaryBottomRight = new ValueNotifier<GeoPoint>(widget.topic.geoBottomRight);
    ChatSummary chatSummary = ChatSummary(preferences: widget.preferences, topLeft: summaryTopLeft, bottomRight: summaryBottomRight, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height/4, user: widget.user, imageUrl: widget.topic.imageUrl, topic: widget.topic, messageLocation: widget.messageLocation, chatMode: _chatMode, toggleComment: this.toggleComment, updateUser: this.updateUser, getUserName: this.getUserName, getAllUserList: this.getAllUserId, getColor: this.getColor);
    List<Widget> _widgetList = [chatSummary];
    if(this._chatMode == Chat_Mode.COMMENT_MODE) {
      _widgetList.add(ChatList(chatStream: chatStream, parentId: widget.topic.id, user: widget.user, topic: widget.topic, listScrollController: this.listScrollController, updateUser: updateUser, getUserName: getUserName, getColor: getColor));
      if(widget.user != null) {
        if(this.messageLocation != null)
        {
          print("tmwc blue scu ${this.messageLocation.latitude} and ${_enableSendButton.toString()}");
        } else {
          print("message: location null");
        }
        if(this.messageLocation != null && _enableSendButton) {
          _widgetList.add(SendMessage(topic: widget.topic, messageService: this.messageService, listScrollController: this.listScrollController, messageLocation: this.messageLocation));
        } else {
          //_widgetList.add(LinearProgressIndicator());
        }
      }
    }
    Widget _bodyWidget =  Column(children: _widgetList);
    if(this._chatMode != Chat_Mode.COMMENT_MODE) {
      _bodyWidget = SingleChildScrollView(child: _bodyWidget);
    }
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          _bodyWidget,
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  initPlatformState() async {
    bool _isSendButtonOn = false;
    GeoPoint _messageLocation;
    if(widget.user != null) {
      UserService userService = new UserService();
      RecentTopic recentTopic = await userService.getRecentTopic(widget.user.uuid, widget.topic.id);
      if(recentTopic != null) {
        _messageLocation = recentTopic.messageLocation;
        _isSendButtonOn = true;
        print("Chat Screen Recent Topic ${_isSendButtonOn}");
      } else {
        if(widget.user.homeAddress != null) {
          _isSendButtonOn = widget.topic.isAddressWithin(widget.user.homeAddress);
          print("Chat Screen Home ${_isSendButtonOn}");
          _messageLocation = widget.user.homeAddress;
        }
        if(!_isSendButtonOn && widget.user.officeAddress != null) {
          _isSendButtonOn = widget.topic.isAddressWithin(widget.user.officeAddress);
          print("Chat Screen  Office ${_isSendButtonOn}");
          _messageLocation = widget.user.officeAddress;
        }/*
        if(!_isSendButtonOn && _locationPermissionGranted) {
          print("Current");
          Map map = widget.getCurrentLocation();
          GeoPoint mapCenter = map['GeoPoint'];
          _isSendButtonOn  = widget.topic.isAddressWithin(mapCenter);
        }
        */
      }
    } 
    Position location;
    if(widget.topic.geoTopLeft == null) {
      // Platform messages may fail, so we use a try/catch PlatformException.
      try {
        geolocationStatus = await _geolocator.checkGeolocationPermissionStatus();
        location = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
        error = null;
      } on PlatformException catch (e) {
        if (e.code == 'PERMISSION_DENIED') {
          error = 'Permission denied';
        } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
          error = 'Permission denied - please ask the user to enable it from the app settings';
        }

        location = null;
      }

      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      //if (!mounted) return;

    }
    setState(() {
      if(_isSendButtonOn) {
        this._enableSendButton = _isSendButtonOn;
      }
      //print('initPlatformStateLocation: ${location}');
      if(location != null) {
        _currentLocation = location;
        GeoPoint mapCenter = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
        this.messageLocation = mapCenter;
        if(!_isSendButtonOn) {
          this._enableSendButton = widget.topic.isAddressWithin(this.messageLocation);
        }
      } else {
        this.messageLocation = _messageLocation;
      }
    });
  }

  @override
  void initState() {
    _userService = new UserService();
    super.initState();
    focusNode.addListener(onFocusChange);
    messageService = new MessageService(widget.user);
    _userList = {};
    _chatMode = Chat_Mode.INFO_MODE;
 
    isLoading = false;
    

    //readLocal();
    initPlatformState();
    // Check for previous edit topic
    chatStream = new ValueNotifier(this.messageService.getChatSnap(this.widget.topic.id));
    if(widget.topic.geoTopLeft == null) 
    {
      _positionStream = _geolocator.getPositionStream(locationOptions).listen(
        (Position position) {
          if(position != null) {
            print('initState Poisition ${position}');
            _currentLocation = position;
            GeoPoint mapCenter = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
            this.messageLocation = mapCenter;
          }
        });
    } else {
      if(this.messageLocation == null) {
        this.messageLocation = widget.topic.geoCenter;
      }
    }
  }

  void updateUser(User user) {
    if(_userList[user.uuid] == null) {
      _userList[user.uuid] = user;
    }
  }

  List<String> getAllUserId() {
    return _userList.keys.toList();
  }

  String getUserName(String userID) {
    String rv;
    if(widget.topic.isShowName) {
      rv = _userList[userID].username;
    } else {
      int idx = _userList.keys.toList().indexOf(userID);
      rv= _userService.getSecretName(widget.topic.id, idx);
    }
    return rv;
  }

  int getColor(String userID) {
    int idx = _userList.keys.toList().indexOf(userID);
    return idx %= TOPIC_COLORS.length;
  }


  bool isCurrentUser(int index) {
    return(listMessage[index]['createdUser'] != null && listMessage[index]['createdUser']['uuid'] == widget.user.uuid);
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 && listMessage != null && isCurrentUser(index - 1)) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 && listMessage != null && !isCurrentUser(index - 1)) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    Navigator.pop(context);
    return Future.value(false);
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
      });
    }
  }
}
