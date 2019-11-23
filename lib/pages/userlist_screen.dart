import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:ourland_native/widgets/base_profile.dart';


import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/widgets/base_profile.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class UserlistScreen extends StatefulWidget {
  final User currentUser;
  final String title;
  final List<String> userIdList;
  UserlistScreenState _state;

  UserlistScreen({Key key, @required this.currentUser, @required this.title, @required this.userIdList}) : super(key: key);

  @override
  State createState() {
    _state = new UserlistScreenState();
    return _state;
  } 
}
class UserlistScreenState extends State<UserlistScreen> with TickerProviderStateMixin  {
  UserlistScreenState({Key key});
  UserService _userService;
  List<User> _userList = [];

  bool isLoading = true;
 
  @override
  void initState() {
    super.initState();
    _userService = new UserService();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    if(widget.userIdList.length > 0) {
      widget.userIdList.forEach((userId) {
        _userService.getUser(userId).then((user) {
          if(user != null) {
            setState(() {
              _userList.add(user);
              isLoading = false;
            });
          }
        });
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return 
      new Scaffold(
        appBar: new AppBar(
          title: Text(widget.title, style: Theme.of(context).textTheme.title)
          ),
        body:buildUserList(context),
    );
  }
  Widget buildUserList(BuildContext context) {
    return Stack(
      children: <Widget>[
        buildUserListView(context),     
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
          :  (widget.userIdList.length > 0) ? 
            Container() : new Text(LABEL_ZERO_BLOCK)
    );
  }
    
  Widget buildUserListView(BuildContext context) {
    List<StaggeredTile> staggeredTileBuilder(List<Widget> widgets) {
      List<StaggeredTile> _staggeredTiles = [];
      for (Widget widget1 in widgets) {
        _staggeredTiles.add(new StaggeredTile.fit(2));
      }
      return _staggeredTiles;
    }

    List<Widget> buildGrid(BuildContext context) {
      List<Widget> _gridItems = [];
      this._userList.forEach((user) {
        _gridItems.add(BaseProfile(user: user, currentUser: widget.currentUser));
      });
      return _gridItems;
    } 
    List<Widget> children =  buildGrid(context);
    return new StaggeredGridView.count(
      physics: new BouncingScrollPhysics(),
      crossAxisCount: 4,
      children: children, 
      staggeredTiles: staggeredTileBuilder(children),
    );
  }
}
  