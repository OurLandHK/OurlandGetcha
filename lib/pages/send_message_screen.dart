import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ourland_native/helper/string_helper.dart';

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
import 'package:ourland_native/models/polling_model.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/color_picker.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

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

  List<DropdownMenuItem<String>> _messageTypeDropDownMenuItems;
  List<DropdownMenuItem<String>> _duationDropDownMenuItems;
  

  String _parentTitle;
  String _newTopicLabel;
  String _desc;
  List<String> _tags = [];
  String _messageType;
  String _duration;
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
  Widget _locationField;
  Polling _polling;
  DateTime _startDate;
  DateTime _endDate;
  TextEditingController _txt = TextEditingController();

  final FocusNode _locationFocus = FocusNode();  
  final FocusNode _titleFocus = FocusNode();  
  final FocusNode _descFocus = FocusNode();
  final FocusNode _startDateFocus = FocusNode();
  final FocusNode _endDateFocus = FocusNode();
  final FocusNode _pollingTitleFocus = FocusNode();  
  final FocusNode _pollingRangeFocus = FocusNode();
  final FocusNode _pollingMaxPollingFocus = FocusNode();
  final List<FocusNode> _pollingOptions = [];
  final FocusNode _sendButtonFocus = FocusNode();

  

  @override
  void initState() {
    super.initState();
    _pollingOptions.add(FocusNode());
    if(widget.searchingMsg == null) {
      _label = LABEL_REGION + ": ";
    } else {
      _label = widget.searchingMsg.text;
    }
    _locationField = TextField(
        controller: _txt,
        focusNode: _locationFocus,
        decoration: InputDecoration(
            hintText: LABEL_REGION0),
        keyboardType: TextInputType.text,
        onChanged: (value) {
          setState(() {
            _location = value;
            _messageLocation = null;
          });},
        onSubmitted: onSubmittedLocation);
    focusNode.addListener(onFocusChange);
    messageService = new MessageService(widget.user);
    userService = new UserService();
    _messageTypeDropDownMenuItems = getDropDownMenuItems(MESSAGE_TYPE_SELECTION, false);
    _messageType = _messageTypeDropDownMenuItems[0].value;
    _duationDropDownMenuItems = getDropDownMenuItems(DURATION_SELECTION, false);
    _duration = _duationDropDownMenuItems[0].value;
    
    
    _buttonText = LOCATION_NOT_VALIDATE;
    _sendButton = RaisedButton(focusNode: _sendButtonFocus, child: Text(_buttonText), onPressed: null);
    Random rng = new Random();
    _color = rng.nextInt(TOPIC_COLORS.length);
    _desc = "";
    _parentTitle = "";
    _isSubmitDisable = true;
    _polling = new Polling(pollingOptionValues: []);
    /*
    List<String> dropDownList = [LABEL_NEARBY];
    if(widget.user.homeAddress != null) {
      dropDownList.add(LABEL_REGION0);
    }
    if(widget.user.officeAddress != null) {
      dropDownList.add(LABEL_REGION1);
    }    
    */
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

  Widget renderMap(BuildContext context) {
    if(this._messageLocation == null) {
      return SizedBox(height: MAP_HEIGHT, child: Expanded(child: Text(LOCATION_NOT_VALIDATE, textAlign: TextAlign.center,)));
    } else {
      return ChatMap(
          topLeft: this._messageLocation,
          bottomRight: this._messageLocation,
          height: MAP_HEIGHT,
          markerList: [OurlandMarker(_label, this._messageLocation, 0, _label, "settings")],
          updateCenter: null,);
   }
  }

  Widget renderLocationField(BuildContext context) {
    return Row(children: [SizedBox(width: 12.0), Expanded(child: 
      _locationField), 
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

  void onSubmittedLocation(String dummy) {
    //fieldFocusChange(context, _locationFocus, _titleFocus);
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
      print("Pressed " + _location);
      _geolocator.placemarkFromAddress(_location, localeIdentifier: "zh_HK").then(
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
        _geolocator.placemarkFromAddress(_location, localeIdentifier: "en_HK").then(
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
          _scaffoldKey.currentState.showSnackBar(
            new SnackBar(content: new Text(NO_PLACE_CALLED + _location)));
        });
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

  void searchForKeywords(String desc) {
    this._desc = desc;
    String parseText = desc.replaceAll("\n", " ");
    List<String> tempTags = StringHelper.keywordSearch(parseText, "#");
    if(tempTags.length == 0) {
      tempTags = StringHelper.keywordSearch(parseText, "＃");
    }
    String tempLocation = "";

    tempLocation = StringHelper.parseAddress(this._desc);
    print(tempLocation);
    
    setState(() {
      _tags = tempTags;
      if(tempLocation != null && tempLocation.length >0) {
        _location = tempLocation;
        _txt.text = _location;
        _messageLocation = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    scheduleMicrotask(() => _swapValuable(context));

    Widget body = new WillPopScope(
      child: Form(
          key: _formKey,
          autovalidate: true,
//           onWillPop: _warnUserAboutInvalidData,
        child: formUI(context)
      ),
      onWillPop: onBackPress,
    );
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        backgroundColor: TOPIC_COLORS[_color],
        title: Row(children:[Text(
          LABEL_NEW,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        DropdownButton(
                value: _messageType,
                items: _messageTypeDropDownMenuItems,
                onChanged: (String value) {setState(() {_messageType = value;});},
                style: TextStyle(color: primaryColor, fontSize: 20.0, fontWeight: FontWeight.bold),
              )]),
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
    if (!_formKey.currentState.validate()) {
      return;
    }
//    If all data are correct then save data to out variables
    _formKey.currentState.save();
    if(_messageType != MESSAGE_TYPE_SELECTION[0]){
      _tags.insert(0, _messageType);
    }
    _tags = _tags.toSet().toList();
    Polling polling;
    DateTime startDate;
    DateTime endDate;
    String startTime;
    String duration;
    if(_messageType == MESSAGE_TYPE_SELECTION[1]) {
      duration = this._duration;
      startDate = DateTime.parse(DateFormat("yyyy-MM-dd").format(this._startDate));
      startTime = new DateFormat.Hm().format(this._startDate);
    }    
    if(_messageType == MESSAGE_TYPE_SELECTION[2]) {
      if(_polling.valid() && this._endDate.isAfter(this._startDate)) { // polling type
        polling = _polling;
        startDate = this._startDate;
        endDate = this._endDate;
      } else {
        polling = _polling;
        return;
      }
    }
    //var destBox = GeoHelper.findBoxGeo(this._messageLocation, 1000.0);
    SearchingMsg searchingMsg = SearchingMsg("", this._messageLocation, this._location, this._parentTitle, 
    widget.user.username, widget.user.avatarUrl, widget.user.uuid, widget.user.uuid,
    _tags, this._desc, null /*this._link*/,
    null, null, null, null, /*this._imageUrl, this._publicImageURL, this._thumbnailImageURL, this._thumbnailPublicImageURL, */
    startDate, startTime, duration, null, endDate, /*this._start, this._startTime, this._duration, this._interval, this._endDate,*/
    null, null, polling, /*this._everydayOpenning, this._weekdaysOpennings, this._polling,*/
    null);
    messageService.sendPendingSearchingMessage(searchingMsg, imageFile);
    onBackPress();
  }

  Widget tagUI(BuildContext context) {
    List<Chip> chips = [];
    this._tags.forEach((tag) {
      print(tag.length);
      chips.add(Chip(label: Text(tag)));
    });
    return Wrap(runSpacing: 4.0, spacing: 8.0, children: chips);
  }

  Widget renderExtendForm(BuildContext context) {
    Widget rv = Container();
    if(this._messageType == MESSAGE_TYPE_SELECTION[2]) { // polling
      rv= renderPollingForm(context);
    }
    if(this._messageType == MESSAGE_TYPE_SELECTION[1]) { // Single Event
      rv= renderSingleEventForm(context);
    }    
    return rv;
  }

  Widget renderSingleEventForm(BuildContext context) {
    final format = DateFormat("yyyy-MM-dd HH:mm");
    List<Widget> widgets = [
      const SizedBox(height: 12.0),
      Row(children: <Widget>[
        Expanded(child: 
          DateTimeField(
          focusNode: _startDateFocus,
          format: format,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              hintText: HINT_EVENT_START_DATE,
              labelText: LABEL_EVENT_START_DATE,
            ),
          onFieldSubmitted: (term) {
              fieldFocusChange(context, _startDateFocus, _endDateFocus);
          },
          onChanged: (dt) => this._startDate = dt,
          onSaved: (dt) => this._startDate = dt,
          onShowPicker: (context, currentValue) async {
            final date = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                initialDate: currentValue ?? DateTime.now(),
                lastDate: DateTime(2100));
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
              );
              return DateTimeField.combine(date, time);
            } else {
              return currentValue;
            }
          },
        )),       
        Expanded(child: 
          DropdownButtonFormField(
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              labelText: LABEL_EVENT_DURATION,
            ),
                value: _duration,
                items: _duationDropDownMenuItems,
                onChanged: (String value) {setState(() {_duration = value;});},
                style: TextStyle(color: primaryColor, fontSize: 20.0, fontWeight: FontWeight.bold),
          )), 
      ],),
    ];
    return Column(children: widgets);
  }  

  Widget renderPollingForm(BuildContext context) {
    void updatePollingOption(int i, String value) {
      Polling tempPolling = _polling;
      if(i< tempPolling.pollingOptionValues.length) {
        tempPolling.pollingOptionValues[i] = value;
      } else {
        if(value.length > 0) {
          tempPolling.pollingOptionValues.add(value);
          _pollingOptions.add(FocusNode());
        }
      }
      //setState(() {
        this._polling = tempPolling;
      //});
    }
    final format = DateFormat("yyyy-MM-dd");
    List<Widget> widgets = [
      const SizedBox(height: 12.0),
      // Polling Title
      TextFormField(
        focusNode: _pollingTitleFocus,
        onFieldSubmitted: (term) {
          fieldFocusChange(context, _pollingTitleFocus, _startDateFocus);
        },
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          filled: true,
          hintText: HINT_POLLING_TITLE,
          labelText: LABEL_POLLING_TITLE,
        ),
        /*
        validator: (value) {
          return validation(LABEL_TOPIC, value);
        },
        */
        onChanged: (String value) {this._polling.pollingTitle = value;},
        onSaved: (String value) {this._polling.pollingTitle = value;},
      ),
      const SizedBox(height: 12.0),
      Row(children: <Widget>[
        Expanded(child: 
          DateTimeField(
          focusNode: _startDateFocus,
          format: format,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              hintText: HINT_POLLING_START_DATE,
              labelText: LABEL_POLLING_START_DATE,
            ),
          onFieldSubmitted: (term) {
              fieldFocusChange(context, _startDateFocus, _endDateFocus);
          },
          onChanged: (dt) => this._startDate = dt,
          onSaved: (dt) => this._startDate = dt,
          onShowPicker: (context, currentValue) {
            return showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                initialDate: currentValue ?? DateTime.now(),
                lastDate: DateTime(2100));
          },
        )),       
        Expanded(child: 
          DateTimeField(
          focusNode: _endDateFocus,
          format: format,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              hintText: HINT_POLLING_END_DATE,
              labelText: LABEL_POLLING_END_DATE,
            ),
          onFieldSubmitted: (term) {
              fieldFocusChange(context, _endDateFocus, _pollingRangeFocus);
          },
          onChanged: (dt) => this._endDate = dt,
          onSaved: (dt) => this._endDate = dt,
          onShowPicker: (context, currentValue) {
            return showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                initialDate: currentValue ?? DateTime.now().add(Duration(days:14)),
                lastDate: DateTime(2100));
          },
        )), 
      ],),
      const SizedBox(height: 12.0),
      Row(children: <Widget>[
        Expanded(child: TextFormField(
          focusNode: _pollingRangeFocus,
          onFieldSubmitted: (term) {
            fieldFocusChange(context, _pollingRangeFocus, _pollingMaxPollingFocus);
          },
          keyboardType: TextInputType.number,
          initialValue: '1',
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            filled: true,
            hintText: LABEL_KM,
            labelText: LABEL_VOTE_RANGE,
          ),
          /*
          validator: (value) {
            return validation(LABEL_TOPIC, value);
          },
          */
          onChanged: (String value) {this._polling.pollingRange = int.parse(value);},
          onSaved: (String value) {this._polling.pollingRange = int.parse(value);},
        )),
        Expanded(child: TextFormField(
          focusNode: _pollingMaxPollingFocus,
          onFieldSubmitted: (term) {
            fieldFocusChange(context, _pollingMaxPollingFocus, _pollingMaxPollingFocus);
          },
          keyboardType: TextInputType.number,
          initialValue: '1',
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            filled: true,
            labelText: LABEL_VOTE_MAX,
          ),
          /*
          validator: (value) {
            return validation(LABEL_TOPIC, value);
          },
          */
          onChanged: (String value) {this._polling.numOfMaxPolling = int.parse(value);},
          onSaved: (String value) {this._polling.numOfMaxPolling = int.parse(value);},
        )),
      ],),
    ];
    int numberOfPolling = 1;
    if(this._polling.pollingOptionValues != null) {
      numberOfPolling = this._polling.pollingOptionValues.length + 1;
    }
    for(int i = 0; i < numberOfPolling; i++) {  
      const String labelText = LABEL_POLLING_OPTION;
      FocusNode nextFocus = _sendButtonFocus;
      if(i + 1 != numberOfPolling) {
        nextFocus = _pollingOptions[i + 1];
      }
      widgets.add(SizedBox(height: 12.0));
      widgets.add(
        TextFormField(
          focusNode: _pollingOptions[i],
          onFieldSubmitted: (term) {
            fieldFocusChange(context, _pollingOptions[i], nextFocus);
          },
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            filled: true,
            labelText: labelText,
          ),
          onChanged: (String value) {updatePollingOption(i, value);},
          onSaved: (String value) {updatePollingOption(i, value);},
        )
      );   
    }
    return Column(children: widgets);
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
          tagUI(context),
          const SizedBox(height: 12.0),
          topicImageUI(context), 
          const SizedBox(height: 12.0),
          TextFormField(
            focusNode: _descFocus,
            onFieldSubmitted: (term) {
              fieldFocusChange(context, _descFocus, _locationFocus);
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
            onChanged: (String value) {searchForKeywords(value);},
            onSaved: (String value) {this._desc = value;},
          ),
          renderLocationField(context), 
          renderMap(context),
          renderExtendForm(context),
          _sendButton
        ],
      )
    );
  }
}
