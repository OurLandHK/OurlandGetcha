import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';


//import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/widgets/Topic_message.dart';

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
  SharedPreferences prefs;
  TabController _tabController;

  bool isLoading;

  // use to get current location
  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
 
  @override
  void initState() {
    super.initState();
    messageService = new MessageService(widget.user);

    isLoading = false;
    _tabController = new TabController(vsync: this, initialIndex: 0, length: 2);
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
  }

  void onFocusChange() {
  }

  Widget buildItem(String messageId, Map<String, dynamic> document, Function _onTap, BuildContext context) {
    Widget rv; 
    int type = 0;
    if(document['createdUser'] == null) {
      document['createdUser']['user'] = "Test";
    }

    Topic topic = Topic.fromMap(document);
    GeoPoint location = topic.geoCenter;
    rv = new TopicMessage(user: widget.user, topic: topic, onTap: _onTap);
    return rv;
  }

  @override
  Widget build(BuildContext context) {
    return 
      new Scaffold(
        appBar: new AppBar(
          title: new TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: <Widget>[
              //  new Tab(icon: new Icon(Icons.camera_alt)),
              new Tab(
                  child: new Row(children: <Widget>[
                    new Icon(Icons.person),
                    new Text(LABEL_RECENT),
                  ])
              ),
              new Tab(
                child: new Row(children: <Widget>[
                  new Icon(Icons.public),
                  new Text(LABEL_BROADCAST),
                ])
              ),
            ],
          ),
        ),
        body:new TabBarView(
          controller: _tabController,
          children: <Widget>[
            buildNotification(context),
            buildBroadcast(context)
          ],
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
            return new ChatScreen(user: widget.user, topic: topic, parentTitle: parentTitle, messageLocation: _messageLocation);
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
    return new Container(
      child: StreamBuilder(
        stream: this.messageService.getBroadcastSnap(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            );
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => buildItem(snapshot.data.documents[index].data['id'], snapshot.data.documents[index].data, _onTap, context),
              itemCount: snapshot.data.documents.length,
            );
          }
        },
      ),
    );
  }

  Widget buildBroadcast(BuildContext context) {
    void _onBroadcastTap(Topic topic, String parentTitle) {
      GeoPoint _messageLocation = lastAccessLocation;
      //GeoPoint mapCenter = GeoHelper.boxCenter(topLeft, bottomRight);
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new ChatScreen(user: widget.user, topic: topic, parentTitle: parentTitle, messageLocation: _messageLocation);
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
    return new Container(
      child: StreamBuilder(
        stream: this.messageService.getBroadcastSnap(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            );
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => buildItem(snapshot.data.documents[index].data['id'], snapshot.data.documents[index].data, _onTap, context),
              itemCount: snapshot.data.documents.length,
            );
          }
        },
      ),
    );
  }
}
