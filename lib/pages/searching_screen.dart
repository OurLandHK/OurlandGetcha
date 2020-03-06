import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ourland_native/models/searching_msg_model.dart';
import 'package:ourland_native/models/user_model.dart' as prefix0;
import 'package:ourland_native/widgets/searching_msg_widget.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

//import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/topic_message.dart';
import 'package:ourland_native/pages/settings.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geodesy/geodesy.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;

class SearchingScreen extends StatefulWidget {
  final GeoPoint fixLocation;
  final User user;
  final Function getCurrentLocation;
  final SharedPreferences preferences;
  final String streetAddress;
  final String tag;
  SearchingScreenState _state;

  SearchingScreen({Key key, @required this.user, @required this.getCurrentLocation, @required this.preferences, this.fixLocation, this.streetAddress, this.tag}) : super(key: key);
  @override
  State createState() {
    /*
    bool _tempExpand = true;
    try {
      _tempExpand = preferences.getBool('TOPIC_EXPANDED');
      print('TOPIC_EXPAND $_tempExpand');
    } catch (Exception) {
      _tempExpand = null;
    } 
    if(_tempExpand == null) {
      _tempExpand = true;
      preferences.setBool('TOPIC_EXPANDED', _tempExpand);
    }
    */
    _state = new SearchingScreenState(fixLocation: this.fixLocation);
    return _state;
  } 
}
class SearchingScreenState extends State<SearchingScreen> with TickerProviderStateMixin  {
  SearchingScreenState({Key key, @required this.fixLocation});
  GeoPoint fixLocation;
  MessageService messageService;
  /*
  ChatMap chatMap;
  ChatMap _pendingChatMap;
  */
  List<OurlandMarker> _markerList;
  List<OurlandMarker> _pendingMarkerList;

  var listMessage;

  bool isLoading;

  // use to get current location
  GeoPoint messageLocation;

  String _currentLocationSelection;
  bool _locationPermissionGranted = true;
  //List<DropdownMenuItem<String>> _locationDropDownMenuItems;  
  List<SearchingMsg> _searchingMsgs;
  List<DropdownMenuItem<String>> _tagDropDownMenuItems;
  Map<String, int> _tagCountMap;

  String _firstTag = "";
  String _searchingTitle = LABEL_NEARBY;

//  Geolocator _geolocator = new Geolocator();
  LocationOptions locationOptions = new LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  GeolocationStatus geolocationStatus = GeolocationStatus.denied;
  String error;

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();
  Function _updateCenter;

  

  @override
  void initState() {
    super.initState();
    this._markerList = [];
    this._pendingMarkerList =[];  
    this._searchingMsgs = [];
    this._tagCountMap = new Map();
    this._tagDropDownMenuItems = getDropDownMenuItems(new List<String>(), true);
    isLoading = false;
    GeoPoint mapCenter = this.fixLocation;
    if(mapCenter == null) {
      Map map = widget.getCurrentLocation();
      mapCenter = map['GeoPoint'];
      _locationPermissionGranted = map['LocationPermissionGranted'];
    } else {
      if(widget.streetAddress != null) {
        _searchingTitle = widget.streetAddress;
      } else {
        _searchingTitle = "(${this.fixLocation.longitude},${this.fixLocation.latitude})";
      }
    }
    if(widget.tag != null && widget.tag.length !=0) {
      _searchingTitle += " " + widget.tag + " ";
    }
    this.messageLocation = mapCenter;
    focusNode.addListener(onFocusChange);
    messageService = new MessageService(widget.user);
  }
  

