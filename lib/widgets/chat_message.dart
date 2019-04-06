import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/chat_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/widgets/image_widget.dart';

class ChatMessage extends StatelessWidget {
  final String parentId;
  final String messageId;
  final User user;
  final GeoPoint geoTopLeft;
  final GeoPoint geoBottomRight;
  final Chat messageBody;
  final Function onTap;

  ChatMessage(
      {Key key,
      @required this.user,
      @required this.parentId,
      @required this.messageId,
      @required this.messageBody,
      @required this.onTap,
      this.geoTopLeft,
      this.geoBottomRight})
      : super(key: key);

  bool isCurrentUser() {
    return(messageBody.createdUser != null && messageBody.createdUser.uuid == this.user.uuid);
  }

  Widget build(BuildContext context) {
    Widget rv;
    Container messageWidget;
    EdgeInsets margin = isCurrentUser() ? EdgeInsets.only(right: 10.0) : EdgeInsets.only(left: 10.0);
    EdgeInsets timeMargin = isCurrentUser() ? EdgeInsets.only(right: 50.0, top: 5.0, bottom: 5.0) : EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0);
    //print(this.messageId);
    switch (messageBody.type) {
      case 0:
        messageWidget = Container(
          child: RichLinkPreview(
              link: messageBody.content,
              appendToLink: true,
              backgroundColor: primaryColor,
              borderColor: primaryColor,
              textColor: Colors.white),
          padding: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 10.0),
          width: 200.0,
          decoration: BoxDecoration(
              color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
          margin: margin,
        );
        if(messageBody.imageUrl != null) {
          messageWidget = Container(
            child: Column (children: <Widget>[
              new ImageWidget(imageUrl: messageBody.imageUrl, height: 200 ,width: 200),
              messageWidget,
          ]),
          );
        }
        break;
      case 1:
        messageWidget = Container(
          child: new ImageWidget(imageUrl: messageBody.content, height: 200 ,width: 200),
          margin: margin,
        );
        break;
      case 2:
        messageWidget = Container(
          child: new Image.asset(
            'assets/images/${messageBody.content}.gif',
            width: 100.0,
            height: 100.0,
            fit: BoxFit.cover,
          ),
          margin: margin,
        );
    }
    Row row = new Row(
      children: <Widget>[
        Container(width: 35.0), // Should be fild with user avator
        messageWidget,
      ],
    );
    // Time
    Container timeWidget = Container(
      child: Text(
        DateFormat('dd MMM kk:mm').format(
            new DateTime.fromMicrosecondsSinceEpoch(
                messageBody.created.microsecondsSinceEpoch)),
        style: TextStyle(
            color: greyColor, fontSize: 12.0, fontStyle: FontStyle.italic),
      ),
      margin: timeMargin,
    );
    Widget content = row;
    rv = Container(
      child: Column(
        children: <Widget>[
          content,
          timeWidget,
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      margin: EdgeInsets.only(bottom: 10.0),
    );
    return rv;
  }
}
