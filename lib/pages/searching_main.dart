import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/pages/searching_screen.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/widgets/searching_msg_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:geolocator/geolocator.dart';

// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class SearchingMain extends StatefulWidget  {
  final GeoPoint fixLocation;
  final User user;
  final Function getCurrentLocation;
  final SharedPreferences preferences;
  final bool disableLocation;

  SearchingMain({Key key, @required this.user, @required this.getCurrentLocation, @required this.preferences, this.fixLocation, @required this.disableLocation}) : super(key: key) {
  }

  @override
  _SearchingMainState createState() => new _SearchingMainState();
}
class _SearchingMainState extends State<SearchingMain>{
  bool _isSubmitDisable;
  String _streetAddress;
  MessageService _messageService;
  List<String> _tagList = [];
  Geolocator _geolocator = new Geolocator();
  Topic _recentTopic;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    if(widget.disableLocation) {
      _isSubmitDisable = true;
    } else {
      _isSubmitDisable = false;
    }
    super.initState();
    _messageService = new MessageService(widget.user);
    initPlatformState();

  }

  initPlatformState() async {
    _messageService.getLatestTopic().then((topic) {
      //print("${topic.id}");
      setState(() {
        _recentTopic = topic;
      });
    });
    _messageService.getSearchFirstPage().then((searchFirstPage){
      setState(() {
        _tagList = searchFirstPage['Tags'].cast<String>();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    void onPressed(context, tag)  {
      GeoPoint newLocation; 
      if(_streetAddress != null && _streetAddress.length > 0) {
      _geolocator.placemarkFromAddress(_streetAddress).then((List<Placemark> placemark) {
        Position pos = placemark[0].position;
        newLocation = new GeoPoint(pos.latitude, pos.longitude);
        Navigator.of(context).push(
          new MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return new SearchingScreen(user: widget.user, getCurrentLocation: widget.getCurrentLocation, preferences: widget.preferences, fixLocation: newLocation, streetAddress: _streetAddress, tag: tag);
            },
          ),
        );
      }, onError: (e) {
              _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: new Text(NO_PLACE_CALLED + _streetAddress)));
      });
      } else {
        Navigator.of(context).push(
          new MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return new SearchingScreen(user: widget.user, getCurrentLocation: widget.getCurrentLocation, preferences: widget.preferences, fixLocation: newLocation, tag: tag);
            },
          ),
        );
      }
    }

    void onChanged(String value) {
      bool __isSubmitDisable = true;
      if((value != null && value.length > 0) || widget.disableLocation == false) {
        __isSubmitDisable = false;
      } 
      //print("onChanged ${value} ${__isSubmitDisable.toString()}");
      setState(() {
        _streetAddress = value;
        _isSubmitDisable = __isSubmitDisable;
      });
    }

    Widget renderLocationField() {
      String hint = HINT_SEARCH_NEARBY_LOCATION;
      if(widget.disableLocation) {
        hint = HINT_SEARCH_LOCATION;
      }

      return PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: Row(children: [SizedBox(width: 12.0), Expanded(child: TextField(
                  decoration: InputDecoration(
                      hintText: hint),
                  keyboardType: TextInputType.text,
                  //onChanged: (value) {_streetAddress = value;})),
                  //onChanged: (value) {setState(() {_streetAddress = value;});},
                  onChanged: (value) => onChanged(value))), 
                  Material(child: Container(
                    decoration: BoxDecoration(
                          border: Border.all(width: 0.5, color: Colors.grey),
                        ),
                      child: IconButton(icon: Icon(Icons.location_searching), onPressed: _isSubmitDisable ? null : () => onPressed(context, "")))),
                  SizedBox(width: 12.0)]));
    }

    Row renderTagButtons(List<String> tags) {
      List<Widget> widgets = tags
                .map((tag) => Expanded(
                  //flex: 1,
                  child:OutlineButton(
                      child: Text(tag),                      
                      onPressed: _isSubmitDisable ? null : () => onPressed(context, tag),
                      borderSide: BorderSide(
                        color: Colors.blue, //Color of the border
                        style: BorderStyle.solid, //Style of the border
                        width: 0.8, //width of the border
                      )
                    ))
                )
                .toList();
      return(Row(children: widgets));
    }
    List<Widget> widgetList = [];

    if(_tagList != null && _tagList.length > 0) {
      List<String> firstButtonRow = _tagList.sublist(0, (_tagList.length/2).round());
      List<String> secondButtonRow = _tagList.sublist((_tagList.length/2).round(), _tagList.length);
      widgetList = [
        renderTagButtons(firstButtonRow),
        renderTagButtons(secondButtonRow)];
    }
    if(_recentTopic != null) {
      widgetList.add(Text(LABEL_RECENT_SEARCHING));
      widgetList.add(new SearchingMsgWidget(
        user: widget.user,
        searchingMsg: _recentTopic.searchingMsg,
        messageLocation: _recentTopic.geoCenter,
        getCurrentLocation: widget.getCurrentLocation,
        locationPermissionGranted: !widget.disableLocation));
    }

    return Scaffold(
        key: _scaffoldKey,
        appBar: renderLocationField(),
        body: ListView(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          children: widgetList
        ));
/*        body: Column(children: widgetList
          ));
          */
  } 
}
