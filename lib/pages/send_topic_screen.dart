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
import '../widgets/send_message.dart';

final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class SendTopicScreen extends StatefulWidget {
  final GeoPoint messageLocation;
  final User user;
  SendTopicScreen({Key key, @required this.messageLocation, @required this.user}) : super(key: key);

  @override
  State createState() => new SendTopicState(messageLocation: this.messageLocation);
}

class SendTopicState extends State<SendTopicScreen> with TickerProviderStateMixin  {
  SendTopicState({Key key, this.messageLocation});
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

  List<DropdownMenuItem<String>> _tagDropDownMenuItems;
  List<DropdownMenuItem<String>> _locationDropDownMenuItems;

  String _parentTitle;
  String _desc;
  String _firstTag;
  int _type;
  String _currentLocationSelection;
  bool _isShowGeo;
  bool _isSubmitDisable;
  Text _buttonText;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    chatModel = new ChatModel(TOPIC_ROOT_ID, widget.user);
    chatMap = null; 
    _tagDropDownMenuItems = getDropDownMenuItems(TAG_SELECTION);
    _firstTag = _tagDropDownMenuItems[0].value;
    
    
    _buttonText = new Text(MISSING_TOPIC);
    _isShowGeo = false;
    _desc = "";
    _parentTitle = "";
    _type = 0;
    _isSubmitDisable = false;

    _locationDropDownMenuItems = getDropDownMenuItems([LABEL_NEARBY, LABEL_REGION0, LABEL_REGION1]);
    _currentLocationSelection = _locationDropDownMenuItems[0].value;

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
              this.chatMap = new ChatMap(mapCenter: mapCenter, height: CREATE_TOPIC_MAP_HEIGHT);
            } else {
              this.chatMap.updateCenter(mapCenter);
            }
          }
        });
    } else {
      print('messageLocation ${this.messageLocation.latitude} , ${this.messageLocation.longitude}');
      this.chatMap = new ChatMap(mapCenter: this.messageLocation, height: CREATE_TOPIC_MAP_HEIGHT);
    }
  }

  List<DropdownMenuItem<String>> getDropDownMenuItems(List<String> labelList) {
    List<DropdownMenuItem<String>> items = new List();
    for (String label in labelList) {
      items.add(new DropdownMenuItem(
          value: label,
          child: new Text(label)
      ));
    }
    return items;
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
            chatMap = new ChatMap(mapCenter: mapCenter, height: CREATE_TOPIC_MAP_HEIGHT);
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

  void updateLocation(String locationSelection) {
    setState(() {
      _currentLocationSelection = locationSelection;          
    // TODO 
      switch (_currentLocationSelection) {
        case LABEL_NEARBY:
          this.messageLocation = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
          break;
        case LABEL_REGION0:
        case LABEL_REGION1:
          this.messageLocation = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
          break;
      }
      GeoPoint mapCenter = this.messageLocation;
      if(this.chatMap == null) {        
        this.chatMap = new ChatMap(mapCenter: mapCenter, height: MAP_HEIGHT);
      } else {
        this.chatMap.updateCenter(mapCenter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    void sendMessage() {
      List<String> tags = [this._firstTag];
      chatModel.sendTopicMessage(this.messageLocation, this._parentTitle, tags, this._desc, this._type, this._isShowGeo);
      onBackPress();
    };

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
                  Row(
                    children: <Widget> [
                      Expanded(child: new Text(LABEL_IN)),
                      Expanded(child: new DropdownButton(
                        value: _currentLocationSelection,
                        items: _locationDropDownMenuItems,
                        onChanged: updateLocation,
                      )),
                      Expanded(child: new Text(LABEL_HAS)),
                      Expanded(child: new DropdownButton(
                        value: _firstTag,
                        items: _tagDropDownMenuItems,
                        onChanged: (String value) {setState(() {_firstTag = value;});},
                      )),
                    ]
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      filled: true,
                      icon: Icon(Icons.person),
                      hintText: HINT_TOPIC,
                      labelText: LABEL_TOPIC,
                    ),
                    onSaved: (String value) {setState(() { this._parentTitle = value;}); },
                // validator: _validateName,
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: HINT_DEATIL,
                      helperText: HELPER_DETAIL,
                      labelText: LABEL_DETAIL,
                    ),
                    maxLines: 3,
                    onSaved: (String value) { setState(() { this._desc = value;}); },
                  ),
                  Row(
                    children: <Widget> [
                        Switch.adaptive(
                          value: _isShowGeo,
                          onChanged: (bool value) {
                              _isShowGeo = value;
                          }
                        ),
                        Text(LABEL_MUST_SHOW_GEO)
                    ]
                  ),
                  RaisedButton(
                    child: _buttonText,
                    onPressed: _isSubmitDisable ? null : sendMessage,
                  )
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
