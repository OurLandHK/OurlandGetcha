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
import 'package:ourland_native/widgets/Topic_message.dart';
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
  SearchingScreenState _state;

  SearchingScreen({Key key, @required this.user, @required this.getCurrentLocation, @required this.preferences, this.fixLocation}) : super(key: key);
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
//  bool _locationPermissionGranted = false;
  List<DropdownMenuItem<String>> _locationDropDownMenuItems;  

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
    isLoading = false;
    GeoPoint mapCenter = widget.getCurrentLocation();
    this.messageLocation = mapCenter;
    focusNode.addListener(onFocusChange);
    messageService = new MessageService(widget.user);

  if(this.fixLocation != null) {
    _searchingTitle = this.fixLocation.toString();
  }

/*        // Init UI
  List<String> dropDownList = [LABEL_NEARBY];
    if(widget.user != null) {
      dropDownList = [LABEL_NEARBY, LABEL_REGION0, LABEL_REGION1];
    }
    _locationDropDownMenuItems = getDropDownMenuItems(dropDownList ,false);
    _currentLocationSelection = _locationDropDownMenuItems[0].value;    
    _updateCenter = setLocation;
    bool _tempExpand = true;
    try {
      _tempExpand = widget.preferences.getBool('TOPIC_EXPANDED');
    } catch (Exception) {
      widget.preferences.setBool('TOPIC_EXPANDED', _tempExpand);
    } 
    this.expanded = _tempExpand;
  */
  }


//  List<DropdownMenuItem<String>> _tagDropDownMenuItems = getDropDownMenuItems(TAG_SELECTION , true);

  Future<void> setLocation(GeoPoint location) async {
    GeoPoint _temp = location;
    if(location == null) {
      _temp = await widget.getCurrentLocation();
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

  Widget buildItem(String messageId, SearchingMsg searchingMsg, Function _onTap, BuildContext context) {
    Widget rv; 
    int type = 0;
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
    rv = new SearchingMsgWidget(user: widget.user, searchingMsg: searchingMsg, onTap: _onTap, messageLocation: _messageLocation);
    return rv;
  }

  @override
  Widget build(BuildContext context) {
    bool isAddressWithinTopic(GeoPoint address, SearchingMsg searchingMsg1) {
      Geodesy geodesy = Geodesy();
      bool rv = false;
      LatLng l1 = new LatLng(address.latitude, address.longitude);
      LatLng searchingMsg = new LatLng(searchingMsg1.geolocation.latitude, searchingMsg1.geolocation.longitude);
      if(geodesy.distanceBetweenTwoGeoPoints(l1, searchingMsg, null) < 2500) {
        rv = true;
      } 
      return rv;
    }

    void _onTap(SearchingMsg searchingMsg, String parentTitle, GeoPoint messageLocation) async {
      //GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      GeoPoint _messageLocation = messageLocation;
      if(_messageLocation == null && this.fixLocation != null) {
        _messageLocation = this.fixLocation;
      } 
      if(_messageLocation == null && this.messageLocation != null) {
        _messageLocation = new GeoPoint(this.messageLocation.latitude, this.messageLocation.longitude);
      }
      bool enableSendButton = false;
      // Check for previous edit topic
      if(widget.user != null) {
        UserService userService = new UserService();
        RecentTopic recentTopic = await userService.getRecentTopic(widget.user.uuid, searchingMsg.key);
        if(recentTopic != null) {
          print("Recent Topic");
          _messageLocation = recentTopic.messageLocation;
          enableSendButton = true;
        } else {
          if(widget.user.homeAddress != null) {
            print("Home");
            enableSendButton = isAddressWithinTopic(widget.user.homeAddress, searchingMsg);
          }
          if(!enableSendButton && widget.user.officeAddress != null) {
            print("Office");
            enableSendButton = isAddressWithinTopic(widget.user.officeAddress, searchingMsg);
          }
          if(!enableSendButton) {
            print("Current");
            GeoPoint mapCenter = widget.getCurrentLocation();
            enableSendButton = isAddressWithinTopic(mapCenter, searchingMsg);
          }
        }
      } 
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            Key chatKey = new Key(searchingMsg.key);
            return new ChatScreen(key: chatKey, user : widget.user, topic: null, parentTitle: parentTitle, enableSendButton: enableSendButton, messageLocation: _messageLocation);
          },
        ),
      );
    }
