import 'package:flutter/material.dart';
//import 'package:ourland_native/pages/sendmessage.dart';
import 'package:ourland_native/pages/camera_screen.dart';
import 'package:ourland_native/pages/chat_screen.dart';
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

  @override
  void initState() {
    // TODO: implement initState
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
              text: "NearBy",
            ),
            new Tab(
              text: "Home",
            ),
            new Tab(
              text: "Office",
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
          new ChatScreen(true),
          new ChatScreen(true),
          new ChatScreen(true),
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