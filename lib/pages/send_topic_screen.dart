import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourland_native/models/constant.dart';
import '../models/chat_model.dart';
import './chat_map.dart';
import '../widgets/send_message.dart';

final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class SendTopicScreen extends StatefulWidget {
  final GeoPoint messageLocation;
  SendTopicScreen({Key key,this.messageLocation}) : super(key: key);

  @override
  State createState() => new SendTopicState(messageLocation: this.messageLocation);
}

class SendTopicState extends State<SendTopicScreen> with TickerProviderStateMixin  {
  SendTopicState({Key key, this.messageLocation});

  String parentTitle;
  String id;
  ChatModel chatModel;
  ChatMap chatMap;

  SharedPreferences prefs;

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
    chatModel = new ChatModel(TOPIC_ROOT_ID);
    chatMap = null; 

    initPlatformState();
    if(this.messageLocation == null) {
      _positionStream = _geolocator.getPositionStream(locationOptions).listen(
        (Position position) {
          if(position != null) {
            print('initState Poisition ${position}');
            _currentLocation = position;
            GeoPoint mapCenter = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
            this.messageLocation = mapCenter;
            if(this.chatMap == null) {        
              this.chatMap = new ChatMap(mapCenter: mapCenter, height: MAP_HEIGHT);
            } else {
              this.chatMap.updateCenter(mapCenter);
            }
          }
        });
    } else {
      print('messageLocation ${this.messageLocation.latitude} , ${this.messageLocation.longitude}');
      this.chatMap = new ChatMap(mapCenter: this.messageLocation, height: MAP_HEIGHT);
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    if(this.messageLocation == null) {
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
            chatMap = new ChatMap(mapCenter: mapCenter, height: MAP_HEIGHT);
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

  Future<bool> onBackPress() {
    Navigator.pop(context);
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
/*    
    void _onTap(String messageId, String parentTitle, GeoPoint topLeft, GeoPoint bottomRight) {
      print("onTap");
      GeoPoint _messageLocation = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
      if(this.fixLocation != null) {
        _messageLocation = this.fixLocation;
      }
      GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new Chat(parentId: messageId, parentTitle: parentTitle, fixLocation: mapCenter, messageLocation: _messageLocation);
          },
        ),
      );
    }
 */
    Widget body = new WillPopScope(
      child: Column(
        children: <Widget>[              
          new Container( 
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor),
            child: (this.chatMap != null) ? this.chatMap : new Container(),
          ),
          new Form(
//               key: _formKey,
//               autovalidate: _autovalidate,
//               onWillPop: _warnUserAboutInvalidData,
            child: SingleChildScrollView(
//                dragStartBehavior: DragStartBehavior.down,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 24.0),
                  TextFormField(
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      filled: true,
                      icon: Icon(Icons.person),
                      hintText: 'What do people call you?',
                      labelText: 'Name *',
                    ),
                    onSaved: (String value) { parentTitle = value; },
                // validator: _validateName,
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Tell us about yourself (e.g., write down what you do or what hobbies you have)',
                      helperText: 'Keep it short, this is just a demo.',
                      labelText: 'Life story',
                    ),
                    maxLines: 3,
                  ),
                ],
              )
            )
          )
/*                    // Input content
          (this.messageLocation != null) ?
            new SendMessage(chatModel: this.chatModel, listScrollController: this.listScrollController, messageLocation: this.messageLocation) : new CircularProgressIndicator(),
            */
        ],
      ),

      onWillPop: onBackPress,
    );
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(
          "test",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.7,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child:body
      ),
    ); 
  }
}
