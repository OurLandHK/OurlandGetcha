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
import 'package:ourland_native/models/chat_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/widgets/chat_list.dart';
import 'package:ourland_native/widgets/chat_message.dart';
import 'package:ourland_native/widgets/chat_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_model.dart';
import '../widgets/send_message.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class ChatScreen extends StatelessWidget {
  final String parentTitle;
  final Topic topic;
  final GeoPoint messageLocation;
  final User user;
  ChatScreen({Key key, @required this.user, @required this.topic, @required this.parentTitle, this.messageLocation}) : super(key: key);

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
            centerTitle: true,
            elevation: 0.7,
          ),
          body: Container(
            //color: TOPIC_COLORS[topic.color],
            child: new ChatScreenBody(
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
  final User user;

  ChatScreenBody({Key key, @required this.user, @required this.topic, @required this.parentTitle, this.messageLocation}) : super(key: key);

  @override
  State createState() => new ChatScreenBodyState(messageLocation: this.messageLocation);
}

class ChatScreenBodyState extends State<ChatScreenBody> with TickerProviderStateMixin  {
  MessageService messageService;
  ValueNotifier<Stream> chatStream;
  ValueNotifier<Stream> chatStream1;
  ChatSummary chatSummary;
  var listMessage;
  bool _displayComment = false;
  //ChatMap chatMap;

  String groupChatId;
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

  void toggleComment() {
    setState(() {
      _displayComment = !_displayComment;
    });
  }

  @override
  Widget build(BuildContext context) {

    ValueNotifier<GeoPoint> summaryTopLeft = new ValueNotifier<GeoPoint>(widget.topic.geoTopLeft);
    ValueNotifier<GeoPoint> summaryBottomRight = new ValueNotifier<GeoPoint>(widget.topic.geoBottomRight);
    ChatSummary chatSummary = ChatSummary(chatStream: this.chatStream, topLeft: summaryTopLeft, bottomRight: summaryBottomRight, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height/4, user: widget.user, imageUrl: widget.topic.imageUrl, topic: widget.topic, expand: !_displayComment, toggleComment: this.toggleComment);
    List<Widget> _widgetList = [chatSummary];
    if(this._displayComment) {
      _widgetList.add(ChatList(chatStream: chatStream1, parentId: widget.topic.id, user: widget.user, listScrollController: this.listScrollController));
      if(this.messageLocation != null) {
        _widgetList.add(SendMessage(parentID: widget.topic.id, messageService: this.messageService, listScrollController: this.listScrollController, messageLocation: this.messageLocation));
      } else {
        _widgetList.add(LinearProgressIndicator());
      }
    }
    Widget _bodyWidget =  Column(children: _widgetList);
    if(!this._displayComment) {
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
    if(widget.topic.geoTopLeft == null) {
      Position location;
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

      setState(() {
          print('initPlatformStateLocation: ${location}');
          if(location != null) {
            _currentLocation = location;
            GeoPoint mapCenter = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
            this.messageLocation = mapCenter;
          }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    messageService = new MessageService(widget.user);
    chatSummary = null;
 //   chatMap = null;

    isLoading = false;

    //readLocal();
    initPlatformState();
    chatStream = new ValueNotifier(this.messageService.getChatSnap(this.widget.topic.id));
    chatStream1 = new ValueNotifier(this.messageService.getChatSnap(this.widget.topic.id));
    if(widget.topic.geoTopLeft == null) {
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
