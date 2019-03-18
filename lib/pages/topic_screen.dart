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
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:ourland_native/models/chat_model.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/Topic_message.dart';
import 'package:ourland_native/helper/geo_helper.dart';

final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;

class TopicScreen extends StatefulWidget {
  final GeoPoint fixLocation;
  final User user;
  TopicScreenState _state;

  TopicScreen({Key key, @required this.user, this.fixLocation}) : super(key: key);
  void setLocation(GeoPoint location) {
    _state.setLocation(location);
  }

  @override
  State createState() {
    _state = new TopicScreenState(fixLocation: this.fixLocation);
    return _state;
  } 
}
class TopicScreenState extends State<TopicScreen> with TickerProviderStateMixin  {
  TopicScreenState({Key key, @required this.fixLocation});
  GeoPoint fixLocation;
  MessageService messageService;
  ChatMap chatMap;

  var listMessage;
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
    messageService = new MessageService(widget.user);
    chatMap = null; 

    isLoading = false;

    initPlatformState();
    if(this.fixLocation == null) {
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
      print('FixLocation ${this.fixLocation.latitude} , ${this.fixLocation.longitude}');
      this.chatMap = new ChatMap(topLeft: this.fixLocation, bottomRight: this.fixLocation, height: MAP_HEIGHT);
      if(this.messageLocation == null) {
        this.messageLocation = this.fixLocation;
      }
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    if(this.fixLocation == null) {
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
            chatMap = new ChatMap(topLeft: this.messageLocation, bottomRight: this.messageLocation,  height: MAP_HEIGHT);
          }
      });
    }
  }

  void setLocation(GeoPoint location) {
    print("${location}");
    setState(() {
      this.fixLocation = location;
      this.messageLocation = location;
    });
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
      });
    }
  }

  Widget buildItem(String messageId, Map<String, dynamic> document, Function _onTap, BuildContext context) {
    Widget rv; 
    int type = 0;
    if(document['createdUser'] == null) {
      document['createdUser']['user'] = "Test";
    }

    Topic topic = Topic.fromMap(document);
    GeoPoint location = topic.geoCenter;
    if(this.chatMap != null) {
      this.chatMap.addLocation(messageId, location, topic.topic, type, topic.createdUser.username);
    }
    rv = new TopicMessage(user: widget.user, topic: topic, onTap: _onTap);
    return rv;
  }

  @override
  Widget build(BuildContext context) {
    void _onTap(Topic topic, String parentTitle) {
      GeoPoint _messageLocation = new GeoPoint(this.messageLocation.latitude, this.messageLocation.longitude);
      if(this.fixLocation != null) {
        _messageLocation = this.fixLocation;
      }
      //GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new ChatScreen(user: widget.user, topic: topic, parentTitle: parentTitle, messageLocation: _messageLocation);
          },
        ),
      );
    }

    return Stack(
      children: <Widget>[
        buildScrollView(_onTap, context),     
        buildLoading(),
      ],
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
          :  new Container()
    );
  }

  Widget buildScrollView(Function _onTap, BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          expandedHeight: MAP_HEIGHT,
          pinned: true,
          floating: true,
          snap: true,
          // Add Filter later
          
          actions: <Widget>[
            // snack bar
          ],
          
          flexibleSpace: FlexibleSpaceBar(
            title: (this.messageLocation != null) ? Text('GPS: ${this.messageLocation.latitude}, ${this.messageLocation.longitude}') : null,
            background: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                (this.chatMap != null) ? this.chatMap : new Container(height: MAP_HEIGHT),
                // This gradient ensures that the toolbar icons are distinct
                // against the background image.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.0, -1.0),
                      end: Alignment(0.0, -0.4),
                      colors: <Color>[Color(0x60000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        buildSilverListMessage(_onTap, context),
      ],
    );
  }

    Widget buildSilverListMessage(Function _onTap, BuildContext context) {
    return StreamBuilder(
      stream: this.messageService.getTopicSnap(this.messageLocation, 1),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          listMessage = snapshot.data.documents;
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
                return buildItem(snapshot.data.documents[index].data['id'], snapshot.data.documents[index].data, _onTap, context);
              },
              childCount: snapshot.data.documents.length,
            ),
          );
        } else {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)));
              },
              childCount: 1,
            ),
          );
        }
      },
    );
  }
}
