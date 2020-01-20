import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourland_native/helper/geo_helper.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/color_picker.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class SendMessageScreen extends StatefulWidget {
  final Function getCurrentLocation;
  final User user;
  SearchingMsg searchingMsg;
  SendMessageScreen({Key key, @required this.getCurrentLocation, @required this.user, this.searchingMsg}) : super(key: key);

  @override
  State createState() => new SendMessageState();
}

class SendMessageState extends State<SendMessageScreen> with TickerProviderStateMixin  {
  SendMessageState({Key key}) {

  }
  String id;
  MessageService messageService;
  UserService userService;
  File imageFile;

  SharedPreferences prefs;

  // use to get current location
  GeoPoint _messageLocation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
  String _newTopicLabel;
  String _desc;
  String _firstTag;
  int _type;
  String _currentLocationSelection;
  String _location;
  String _label ;
  ChatMap map;
  bool _isSubmitDisable;
  bool _pendingIsSubmitDisable;
  String _pendingButtonText; 
  Widget _sendButton;
  Widget _pendingButton;
  int _color;
  String _buttonText;

  final FocusNode _locationFocus = FocusNode();  
  final FocusNode _titleFocus = FocusNode();  
  final FocusNode _descFocus = FocusNode();
  

  @override
  void initState() {
    super.initState();
    if(widget.searchingMsg == null) {
      _label = LABEL_REGION;
    } else {
      _label = widget.searchingMsg.text;
    }
    focusNode.addListener(onFocusChange);
    messageService = new MessageService(widget.user);
    userService = new UserService();
    _tagDropDownMenuItems = getDropDownMenuItems(TAG_SELECTION, false);
    _firstTag = _tagDropDownMenuItems[0].value;
    
    _newTopicLabel = LABEL_NEW_TOPIC;
    _buttonText = LOCATION_NOT_VALIDATE;
    _sendButton = RaisedButton(child: Text(_buttonText), onPressed: null);
    Random rng = new Random();
    _color = rng.nextInt(TOPIC_COLORS.length);
    _desc = "";
    _parentTitle = "";
    _type = 0;
    _isSubmitDisable = true;
    List<String> dropDownList = [LABEL_NEARBY];
    if(widget.user.homeAddress != null) {
      dropDownList.add(LABEL_REGION0);
    }
    if(widget.user.officeAddress != null) {
      dropDownList.add(LABEL_REGION1);
    }    
    _locationDropDownMenuItems = getDropDownMenuItems(dropDownList, false);
    _currentLocationSelection = _locationDropDownMenuItems[0].value;

    //Map map = widget.getCurrentLocation();
    //this._messageLocation = map['GeoPoint'];
    //_locationPermissionGranted = map['LocationPermissionGranted'];
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

  Widget renderMap() {
    if(this._messageLocation == null) {
      return SizedBox(height: MAP_HEIGHT);
    } else {
      return ChatMap(
          topLeft: this._messageLocation,
          bottomRight: this._messageLocation,
          height: MAP_HEIGHT,
          markerList: [OurlandMarker(_label, this._messageLocation, 0, _label, "settings")],
          updateCenter: null,);
   }
  }

  Widget renderLocationField() {
    return Row(children: [SizedBox(width: 12.0), Expanded(child: 
      TextField(
        focusNode: _locationFocus,
        decoration: InputDecoration(
            hintText: LABEL_REGION0),
        keyboardType: TextInputType.text,
        onChanged: (value) {
          setState(() {
            _location = value;
            _messageLocation = null;
          });},
        onSubmitted: onSubmitted)), 
        Material(child: Container(
          decoration: BoxDecoration(
                border: Border.all(width: 0.5, color: Colors.grey),
                /*
                boxShadow: [
                  new BoxShadow(
                    color: Colors.grey,
                    offset: new Offset(0.0, 2.5),
                    blurRadius: 4.0,
                    spreadRadius: 0.0
                  )
                ],
                */  //borderRadius: BorderRadius.circular(6.0)
              ),
            child: IconButton(icon: Icon(Icons.location_searching), onPressed: onPressed))),
        SizedBox(width: 12.0)]);
  }

  void onSubmitted(String dummy) {
    fieldFocusChange(context, _locationFocus, _titleFocus);
    onPressed();
  }

  void refreshMarker(String label) {
    setState(() {
      _label = label;
    });

    /*
    this.map.clearMarkers();
    this.map.addMarker(this._currentLocation, label, "settings");
    */
  }

  void onPressed()  {
    if(_location != null && _location.length > 1) {
      print("Pressed" + _location);
      _geolocator.placemarkFromAddress(_location).then(
          (List<Placemark> placemark) {
        Position pos = placemark[0].position;
        String markerLabel = placemark[0].name;
        print(markerLabel);
        setState(() {
          this._messageLocation= new GeoPoint(pos.latitude, pos.longitude);
        });
        //updateMap();
        refreshMarker(markerLabel);
      }, onError: (e) {
        print(e.toString());
        // PlatformException thrown by the Geolocation if the address cannot be translate
        // DO NOTHING
      });
    }
  }
  void _swapValuable(BuildContext context) {
    if(_pendingButton != null) {
      print("Swap Button");
      if(_sendButton.runtimeType == RaisedButton) {
        setState(() {          
          _sendButton = Container();  
        });
      } else {
        setState(() {          
          _sendButton = _pendingButton;
          _pendingButton = null;   
        });
      }
    }
    //scheduleMicrotask(() => _swapValuable(context));
  }

  @override
  Widget build(BuildContext context) {
    scheduleMicrotask(() => _swapValuable(context));

    Widget body = new WillPopScope(
      child: Column(
        children: <Widget>[    
          renderMap(),
          renderLocationField(),        
          new Form(
             key: _formKey,
             autovalidate: true,
//           onWillPop: _warnUserAboutInvalidData,
            child: formUI(context)
          )
        ],
      ),
      onWillPop: onBackPress,
    );
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        backgroundColor: TOPIC_COLORS[_color],
        title: new Text(
          _newTopicLabel,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.7,
        actionsIconTheme: Theme.of(context).primaryIconTheme,
      ),
      body: Container(
        color: TOPIC_COLORS[_color],
        //child: new Container(),
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            child: body
          ),
        ),

      ),
    ); 
  }

  Future getImageFromGallery() async {
    await getImage(ImageSource.gallery);
  }

  Future getImageFromCamera() async {
    await getImage(ImageSource.camera);
  }

  Future getImage(ImageSource imageSource) async {
    File newImageFile = await ImagePicker.pickImage(source: imageSource);

    if (newImageFile != null) {
      setState(() {
        imageFile = newImageFile;
        //print("${imageFile.uri.toString()}");
      });
    }
  }

  Widget topicImageUI(BuildContext context) {
    return 
      Column(children: <Widget>[
        Row(children: <Widget> [
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: getImageFromGallery,
                color: primaryColor,
              ),
            ),
            color: TOPIC_COLORS[_color],
          ),
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.camera_enhance),
                onPressed: getImageFromCamera,
                color: primaryColor,
              ),
            ),
            color: TOPIC_COLORS[_color],
          ),
          imageFile != null ? Stack(children: [Image.file(
            imageFile, width: MediaQuery.of(context).size.width / 2
          ), IconButton(icon: Icon(Icons.close), onPressed: removeImage,)]) : new Container(), 
        ]
      )        
    ],
    crossAxisAlignment: CrossAxisAlignment.center,
    );
  }

  void removeImage() {setState((){imageFile = null;});}
  void sendMessage() {
    if (_formKey.currentState.validate()) {
//    If all data are correct then save data to out variables
      _formKey.currentState.save();
      
      List<String> tags = [this._firstTag];
      // TODO pass this_desc to extract the hash tag
      // Find the geo box
      var destBox = GeoHelper.findBoxGeo(this._messageLocation, 1000.0);
      SearchingMsg searchingMsg = SearchingMsg("", this._messageLocation, this._location, this._parentTitle, 
      widget.user.username, widget.user.avatarUrl, widget.user.uuid, widget.user.uuid,
      tags, this._desc, null /*this._link*/,
      null, null, null, null, /*this._imageUrl, this._publicImageURL, this._thumbnailImageURL, this._thumbnailPublicImageURL, */
      null, null, null, null, null, /*this._start, this._startTime, this._duration, this._interval, this._endDate,*/
      null, null, null, /*this._everydayOpenning, this._weekdaysOpennings, this._polling,*/
      null);
      messageService.sendPendingSearchingMessage(searchingMsg, imageFile);
      onBackPress();
    }
  }
  Widget formUI(BuildContext context) {
    String validation(String label, String value) {
      String rv;
      bool _updateButton = false;
      _pendingIsSubmitDisable = _isSubmitDisable;
      _pendingButtonText = _buttonText;
      if(this._messageLocation == null) {
        _pendingIsSubmitDisable = true;
        _pendingButtonText = LOCATION_NOT_VALIDATE;         
        rv = LOCATION_NOT_VALIDATE;
      } else {
        switch(label) {
          case LABEL_TOPIC:
            if(value.isEmpty) {
              _pendingIsSubmitDisable = true;
              _pendingButtonText = LABEL_MISSING_TOPIC;
              rv = LABEL_MISSING_TOPIC;
            } else {
              _pendingIsSubmitDisable = false;
              if(this._desc.length == 0) {
                _pendingButtonText = LABEL_MORE_DETAIL;
              }
              _formKey.currentState.save();
            }
            break;
          case LABEL_DETAIL:
            if(this._parentTitle.length != 0) {
              if(value.isNotEmpty) {
                if(!_isSubmitDisable) {
                  _pendingIsSubmitDisable = false;
                  _pendingButtonText = LABEL_SEND;
                }
              } else {
                _formKey.currentState.save();
                if(!_isSubmitDisable) {
                  _pendingIsSubmitDisable = false;
                  _pendingButtonText = LABEL_MORE_DETAIL;
                }
              }
            }
            break;        
        }
      }
      /*
      print(label + " " + value + " " + _isSubmitDisable.toString() + " " + _pendingIsSubmitDisable.toString()
      + " " + _buttonText  + " " + _pendingButtonText);
      */
      if(_isSubmitDisable != _pendingIsSubmitDisable || _buttonText != _pendingButtonText) {
        _isSubmitDisable = _pendingIsSubmitDisable;
        _buttonText = _pendingButtonText;  
        _pendingButton = RaisedButton(
              child: Text(_buttonText),
              onPressed: (this._messageLocation == null || this._parentTitle.length == 0) ? null : sendMessage,
            );
        
      }
      return rv;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          /* // This should be row to display hash tag detect in desc
          Row(
            children: <Widget> [
              Expanded(child: new Text(LABEL_HAS)),
              Expanded(child: new DropdownButton(
                value: _firstTag,
                items: _tagDropDownMenuItems,
                onChanged: (String value) {setState(() {_firstTag = value;});},
              )),
            ]
          ),
          */
          const SizedBox(height: 12.0),
          TextFormField(
            focusNode: _titleFocus,
            onFieldSubmitted: (term) {
              fieldFocusChange(context, _titleFocus, _descFocus);
            },
            textInputAction: TextInputAction.next,
            //textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              icon: Icon(Icons.person),
              hintText: HINT_TOPIC,
              labelText: LABEL_TOPIC,
            ),
            validator: (value) {
              return validation(LABEL_TOPIC, value);
            },
            onChanged: (String value) {this._parentTitle = value;},
            onSaved: (String value) {this._parentTitle = value;},
          ),
          const SizedBox(height: 12.0),
          topicImageUI(context), 
          const SizedBox(height: 12.0),
          TextFormField(
            focusNode: _descFocus,
            onFieldSubmitted: (term) {
              fieldFocusChange(context, _titleFocus, _descFocus);
            },
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: HINT_DEATIL,
              helperText: HELPER_DETAIL,
              labelText: LABEL_DETAIL,
            ),
            maxLines: 3,
            validator: (value) {
              return validation(LABEL_DETAIL, value);
            },
            onChanged: (String value) {this._desc = value;},
            onSaved: (String value) {this._desc = value;},
          ),
          _sendButton
        ],
      )
    );
  }
}
