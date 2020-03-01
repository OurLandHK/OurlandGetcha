import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ourland_native/models/user_model.dart' as prefix0;
import 'package:permission_handler/permission_handler.dart';

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


class BroadcastScreen extends StatefulWidget {
  final User user;
  final SharedPreferences preferences;
  List<String> youtubeChannelList = [];
  BroadcastScreenState _state;

  BroadcastScreen({Key key, @required this.user, @required this.preferences, @required this.youtubeChannelList}) : super(key: key);
  @override
  State createState() {
    _state = new BroadcastScreenState();
    return _state;
  } 
}
class BroadcastScreenState extends State<BroadcastScreen> with TickerProviderStateMixin  {
  BroadcastScreenState({Key key});
  MessageService _messageService;

  var listMessage;

  List<DropdownMenuItem<String>> _tagDropDownMenuItems;

  bool isLoading;
  bool expanded;

  String _firstTag;
  String _pendingTag = "";
  List<Widget> _children =[];

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();
  Topic _recentTopic;

  @override
  void initState() {
    super.initState();
    _tagDropDownMenuItems = getDropDownMenuItems(widget.youtubeChannelList , true);
    isLoading = false;
    focusNode.addListener(onFocusChange);
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
    rv = new TopicMessage(user: widget.user, topic: topic, onTap: _onTap, messageLocation: null);
    return rv;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buildToolBar(BuildContext context) {
      return  <Widget> [
                Expanded(flex: 1, child: Text(LABEL_PROGRAM, style: Theme.of(context).textTheme.subhead, textAlign: TextAlign.center)),
                Expanded(flex: 3, child: DropdownButton(
                    value: _firstTag,
                    items: _tagDropDownMenuItems,
                    style: Theme.of(context).textTheme.subhead,
                    onChanged: (String value) {setState(() {
                      _children =[];
                      _firstTag = null;
                      _pendingTag = value;
                    });
                  },
                )),
              ];
    }
    PreferredSizeWidget appBar;
    appBar = new AppBar(flexibleSpace: PreferredSize(
              preferredSize: Size.fromHeight(TOOLBAR_HEIGHT),
              child: Row(children: buildToolBar(context))));
    WidgetsBinding.instance
      .addPostFrameCallback((_) => _swapValuable(context));
    return new Scaffold(
        appBar: appBar,
        body: Container(
          color: Colors.white,
          child: new Stack(
            children: <Widget>[
            // buildScrollView(_onTap, context),
              buildListView(context),
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
      if (this._firstTag == null) {
        bool canViewHide = false;
        if(widget.user != null && widget.user.globalHideRight) {
          canViewHide = true;
        }
        this._messageService.getBroadcastSnap(this._pendingTag).listen((onData) {
          List<Topic> topics = [];
          if(onData.documents.length > 0) {          
            for (DocumentSnapshot doc in onData.documents) {
              Map data = doc.data;
              Topic topic = Topic.fromMap(data);
              topics.add(topic);
            }
          }
          List<Widget> widgets= buildGrid(topics, _onTap, context);
          setState(() {
            this._children = widgets;
            this._firstTag = this._pendingTag;
          });
        });
      }  
    }

    Widget buildListView(BuildContext context) {
      if (this._firstTag == null) {
        return new Center(child: new CircularProgressIndicator());
      } else {
        if(_children.length > 0) {
          return StaggeredGridView.count(
            physics: new BouncingScrollPhysics(),
            crossAxisCount: 4,
            children: _children, 
            staggeredTiles: staggeredTileBuilder(_children),
          );
        } else {
          return new Container(child: Text(LABEL_CHOICE_OTHER_TAG,
          style: Theme.of(context).textTheme.headline));
        }
        //staggeredTiles: generateRandomTiles(snapshot.data.length),
      }
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
        if(widget.user == null || !widget.user.blockUsers.contains(topic.createdUser.uuid)) {
          _gridItems.add(buildItem(topic.id, topic, _onTap, context));
        }
      }
      return _gridItems;
    }  

    void _onTap(Topic topic, String parentTitle, GeoPoint messageLocation) async {
      Navigator.of(context).push(
        new MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return ChatScreen(user : widget.user, topic: topic, parentTitle: parentTitle, messageLocation: null);
          },
        ),
      );
    }
}