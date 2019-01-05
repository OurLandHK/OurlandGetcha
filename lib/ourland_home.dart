import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:ourland_native/pages/sendmessage.dart';
import 'package:ourland_native/pages/camera_screen.dart';
import 'package:ourland_native/pages/chat_screen.dart';
import 'package:ourland_native/models/constant.dart';
//import 'package:ourland_native/pages/status_screen.dart';

class OurlandHome extends StatefulWidget {
  var cameras;
  OurlandHome(this.cameras);

  @override
  _OurlandHomeState createState() => new _OurlandHomeState();
}

const String _app_name = "我地.佳招";

class _OurlandHomeState extends State<OurlandHome>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  String uid = '';

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
          new Icon(Icons.more_vert)
        ],
      ),
      body: new TabBarView(
        controller: _tabController,
        children: <Widget>[
          //new CameraScreen(widget.cameras),
          new ChatScreen(parentId: "", parentTitle: LABEL_NEARBY,),
          new ChatScreen(parentId: "", parentTitle: LABEL_REGION0,),
          new ChatScreen(parentId: "", parentTitle: LABEL_REGION1,),
          //new StatusScreen(),
          //new CallsScreen(),
        ],
      ),
/*      floatingActionButton: new FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor,
        child: new Icon(
          Icons.message,
          color: Colors.white,
        ),
        onPressed: () => print("open chats"),
      ),*/
    );
  }
}