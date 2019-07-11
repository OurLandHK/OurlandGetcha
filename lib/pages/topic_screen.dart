import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

//import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/widgets/chat_map.dart';
import 'package:ourland_native/widgets/Topic_message.dart';
import 'package:ourland_native/pages/settings.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

//final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;

class TopicScreen extends StatefulWidget {
  final GeoPoint fixLocation;
  final User user;
  final Function getCurrentLocation;
  TopicScreenState _state;

  TopicScreen({Key key, @required this.user, @required this.getCurrentLocation, this.fixLocation}) : super(key: key);
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
  /*
  ChatMap chatMap;
  ChatMap _pendingChatMap;
  */
  List<OurlandMarker> _markerList;
  List<OurlandMarker> _pendingMarkerList;

  var listMessage;
  SharedPreferences prefs;

  bool isLoading;
  bool _expanded;

  // use to get current location
  GeoPoint messageLocation;

  String _currentLocationSelection;
  bool _locationPermissionGranted = false;
  List<DropdownMenuItem<String>> _locationDropDownMenuItems;  

  String _firstTag = "";

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
    this._markerList = [];
    this._pendingMarkerList =[];  
    _expanded = true;

    isLoading = false;
    GeoPoint mapCenter = widget.getCurrentLocation();
    this.messageLocation = mapCenter;
        // Init UI
    List<String> dropDownList = [LABEL_NEARBY];
    if(widget.user != null) {
      dropDownList = [LABEL_NEARBY, LABEL_REGION0, LABEL_REGION1];
    }
    _locationDropDownMenuItems = getDropDownMenuItems(dropDownList ,false);
    _currentLocationSelection = _locationDropDownMenuItems[0].value;
  }


  List<DropdownMenuItem<String>> _tagDropDownMenuItems = getDropDownMenuItems(TAG_SELECTION , true);

  void setLocation(GeoPoint location) {
    //print("${location}");
    GeoPoint _temp = location;
    if(location == null) {
      _temp = widget.getCurrentLocation();
    }
    setState(() {
      this.fixLocation = _temp;
      this.messageLocation = _temp;
      this._markerList = [];
      this._pendingMarkerList =[];  
    });
    print("setLocation ${this.messageLocation.latitude}");
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
      });
    }
  }

  Widget buildItem(String messageId, Topic topic, Function _onTap, BuildContext context) {
    Widget rv; 
    int type = 0;
    GeoPoint location = topic.geoCenter;
/*
    if(this._pendingChatMap != null) {
      this._pendingChatMap.addLocation(messageId, location, topic.topic, type, topic.createdUser.username);
    } else {
      this.chatMap.addLocation(messageId, location, topic.topic, type, topic.createdUser.username);
    }
*/    
    this._pendingMarkerList.add(OurlandMarker(messageId, location, type, topic.topic, topic.createdUser.username));
    GeoPoint _messageLocation;
    if(this.fixLocation != null) {
      _messageLocation = this.fixLocation;
    } else {
      if(this.messageLocation != null) {
        _messageLocation = new GeoPoint(this.messageLocation.latitude, this.messageLocation.longitude);
      }
    }
    rv = new TopicMessage(user: widget.user, topic: topic, onTap: _onTap, messageLocation: _messageLocation);
    return rv;
  }

  @override
  Widget build(BuildContext context) {
      void showHome() {
        print("Show Home ${widget.user.username}");
        if(widget.user.homeAddress != null) {
          setLocation(widget.user.homeAddress);
        } else {
          Navigator.of(context).push(
            new MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return new UpdateLocationScreen(locationType: LABEL_REGION0, user: widget.user);
              },
            ),
          );
        }
      }
      void showOffice() {
        if(widget.user.officeAddress != null) {
          setLocation(widget.user.officeAddress);
        } else {
          Navigator.of(context).push(
            new MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return new UpdateLocationScreen(locationType: LABEL_REGION1, user: widget.user);
              },
            ),
          );
        }
      }
      void showNearby() {
        setLocation(null);
      }
      void updateLocation(String locationSelection) {
        bool isFabShow;
        switch(locationSelection) {
          case LABEL_REGION0:
            showHome();
            //_nearBySelection.setLocation(widget.user.homeAddress);
            if(widget.user.homeAddress == null) {
              isFabShow = false;
            } else {
              isFabShow = true;         
            }
            break;
          case LABEL_REGION1:
            showOffice();
            //_nearBySelection.setLocation(widget.user.officeAddress);
            if(widget.user.officeAddress == null) {
              isFabShow = false;
            } else {
              isFabShow = true;           
            }
            break;          
          default:
            isFabShow = true;
            showNearby();
            //_nearBySelection.setLocation(null);
            
        }
        setState(() {
          this._currentLocationSelection = locationSelection; 
          //this.chatMap = null;
        });
      }   

    void _onTap(Topic topic, String parentTitle, GeoPoint messageLocation) {
      //GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      GeoPoint _messageLocation = messageLocation;
      if(_messageLocation == null && this.fixLocation != null) {
        _messageLocation = this.fixLocation;
      } 
      if(_messageLocation == null && this.messageLocation != null) {
        _messageLocation = new GeoPoint(this.messageLocation.latitude, this.messageLocation.longitude);
      }
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new ChatScreen(user: widget.user, topic: topic, parentTitle: parentTitle, messageLocation: _messageLocation);
          },
        ),
      );
    }

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
                        _expanded = !_expanded;
                      });
                    },
                ),
              ];
    }
    PreferredSizeWidget appBar;
    Widget map = Container(height: MAP_HEIGHT);
