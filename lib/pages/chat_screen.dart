import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/widgets/chat_list.dart';
import 'package:ourland_native/widgets/chat_message.dart';
import 'package:ourland_native/widgets/chat_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_model.dart';
import '../widgets/send_message.dart';

final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class ChatScreen extends StatelessWidget {
  final String parentId;
  final String parentTitle;
  final GeoPoint topLeft;
  final GeoPoint bottomRight;
  final GeoPoint messageLocation;
  final String imageUrl;
  final String desc;
  final User user;
  ChatScreen({Key key, @required this.user, @required this.parentId, @required this.parentTitle, this.topLeft, this.bottomRight, this.messageLocation, this.imageUrl, this.desc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
          key: _scaffoldKey,
          appBar: new AppBar(
            title: new Text(
              this.parentTitle,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0.7,
          ),
          body: new ChatScreenBody(
            user: this.user,
            parentId: this.parentId,
            parentTitle: this.parentTitle,
            topLeft: this.topLeft,
            bottomRight: this.bottomRight,
            messageLocation: this.messageLocation,
            imageUrl: this.imageUrl,
            desc: this.desc
          ),
        );
  }
}

class ChatScreenBody extends StatefulWidget {
  final String parentId;
  final String parentTitle;
  final GeoPoint topLeft;
  final GeoPoint bottomRight;
  final GeoPoint messageLocation;
  final String imageUrl;
  final String desc;
  final User user;

  ChatScreenBody({Key key, @required this.user, @required this.parentId, @required this.parentTitle, this.topLeft, this.bottomRight, this.messageLocation, this.imageUrl, this.desc}) : super(key: key);

  @override
  State createState() => new ChatScreenBodyState(parentId: this.parentId, parentTitle: this.parentTitle, topLeft: this.topLeft, bottomRight: this.bottomRight, messageLocation: this.messageLocation, imageUrl: this.imageUrl, desc: this.desc);
}

class ChatScreenBodyState extends State<ChatScreenBody> with TickerProviderStateMixin  {
  String parentId;

  String parentTitle;
  GeoPoint topLeft;
  GeoPoint bottomRight;
  String imageUrl;
  String desc;
  String id;
  ChatModel chatModel;
  ValueNotifier<Stream> chatStream;
  ChatSummary chatSummary;
  //ValueNotifier<Stream> chatStream1;
  var listMessage;
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
  ChatScreenBodyState({Key key, @required this.parentId, @required this.parentTitle, @required this.topLeft, @required this.bottomRight, this.messageLocation, this.imageUrl, this.desc});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<GeoPoint> summaryTopLeft = new ValueNotifier<GeoPoint>(this.topLeft);
    ValueNotifier<GeoPoint> summaryBottomRight = new ValueNotifier<GeoPoint>(this.bottomRight);
    ChatSummary chatSummary = ChatSummary(chatStream: this.chatStream, topLeft: summaryTopLeft, bottomRight: summaryBottomRight, width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height/4, user: widget.user, imageUrl: imageUrl, desc: desc);
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[

              new Container(
                decoration: new BoxDecoration(
                  color: Theme.of(context).cardColor),
                child: chatSummary,
              ),

              // List of messages
              ChatList(chatStream: chatStream, parentId: this.parentId, user: widget.user, listScrollController: this.listScrollController),
              (this.messageLocation != null) ?
                new SendMessage(chatModel: this.chatModel, listScrollController: this.listScrollController, messageLocation: this.messageLocation) : new CircularProgressIndicator(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Widget buildItem(String messageId, Map<String, dynamic> document, Function _onTap, BuildContext context) {
    Widget rv;
    rv = new ChatMessage(user: widget.user, messageBody: document, parentId: this.parentId, messageId: messageId, onTap: _onTap);
    return rv;
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
    if(this.topLeft == null) {
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
    chatModel = new ChatModel(this.parentId, widget.user);
    chatSummary = null;
 //   chatMap = null;

    isLoading = false;

    //readLocal();
    initPlatformState();
    chatStream = new ValueNotifier(this.chatModel.getMessageSnap(this._currentLocation, 1));
    //chatStream1 = new ValueNotifier(this.chatModel.getMessageSnap(this._currentLocation, 1));
    if(this.topLeft == null) {
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
        this.messageLocation = GeoHelper.boxCenter(this.topLeft, this.bottomRight);;
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

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    if (id.hashCode <= parentId.hashCode) {
      groupChatId = '$id-$parentId';
    } else {
      groupChatId = '$parentId-$id';
    }

    setState(() {});
  }
}
