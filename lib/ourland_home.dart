import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ourland_native/pages/topic_screen.dart';
import 'package:ourland_native/widgets/popup_menu.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/pages/send_topic_screen.dart';

class OurlandHome extends StatefulWidget {
  final User user;

  OurlandHome(this.user) {
    if (user == null) {
      throw new ArgumentError("[OurlandHome] firebase user cannot be null.");
    }
  }

  @override
  _OurlandHomeState createState() => new _OurlandHomeState();
}

const String _app_name = "我地.佳招";

class _OurlandHomeState extends State<OurlandHome>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  String uid = '';
//  List<CameraDescription> cameras;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    this.uid = '';

/*
    availableCameras().then((rv) {
      cameras = rv;
    });
*/
    super.initState();
    _tabController = new TabController(vsync: this, initialIndex: 0, length: 3);

    // checking if location permission is granted
    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.location)
        .then((PermissionStatus permission) {
      if (permission == PermissionStatus.granted) {
        _locationPermissionGranted = true;
      } else {
        requestLocationPermission();
      }
    });
  }

  requestLocationPermission() {
    PermissionHandler().requestPermissions([PermissionGroup.location]).then(
        (Map<PermissionGroup, PermissionStatus> permissions) {
      if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    void sendMessageClick(GeoPoint messageLocation) {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return new SendTopicScreen(
                messageLocation: messageLocation, user: widget.user);
          },
        ),
      );
    }

    if (_locationPermissionGranted == true) {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text(_app_name),
          elevation: 0.7,
          bottom: new TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: <Widget>[
              //  new Tab(icon: new Icon(Icons.camera_alt)),
              new Tab(
                text: LABEL_NEARBY,
              ),
              new Tab(
                text: LABEL_REGION0,
              ),
              new Tab(
                text: LABEL_REGION1,
              ),
            ],
          ),
          actions: <Widget>[
            //new Icon(Icons.search),
            new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
            ),
            PopupMenu()
          ],
        ),
        body: new TabBarView(
          controller: _tabController,
          children: <Widget>[
            //new CameraScreen(widget.cameras),
            new TopicScreen(user: widget.user),
            new TopicScreen(user: widget.user),
            new TopicScreen(user: widget.user),
            //new StatusScreen(),
            //new CallsScreen(),
          ],
        ),
        //persistentFooterButtons: <Widget>[SendMessage(chatModel: ChatModel(TOPIC_ROOT_ID), listScrollController: null, messageLocation: new GeoPoint(22.4, 114)),],
        floatingActionButton: new FloatingActionButton(
          backgroundColor: Theme.of(context).accentColor,
          child: new Icon(
            Icons.message,
            color: Colors.white,
          ),
          onPressed: () => sendMessageClick(null),
        ),
      );
    } else {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text(_app_name),
          elevation: 0.7,
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Text(PERM_LOCATION_NOT_GRANTED),
            new RaisedButton(
              padding: const EdgeInsets.all(8.0),
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: requestLocationPermission,
              child: new Text(PERM_LOCATION_GRANT_BTN_TEXT),
            ),
          ],
        )),
      );
    }
  }
}
