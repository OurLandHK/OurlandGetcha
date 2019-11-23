import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/widgets/image_widget.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';

class BaseProfile extends StatelessWidget {
  final User user;
  final User currentUser;
  final UserService _userService = new UserService();

  BaseProfile(
      {Key key,
      @required this.user, @required this.currentUser})
      : super(key: key);

  Widget _buildDialog(BuildContext context) {
    String imageUrl = (this.user.avatarUrl != null) ? this.user.avatarUrl : 'assets/images/default-avatar.jpg';
    Widget imageWidget = new ImageWidget(width: 50, height: 50, imageUrl: imageUrl);
    String username = "";
    if(this.user.username != null) {
      username = this.user.username;
    } 
    Widget blockButton = Container();
    if(this.currentUser != null && this.currentUser.uuid != this.user.uuid) {
      if(this.currentUser.blockUsers == null || this.currentUser.blockUsers.contains(this.user.uuid) == false) {
        blockButton = FlatButton(
          child: const Text(LABEL_BLOCK),
          onPressed: () {
            Map<String, List<String>> updateField = new Map();
            this.currentUser.addBlockUser(this.user.uuid);
            updateField['blockUsers'] = this.currentUser.blockUsers;
            _userService.updateUser(this.currentUser.uuid, updateField).then((void v) {
              Navigator.pop(context, true);
            });
          },
        );
      } else {
        blockButton = FlatButton(
          child: const Text(LABEL_UNBLOCK),
          onPressed: () {
            Map<String, List<String>> updateField = new Map();
            this.currentUser.removeBlockUser(this.user.uuid);
            updateField['blockUsers'] = this.currentUser.blockUsers;
            _userService.updateUser(this.currentUser.uuid, updateField).then((void v) {
              Navigator.pop(context, true);
            });
          },
        );        
      }
    } 
    return AlertDialog(
      title: Row(children : [imageWidget, Text(username)]),
      content: Column(children :[
        blockButton,
      ]),
      actions: <Widget>[  
        FlatButton(
          child: const Text(LABEL_CLOSE),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
  void showItemDialog() {
    showDialog<bool>(
      context: context,
      builder: (_) => _buildDialog(context),
    ).then((bool shouldNavigate) {
      /*
      if (shouldNavigate == true) {
        Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
        if (!item.route.isCurrent) {
          Navigator.push(context, item.route);
        }      
      }
      */
    });
  }

    String imageUrl = (this.user.avatarUrl != null) ? this.user.avatarUrl : 'assets/images/default-avatar.jpg';
    Widget imageWidget = new ImageWidget(width: 50, height: 50, imageUrl: imageUrl);
    String username = "";
    if(this.user.username != null) {
      username = this.user.username;
    }
    Widget rv = GestureDetector(onTap: showItemDialog,
      child:
        Column(
          children: <Widget>[
            Material(
              child: imageWidget,
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              clipBehavior: Clip.hardEdge,
            ),
            Container(
              child: Text(
                username,
                style: Theme.of(context).textTheme.body2,
              ),
              alignment: Alignment.center,
              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
            ),
          ]
        )
      );
    return rv;
  }
}


