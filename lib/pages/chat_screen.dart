import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

//import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import '../models/chat_model.dart';
import './chat_map.dart';
import '../widgets/chat_message.dart';
import 'package:ourland_native/helper/geo_helper.dart';
import '../widgets/send_message.dart';

final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class Chat extends StatelessWidget {
  final String parentId;
  final String parentTitle;
  final GeoPoint topLeft;
  final GeoPoint bottomRight;
  final GeoPoint messageLocation;
  final User user;
  Chat({Key key, @required this.user, @required this.parentId, @required this.parentTitle, this.topLeft, this.bottomRight, this.messageLocation}) : super(key: key);

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
          body: new ChatScreen(
            user: this.user,
            parentId: this.parentId,
            parentTitle: this.parentTitle,
            topLeft: this.topLeft,
            bottomRight: this.bottomRight,
            messageLocation: this.messageLocation
          ),
        );
  }
}

class ChatScreen extends StatefulWidget {
  final String parentId;
  final String parentTitle;
  final GeoPoint topLeft;
  final GeoPoint bottomRight;
  final GeoPoint messageLocation;
  final User user;

  ChatScreen({Key key, @required this.user, @required this.parentId, @required this.parentTitle, this.topLeft, this.bottomRight, this.messageLocation}) : super(key: key);

  @override
  State createState() => new ChatScreenState(parentId: this.parentId, parentTitle: this.parentTitle, topLeft: this.topLeft, bottomRight: this.bottomRight, messageLocation: this.messageLocation);
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin  {
  ChatScreenState({Key key, @required this.parentId, @required this.parentTitle, @required this.topLeft, @required this.bottomRight, this.messageLocation});

  String parentId;
  String parentTitle;
  GeoPoint topLeft;
  GeoPoint bottomRight;
  String id;
  ChatModel chatModel;
  ChatMap chatMap;

  var listMessage;
  String groupChatId;
  SharedPreferences prefs;

  bool isLoading;

  // use to get current location
  Position _currentLocation;
  GeoPoint messageLocation;

  StreamSubscription<Position> _positionStream;

  Geolocator _geolocator = new Geolocator();
  LocationOptions locationOptions = new LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  GeolocationStatus geolocationStatus = GeolocationStatus.denied;
  String error;

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    chatModel = new ChatModel(this.parentId, widget.user);
    chatMap = null; 

    isLoading = false;

    readLocal();
    initPlatformState();
    if(this.topLeft == null) {
      _positionStream = _geolocator.getPositionStream(locationOptions).listen(
        (Position position) {
          if(position != null) {
            print('initState Poisition ${position}');
            _currentLocation = position;
            GeoPoint mapCenter = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
            this.messageLocation = mapCenter;
            if(this.chatMap == null) {        
              this.chatMap = new ChatMap(topLeft: this.messageLocation, bottomRight: this.messageLocation, height: MAP_HEIGHT);
            } else {
              this.chatMap.updateCenter(mapCenter);
            }
          }
        });
    } else {
      this.chatMap = new ChatMap(topLeft: this.topLeft, bottomRight: this.bottomRight, height: MAP_HEIGHT);
      if(this.messageLocation == null) {
        this.messageLocation = GeoHelper.boxCenter(this.topLeft, this.bottomRight);;
      }
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
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
            chatMap = new ChatMap(topLeft: this.messageLocation, bottomRight: this.messageLocation, height: MAP_HEIGHT);
          }
      });
    }
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

  Widget buildItem(String messageId, Map<String, dynamic> document, Function _onTap, BuildContext context) {
    Widget rv;
    GeoPoint location = document['geo'];
    this.chatMap.addLocation(location, document['content'], document['type'], "Test");
    rv = new ChatMessage(user: widget.user, messageBody: document, parentId: this.parentId, messageId: messageId, onTap: _onTap);
    return rv;
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

  @override
  Widget build(BuildContext context) {
    void _onTap(String messageId, String parentTitle, GeoPoint topLeft, GeoPoint bottomRight) {
      print("onTap");
      GeoPoint _messageLocation = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
      if(this.messageLocation != null) {
        _messageLocation = this.messageLocation;
      }
      GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new Chat(user: widget.user, parentId: messageId, parentTitle: parentTitle, topLeft: topLeft, bottomRight: bottomRight, messageLocation: _messageLocation);
          },
        ),
      );
    }
    //this.chatMap.mapCenter = this._currentLocation; 
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              
              new Container( 
                decoration: new BoxDecoration(
                  color: Theme.of(context).cardColor),
                // child: GoogleMapWidget(this._currentLocation.latitude, this._currentLocation.longitude),
                  child: this.chatMap,
              ),
              
              // List of messages
              buildListMessage(_onTap, context),
              // Input content
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

  Widget buildListMessage(Function _onTap, BuildContext context) {
    return Flexible(
      child: groupChatId == ''
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: this.chatModel.getMessageSnap(this._currentLocation, 1),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) {
//                      if(index == 0) {
//                        return this.chatMap;
//                      } else {
                        return buildItem(snapshot.data.documents[index].data['id'], snapshot.data.documents[index].data, _onTap, context);
//                      }
                    },
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }
}
