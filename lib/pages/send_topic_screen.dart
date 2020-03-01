import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:ourland_native/helper/string_helper.dart';

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
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/color_picker.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

class SendTopicScreen extends StatefulWidget {
  final Function getCurrentLocation;
  final User user;
  List<String> dropdownList = TAG_SELECTION;
  bool isBroadcast = false;
  SendTopicScreen({Key key, @required this.getCurrentLocation, @required this.user, this.isBroadcast, this.dropdownList}) : super(key: key);

  @override
  State createState() => new SendTopicState();
}

class SendTopicState extends State<SendTopicScreen> with TickerProviderStateMixin  {
  SendTopicState({Key key});
  String id;
  MessageService messageService;
  UserService userService;
  File imageFile;

  SharedPreferences prefs;

  // use to get current location
  Position _currentLocation;
  GeoPoint messageLocation;

  StreamSubscription<Position> _positionStream;
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
  List<String> _tags = [];
  String _currentLocationSelection;
  bool _isShowName;
  bool _isSubmitDisable;
  bool _locationPermissionGranted = true;
  int _color;
  Text _buttonText;
  bool _isSendWithLocation; 
  final FocusNode _showNameFocus = FocusNode();  
  final FocusNode _titleFocus = FocusNode();  
  final FocusNode _descFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if(widget.getCurrentLocation != null) {
      _isSendWithLocation = true;
    } else {
      _isSendWithLocation = false;
    }
    focusNode.addListener(onFocusChange);
    messageService = new MessageService(widget.user);
    userService = new UserService();
    _tagDropDownMenuItems = getDropDownMenuItems(widget.dropdownList, false);
    _firstTag = _tagDropDownMenuItems[0].value;
    
    _newTopicLabel = widget.isBroadcast ? LABEL_NEW_BROADCAST_TOPIC : LABEL_NEW_TOPIC;
    _buttonText = new Text(LABEL_MISSING_TOPIC);
    _isShowName = false;
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