//    print("Marker Length 1 ${this._markerList.length} ${this._pendingMarkerList.length}");
    if(this._markerList.length == this._pendingMarkerList.length) {
      map =  ChatMap(topLeft: this.messageLocation, bottomRight: this.messageLocation,  height: MAP_HEIGHT, markerList: this._markerList);
    } else {
      map =  ChatMap(topLeft: this.messageLocation, bottomRight: this.messageLocation,  height: MAP_HEIGHT, markerList: this._pendingMarkerList);
    }
    if(_expanded) {
      _pendingMarkerList.clear();
      appBar = PreferredSize(
          preferredSize: Size.fromHeight(MAP_HEIGHT), // here the desired height
            child: new AppBar( 
              //flexibleSpace: (this.chatMap != null) ? this.chatMap : new Container(height: MAP_HEIGHT),
              flexibleSpace: map,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(100), // here the desired height
                child: Opacity(opacity: 0.6, child: Container(decoration: BoxDecoration(color: Theme.of(context).backgroundColor), child:Row(children: buildToolBar(context)))),
              ),
            ),
        );
    } else {
      _pendingMarkerList.clear();
      appBar = new AppBar(flexibleSpace: PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: Row(children: buildToolBar(context))));
    }
    WidgetsBinding.instance
      .addPostFrameCallback((_) => _swapMap(context));
    return new Scaffold(
        appBar: appBar,
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

  void _swapMap(BuildContext context) {
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
    return new StreamBuilder<List<Topic>>(
      stream: this.messageService.getTopicSnap(this.messageLocation, 2500, _firstTag),
      builder: (BuildContext context, AsyncSnapshot<List<Topic>> snapshot) {
        if (!snapshot.hasData) {
          return new Center(child: new CircularProgressIndicator());
        } else {
          if(snapshot.data.length > 0) {
            List<Widget> children =  buildGrid(snapshot.data, _onTap, context);
            return new StaggeredGridView.count(
              physics: new BouncingScrollPhysics(),
              crossAxisCount: 4,
              children: children, 
              staggeredTiles: staggeredTileBuilder(children),
            );
          } else {
            return new Container(child: Text(LABEL_CHOICE_OTHER_TAG,
            style: Theme.of(context).textTheme.headline));
          }
          //staggeredTiles: generateRandomTiles(snapshot.data.length),
        };
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

  List<Widget> buildGrid(List<Topic> documents, Function _onTap, BuildContext context) {
    List<Widget> _gridItems = [];
    for (Topic topic in documents) {
      _gridItems.add(buildItem(topic.id, topic, _onTap, context));
    }
    return _gridItems;
  }  
}

