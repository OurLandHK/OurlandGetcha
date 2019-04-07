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
    Widget messageWidget;
    double messageWidth = MediaQuery.of(context).size.width * 3 /4;
    EdgeInsets margin = isCurrentUser() ? EdgeInsets.only(right: 10.0) : EdgeInsets.only(left: 10.0);
    EdgeInsets finalMargin = isCurrentUser() ? EdgeInsets.only(right: 10.0, bottom: 10.0) : EdgeInsets.only(left: 10.0, bottom: 10.0);
    EdgeInsets timeMargin = isCurrentUser() ? EdgeInsets.only(right: 50.0, top: 5.0, bottom: 5.0) : EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0);
    CrossAxisAlignment crossAxisAlignment = isCurrentUser() ? CrossAxisAlignment.end : CrossAxisAlignment.start;
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
          width: messageWidth,
          decoration: BoxDecoration(
              color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
          //margin: margin,
        );
        if(messageBody.imageUrl != null) {
          messageWidget = Container(
            child: Column (children: <Widget>[
              new ImageWidget(imageUrl: messageBody.imageUrl, height: null, width: messageWidth),
              messageWidget,
          ]),
          );
        }
        break;
      case 1:
        messageWidget = new ImageWidget(imageUrl: messageBody.content, height: null, width: messageWidth);
        break;
      case 2:
        messageWidget = new Image.asset(
            'assets/images/${messageBody.content}.gif',
            width: 100.0,
            height: 100.0,
            fit: BoxFit.cover,
          );
    }
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
    List<Widget> widgets = [];
    if(!isCurrentUser()) {
      widgets.add(new Text(this.messageBody.createdUser.username,
      style: TextStyle(
            color: greyColor, fontSize: 12.0, fontStyle: FontStyle.italic)));
    }
    widgets.add(messageWidget);
    widgets.add(timeWidget);
    rv = Container(
      child: Column(
        children: widgets,
        crossAxisAlignment: crossAxisAlignment,
      ),
      margin: finalMargin,
    );
    return rv;
  }
}
