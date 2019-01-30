import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:ourland_native/pages/camera_screen.dart';
import 'package:ourland_native/pages/topic_screen.dart';
import 'package:ourland_native/widgets/popup_menu.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/chat_model.dart';
import 'package:ourland_native/widgets/send_message.dart';

class OurlandHome extends StatefulWidget {
  final FirebaseUser user;

  OurlandHome(this.user) {
    if (user  == null) {
      throw new ArgumentError("[OurlandHome] firebase user cannot be null.");
    }
  }

  @override
  _OurlandHomeState createState() => new _OurlandHomeState();
}

const String _app_name = "我地.佳招";

class _OurlandHomeState extends State<OurlandHome> with SingleTickerProviderStateMixin {
  TabController _tabController;
  String uid = '';
  List<CameraDescription> cameras;

  @override
  void initState() {
    this.uid = '';
    FirebaseAuth.instance.currentUser().then((val) {
      setState(() {
        this.uid = val.uid;
      });
    }).catchError((e) {
      print(e);
    });

    availableCameras().then((rv) {
      cameras = rv;
    });

    super.initState();
    _tabController = new TabController(vsync: this, initialIndex: 0, length: 3);
  }

  @override
  Widget build(BuildContext context) {
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
          new TopicScreen(),
          new TopicScreen(),
          new TopicScreen(),
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
        onPressed: () => print("open chats"),
      ),
    );
  }
}