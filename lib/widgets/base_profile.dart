import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/widgets/image_widget.dart';
import 'package:ourland_native/models/constant.dart';

class BaseProfile extends StatelessWidget {
  final User user;

  BaseProfile(
      {Key key,
      @required this.user,})
      : super(key: key);


  Widget build(BuildContext context) {
    String imageUrl = (this.user.avatarUrl != null) ? this.user.avatarUrl : 'assets/images/default-avatar.jpg';
    Widget imageWidget = new ImageWidget(width: 50, height: 50, imageUrl: imageUrl);
    Widget rv = Column(
      children: <Widget>[
        Material(
          child: imageWidget,
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
          clipBehavior: Clip.hardEdge,
        ),
        Container(
          child: Text(
            this.user.username,
            style: Theme.of(context).textTheme.body2,
          ),
          alignment: Alignment.center,
          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
        ),
      ]
    );
    return rv;
  }
}