/*
    List<Widget> buildToolBar(BuildContext context) {
      return  <Widget> [
                Expanded(flex: 1, child: Text(LABEL_IN, style: Theme.of(context).textTheme.subhead, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: DropdownButton(
                  value: _currentLocationSelection,
                  items: _locationDropDownMenuItems,
                  onChanged: updateLocation,
                  style: Theme.of(context).textTheme.subhead
                )),
                Expanded(flex: 1, child: Text(LABEL_HAS, style: Theme.of(context).textTheme.subhead, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: DropdownButton(
                  value: _firstTag,
                  items: _tagDropDownMenuItems,
                  style: Theme.of(context).textTheme.subhead,
                  onChanged: (String value) {setState(() {_firstTag = value;});},
                )),
                IconButton(
                  icon: Icon(Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        expanded = !expanded;
                      });
                      widget.preferences.setBool('TOPIC_EXPANDED', expanded);
                    },
                ),
              ];
    }
    */
    PreferredSizeWidget appBar;
    Widget map = Container(height: MAP_HEIGHT);
    if(this._markerList.length == this._pendingMarkerList.length) {
      map =  ChatMap(topLeft: this.messageLocation, bottomRight: this.messageLocation,  height: MAP_HEIGHT, markerList: this._markerList, updateCenter: _updateCenter,);
    } else {
      map =  ChatMap(topLeft: this.messageLocation, bottomRight: this.messageLocation,  height: MAP_HEIGHT, markerList: this._pendingMarkerList, updateCenter: _updateCenter);
    }
    WidgetsBinding.instance
      .addPostFrameCallback((_) => _swapValuable(context));
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(
            _searchingTitle,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0.7,
          actionsIconTheme: Theme.of(context).primaryIconTheme,
        ),
        body: Container(
          color: Colors.white,
          child: new Stack(
            children: <Widget>[
            // buildScrollView(_onTap, context),
              buildListView(_onTap, context),
              buildLoading(),
            ],
          ),
        ),
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

  void _swapValuable(BuildContext context) {
//    print("Marker Length 2 ${this._markerList.length} ${this._pendingMarkerList.length}");
    if(this._markerList.length != this._pendingMarkerList.length) {
      List<OurlandMarker> tempList = new List<OurlandMarker>();
      for(int i = 0; i <  this._pendingMarkerList.length; i++) {
        tempList.add(this._pendingMarkerList[i]);
      }
      setState(() {
        this._markerList = tempList;
      });      
    }
  }



  Widget buildListView(Function _onTap, BuildContext context) {
    this._pendingMarkerList.clear();
    bool canViewHide = false;
    if(widget.user != null && widget.user.globalHideRight) {
      canViewHide = true;
    }
    print("StreamBuilder ${this.messageLocation.latitude}");
    //return new StreamBuilder<List<SearchingMsg>>(
    return new StreamBuilder<List<Map>>(
      stream: this.messageService.getSearchingMsgSnap(this.messageLocation, 2500, _firstTag),
//      builder: (BuildContext context, AsyncSnapshot<List<SearchingMsg>> snapshot) {
        builder: (BuildContext context, AsyncSnapshot<List<Map>> snapshot) {
        if (!snapshot.hasData) {
          print("StreamBuilder No Data ${snapshot.data}");
          return new Center(child: new CircularProgressIndicator());
        } else {
          if(snapshot.data.length > 0) {
            print("snapshot.data.length ${snapshot.data.length}");
            List<Widget> children =  buildGrid(snapshot.data, _onTap, context);
            /*
            return ListView(
              padding: EdgeInsets.symmetric(vertical: 8.0), 
              children: children);
            */
            return new StaggeredGridView.count(
              physics: new BouncingScrollPhysics(),
              crossAxisCount: 2,
              children: children, 
              staggeredTiles: staggeredTileBuilder(children),
            );
          } else {
            return new Container(child: Text(LABEL_CHOICE_OTHER_TAG,
            style: Theme.of(context).textTheme.headline));
          }
          //staggeredTiles: generateRandomTiles(snapshot.data.length),
        }
      },
    );
  }

  List<StaggeredTile> staggeredTileBuilder(List<Widget> widgets) {
    List<StaggeredTile> _staggeredTiles = [];
    for (Widget widget in widgets) {
      _staggeredTiles.add(new StaggeredTile.fit(2));
    }
    return _staggeredTiles;
  }

  //List<Widget> buildGrid(List<SearchingMsg> documents, Function _onTap, BuildContext context) {
  List<Widget> buildGrid(List<Map> documents, Function _onTap, BuildContext context) {
    List<Widget> _gridItems = [];
//    for (SearchingMsg searchingMsg in documents) {
    for (Map map in documents) {
      SearchingMsg searchingMsg = SearchingMsg.fromMap(map);
      _gridItems.add(buildItem(searchingMsg.key, searchingMsg, _onTap, context));
    }
    return _gridItems;
  }  
}

