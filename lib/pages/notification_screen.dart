import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
//import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/widgets/Topic_message.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class NotificationScreen extends StatefulWidget {
  final User user;
  NotificationScreenState _state;

  NotificationScreen({Key key, @required this.user}) : super(key: key);

  @override
  State createState() {
    _state = new NotificationScreenState();
    return _state;
  } 
}
class NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin  {
  NotificationScreenState({Key key});
  MessageService messageService;
  UserService userService;
  SharedPreferences prefs;
  TabController _tabController;

  Position _currentLocation;
  GeoPoint messageLocation;

  StreamSubscription<Position> _positionStream;

  Geolocator _geolocator = new Geolocator();
  LocationOptions locationOptions = new LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  GeolocationStatus geolocationStatus = GeolocationStatus.denied;
  bool isLoading;
  String error;

  // use to get current location
  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
 
  @override
  void initState() {
    super.initState();
    messageService = new MessageService(widget.user);
    userService = new UserService();

    isLoading = false;
    int tabLength = 1;
    if(widget.user != null) {
      tabLength++;
    }
    _tabController = new TabController(vsync: this, initialIndex: 0, length: tabLength);
    initPlatformState();
    _positionStream = _geolocator.getPositionStream(locationOptions).listen(
      (Position position) {
        if(position != null) {
          print('initState Poisition ${position}');
          _currentLocation = position;
          GeoPoint mapCenter = new GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
          this.messageLocation = mapCenter;
        }
      });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
      Position location;
      // Platform messages may fail, so we use a try/catch PlatformException.

      try {
        geolocationStatus = await _geolocator.checkGeolocationPermissionStatus();
        location = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
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
          }
      });
  }

  void onFocusChange() {
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabWidget = [];
    List<Widget> tabBarView = [];
    tabWidget.add(Tab(
                child: new Row(children: <Widget>[
                  new Icon(Icons.wallpaper),
                  new Text(LABEL_BROADCAST),
                ])
              ));
    tabBarView.add(buildBroadcast(context));    
    if(widget.user != null) {
      tabWidget.add(Tab(
                  child: new Row(children: <Widget>[
                    new Icon(Icons.bookmark),
                    new Text(LABEL_BOOKMARK),
                  ])
              ));
      tabBarView.add(buildNotification(context));
    }
    return 
      new Scaffold(
        appBar: new AppBar(
          title: new TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: tabWidget
          ),
        ),
        body:new TabBarView(
          controller: _tabController,
          children: tabBarView,
        ),     
    );
  }
  Widget buildNotification(BuildContext context) {
    void _onNotificationTap(Topic topic, String parentTitle, GeoPoint lastAccessLocation) {
      GeoPoint _messageLocation = lastAccessLocation;
      //GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new ChatScreen(user: widget.user, topic: topic, parentTitle: parentTitle, enableSendButton: true, messageLocation: _messageLocation);
          },
        ),
      );
    }

    return Stack(
      children: <Widget>[
        buildNotifcationView(_onNotificationTap, context),     
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
    
  Widget buildNotifcationView(Function _onTap, BuildContext context) {
    Future<Widget> buildFutureItem(RecentTopic recentTopic, Function _onTap) async {
      return this.messageService.getTopic(recentTopic.id).then((value) {
        return new TopicMessage(user: widget.user, topic: value, onTap: _onTap, messageLocation: recentTopic.messageLocation);
      });
    }

    Widget buildItem(RecentTopic recentTopic, Function _onTap, BuildContext context) {
      return FutureBuilder<Widget>(
        future: buildFutureItem(recentTopic, _onTap), // a previously-obtained Future<String> or null
        builder: (context, AsyncSnapshot<Widget> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return new LinearProgressIndicator();
            case ConnectionState.done:
              return snapshot.data;
          }
          return null; // unreachable
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

    List<Widget> buildGrid(List<DocumentSnapshot> querySnapshot, Function _onTap, BuildContext context) {
      List<Widget> _gridItems = [];
      for (DocumentSnapshot snapshot in querySnapshot) {
        RecentTopic recentTopic = RecentTopic.fromMap(snapshot.data);
        _gridItems.add(buildItem(recentTopic, _onTap, context));
      }
      return _gridItems;
    } 
    return new Container(
      child: StreamBuilder(
        stream: userService.getRecentTopicSnap(widget.user.uuid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            );
          } else {
            List<Widget> children =  buildGrid(snapshot.data.documents, _onTap, context);
            return new StaggeredGridView.count(
              physics: new BouncingScrollPhysics(),
              crossAxisCount: 4,
              children: children, 
              staggeredTiles: staggeredTileBuilder(children),
            );
          }
        },
      ),
    );
  }

  Widget buildBroadcast(BuildContext context) {
    void _onBroadcastTap(Topic topic, String parentTitle,  GeoPoint lastAccessLocation) {
      GeoPoint _messageLocation = lastAccessLocation;
      //GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new ChatScreen(user: widget.user, topic: topic, parentTitle: parentTitle, enableSendButton: true, messageLocation: _messageLocation);
          },
        ),
      );
    }

    return Stack(
      children: <Widget>[
        buildBroadcastView(_onBroadcastTap, context),     
        buildLoading(),
      ],
    );
  }


  Widget buildBroadcastView(Function _onTap, BuildContext context) {
    Widget buildItem(Topic topic, Function _onTap, BuildContext context) {
      Widget rv; 
      GeoPoint location = topic.geoCenter;
      rv = new TopicMessage(user: widget.user, topic: topic, onTap: _onTap, messageLocation: this.messageLocation);
      return rv;
    }
    List<StaggeredTile> staggeredTileBuilder(List<Widget> widgets) {
      List<StaggeredTile> _staggeredTiles = [];
      for (Widget widget in widgets) {
        _staggeredTiles.add(new StaggeredTile.fit(2));
      }
      return _staggeredTiles;
    }

    List<Widget> buildGrid(List<DocumentSnapshot> querySnapshot, Function _onTap, BuildContext context) {
      List<Widget> _gridItems = [];
      for (DocumentSnapshot snapshot in querySnapshot) {
        Topic topic = Topic.fromMap(snapshot.data);
        _gridItems.add(buildItem(topic, _onTap, context));
      }
      return _gridItems;
    } 
    return new Container(
      child: StreamBuilder(
        stream: this.messageService.getBroadcastSnap(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            );
          } else {
            List<Widget> children =  buildGrid(snapshot.data.documents, _onTap, context);
            return new StaggeredGridView.count(
              physics: new BouncingScrollPhysics(),
              crossAxisCount: 4,
              children: children, 
              staggeredTiles: staggeredTileBuilder(children),
            );
          }
        },
      ),
    );
  }
}