  Future<void> setLocation(GeoPoint location) async {
    GeoPoint _temp = location;
    if(location == null) {
      Map map = await widget.getCurrentLocation();
      _temp = map['GeoPoint'];
      //rv['LocationPermissionGranted']
    }
    if(_temp != null && _temp.latitude == this.messageLocation.latitude && _temp.longitude == this.messageLocation.longitude ) {
      _temp  = null;
    }
    if(_temp != null && _temp.latitude != null) {
      setState(() {
        this.fixLocation = _temp;
        this.messageLocation = _temp;
        this._markerList = [];
        this._pendingMarkerList =[];       
      });
      print("setLocation ${this.messageLocation.latitude}");
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
      });
    }
  }

  Widget buildItem(String messageId, SearchingMsg searchingMsg, BuildContext context) {
    Widget rv; 
    GeoPoint location = searchingMsg.geolocation;
    this._pendingMarkerList.add(OurlandMarker(messageId, location, 0, searchingMsg.text, searchingMsg.name));
    GeoPoint _messageLocation;
    if(this.fixLocation != null) {
      _messageLocation = this.fixLocation;
    } else {
      if(this.messageLocation != null) {
        _messageLocation = new GeoPoint(this.messageLocation.latitude, this.messageLocation.longitude);
      }
    }
    rv = new SearchingMsgWidget(preferences: widget.preferences,key : Key(searchingMsg.key), user: widget.user, searchingMsg: searchingMsg, getCurrentLocation:  widget.getCurrentLocation, messageLocation: _messageLocation, locationPermissionGranted: _locationPermissionGranted ,pending: false,);
    return rv;
  }

  @override
  Widget build(BuildContext context) {

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

    void _swapValuable(BuildContext context) {
//    print("Marker Length 2 ${this._markerList.length} ${this._pendingMarkerList.length}");
      if(_tagDropDownMenuItems.length == 1 || _tagDropDownMenuItems.length != (this._tagCountMap.length + 1)){
        setState(() {
          _tagDropDownMenuItems = getDropDownMenuItems(this._tagCountMap.keys.toList(), true);
        });
      }
    }

    void updateTagCount(SearchingMsg msg) {
      for(String tag in msg.tagfilter) {
        if(_tagCountMap[tag] == null) {
          _tagCountMap[tag] = 0;
        } else {
          _tagCountMap[tag]++;
        }
      }
    }

    void buildSearchingMsgs(List<Map> documents) {
      _searchingMsgs = [];
      _tagCountMap = new Map<String, int>();
//      for (SearchingMsg searchingMsg in documents) {
      for (Map data in documents) {
        SearchingMsg searchingMsg = SearchingMsg.fromMap(data); 
        if(_firstTag.length == 0 || searchingMsg.tagfilter.contains(_firstTag)) {
          updateTagCount(searchingMsg);
        _searchingMsgs.add(searchingMsg);
        } 
      }
    }

    List<Widget> buildGrid(List<SearchingMsg> documents, BuildContext context) {
      List<Widget> _gridItems = [];
      for (SearchingMsg searchingMsg in documents) {
        if(widget.user == null || !widget.user.blockUsers.contains(searchingMsg.uid)) {
          _gridItems.add(buildItem(searchingMsg.key, searchingMsg, context));
        }
      }
      return _gridItems;
    }  


    Widget buildListView(BuildContext context) {
      this._pendingMarkerList.clear();
      bool canViewHide = false;
      if(widget.user != null && widget.user.globalHideRight) {
        canViewHide = true;
      }
        return new StreamBuilder<List<Map>>(
        stream: this.messageService.getSearchingMsgSnap(this.messageLocation, 2500, widget.tag),
            builder: (BuildContext context, AsyncSnapshot<List<Map>> snapshot) {
          if (!snapshot.hasData) {
            //print("StreamBuilder No Data ${snapshot.data}");
            return new Center(child: new CircularProgressIndicator());
          } else {
            if(snapshot.data.length > 0) {
              //print("snapshot.data.length ${snapshot.data.length}");
              buildSearchingMsgs(snapshot.data);
              List<Widget> children = buildGrid(_searchingMsgs, context);
              return ListView(
                padding: EdgeInsets.symmetric(vertical: 8.0), 
                children: children);
            } else {
              return new Container(child: Text(LABEL_CHOICE_OTHER_TAG,
              style: Theme.of(context).textTheme.headline));
            }
            //staggeredTiles: generateRandomTiles(snapshot.data.length),
          }
        },
      );
    }   

    List<Widget> buildToolBarWidget(BuildContext context) {
      return  <Widget> [
                Text(_searchingTitle, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                Expanded(flex: 1, child: Text(LABEL_HAS, style: Theme.of(context).textTheme.subhead, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: DropdownButton(
                  value: _firstTag,
                  items: _tagDropDownMenuItems,
                  style: Theme.of(context).textTheme.subhead,
                  onChanged: (String value) {setState(() {_firstTag = value;});},
                )),
              ];
    }
        
    WidgetsBinding.instance
      .addPostFrameCallback((_) => _swapValuable(context));
    return new Scaffold(
        appBar: new AppBar(
          title: Row(children: buildToolBarWidget(context)),
          centerTitle: true,
          elevation: 0.7,
          actionsIconTheme: Theme.of(context).primaryIconTheme,
          //bottom: toolBar,
        ),
        body: Container(
          color: Colors.white,
          child:
              Stack(
                children: <Widget>[
                  buildListView(context),
                  buildLoading(),
                ],
              )
//            ]
//          ),
        ),
    );     
  }
}