    //initPlatformState();
    print("send topic 1");
    if(_isSendWithLocation) {
      Map map = widget.getCurrentLocation();
      this.messageLocation = map['GeoPoint'];
      _locationPermissionGranted = map['LocationPermissionGranted'];
    } else {
      _locationPermissionGranted = false;
      this.messageLocation = null;
    }
    print("send topic 2");
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
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
          _locationPermissionGranted = true;
          _currentLocation = location;
          GeoPoint mapCenter = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
          this.messageLocation = mapCenter;
        }
    });
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
          Map map = widget.getCurrentLocation();
          this.messageLocation = map['GeoPoint'];
          _locationPermissionGranted = map['LocationPermissionGranted'];
          if(!_locationPermissionGranted) {
            setState(() {
              _isSubmitDisable = true;
              _buttonText = Text(PERM_LOCATION_NOT_GRANTED);
            });
          }
          break;
        case LABEL_REGION0:
          this.messageLocation = widget.user.homeAddress;
          break;
        case LABEL_REGION1:
          this.messageLocation = widget.user.officeAddress;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget map =  null;
    if(_isSendWithLocation) {
      map = ChatMap(topLeft: this.messageLocation, bottomRight: this.messageLocation,  height: MAP_HEIGHT, markerList: [], updateCenter: null);
    }
    Widget body = new WillPopScope(
      child: Column(
        children: <Widget>[            
          (_isSendWithLocation) ? Container( 
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor),
            child: map,
          ) : Container(),
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

  Widget tagUI(BuildContext context) {
    List<Chip> chips = [];
    this._tags.forEach((tag) {
      chips.add(Chip(label: Text(tag)));
    });
    return Wrap(runSpacing: 4.0, spacing: 8.0, children: chips);
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

  void searchForKeywords(String desc) {
    String parseText = desc.replaceAll("\n", " ");
    List<String> tempTags = StringHelper.keywordSearch(parseText, "#");
    setState(() {
      _tags = tempTags;
    });
  }

  Widget formUI(BuildContext context) {
    String validation(String label, String value) {
      String rv;
      if(_currentLocationSelection == LABEL_NEARBY && !_locationPermissionGranted && _isSendWithLocation) {
        _isSubmitDisable = true;
        _buttonText = Text(PERM_LOCATION_NOT_GRANTED);
        rv = PERM_LOCATION_NOT_GRANTED;
      } else {
        switch(label) {
          case LABEL_TOPIC:
            if(value.isEmpty) {
              _isSubmitDisable = true;
              _buttonText = Text(LABEL_MISSING_TOPIC);
              rv = LABEL_MISSING_TOPIC;
            } else {
              _isSubmitDisable = false;
              _formKey.currentState.save();
            }
            break;
          case LABEL_DETAIL:
            if(value.isNotEmpty) {
              if(!_isSubmitDisable) {
                _buttonText = Text(LABEL_SEND);
              }
            } else {
              _formKey.currentState.save();
              if(!_isSubmitDisable) {
                _buttonText = Text(LABEL_MORE_DETAIL);
              }
            }
            break;        
        }
      }
      return rv;
    }
    void sendMessage() {
      if (_formKey.currentState.validate()) {
  //    If all data are correct then save data to out variables
        _formKey.currentState.save();
        List<String> tags = [this._firstTag];
        tags.addAll(_tags);
        tags = tags.toSet().toList();
        // TODO pass this_desc to extract the hash tag
        // Find the geo box
        if(_isSendWithLocation) {
          var destBox = GeoHelper.findBoxGeo(this.messageLocation, 1000.0);
          Topic topic = new Topic(widget.isBroadcast, widget.user, destBox['topLeft'], destBox['bottomRight'], this.messageLocation,
                null, this._isShowName, tags, this._parentTitle, this._desc, this._color);
          messageService.sendTopicMessage(this.messageLocation, topic, this.imageFile);
          userService.addRecentTopic(widget.user.uuid, topic.id, this.messageLocation);
        } else {
          Topic topic = new Topic(widget.isBroadcast, widget.user, null, null, this.messageLocation,
                null, this._isShowName, tags, this._parentTitle, this._desc, this._color);
          messageService.sendBroadcastMessage(topic, this.imageFile);
        }
        onBackPress();
      }
    };
    List<Widget> toolbarWidget = [];
    if(_isSendWithLocation) {
      toolbarWidget.add(Expanded(flex: 1, child: new Text(LABEL_IN)));
      toolbarWidget.add(Expanded(flex: 2, child: new DropdownButton(
                value: _currentLocationSelection,
                items: _locationDropDownMenuItems,
                onChanged: updateLocation,
              )));
      toolbarWidget.add(Expanded(flex: 1, child: new Text(LABEL_HAS)));
    } else {
      toolbarWidget.add(Expanded(flex: 1, child: new Text(LABEL_PROGRAM)));
    }
    toolbarWidget.add(Expanded(flex: 2, child: new DropdownButton(
                value: _firstTag,
                items: _tagDropDownMenuItems,
                onChanged: (String value) {setState(() {_firstTag = value;});},
              )));
    Row toolbar = Row(children: toolbarWidget);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          toolbar,
          ColorPicker(
            selectedIndex: _color,
            onTap: (index) {
              setState(() {
                _color = index;
              });
            },
          ),
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
              icon: Icon(Icons.note),
              hintText: HINT_TOPIC,
              labelText: LABEL_TOPIC,
            ),
            validator: (value) {
              validation(LABEL_TOPIC, value);
            },
            onSaved: (String value) {this._parentTitle = value;},
        // validator: _validateName,
          ),
          const SizedBox(height: 12.0),
          tagUI(context),
          const SizedBox(height: 12.0),
          topicImageUI(context), 
          const SizedBox(height: 12.0),
          TextFormField(
            initialValue: "",
            focusNode: _descFocus,
            onFieldSubmitted: (term) {
              fieldFocusChange(context, _descFocus, _showNameFocus);
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
              validation(LABEL_DETAIL, value);
            },
            onChanged: (value) {searchForKeywords(value);},
            onSaved: (String value) {this._desc = value;},
          ),
          Row(
            children: <Widget> [
                Checkbox(
                  focusNode: _showNameFocus,
                  value: _isShowName,
                  onChanged: (bool value) {
                      _isShowName = value;
                  }
                ),
                Text(LABEL_MUST_SHOW_NAME)
            ]
          ),
          RaisedButton(
            child: _buttonText,
            onPressed: _isSubmitDisable ? null : sendMessage,
          )
        ],
      )
    );
  }
}
