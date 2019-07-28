import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:ourland_native/widgets/rich_link_preview.dart';
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
  final Function getUserName;
  final int color;
  final Function onTap;

  ChatMessage(
      {Key key,
      @required this.user,
      @required this.parentId,
      @required this.messageId,
      @required this.messageBody,
      @required this.color,
      @required this.onTap,
      @required this.getUserName,
      this.geoTopLeft,
      this.geoBottomRight})
      : super(key: key);

  bool isCurrentUser() {
    return (this.user != null && (messageBody.createdUser != null && messageBody.createdUser.uuid == this.user.uuid));
  }

  bool isLink() {
    if(this.messageBody != null) {
      String content = messageBody.content;
      return content.contains("http");
    } else {
      return false;
    }
  }

  Widget build(BuildContext context) {
    Widget rv;
    Widget messageWidget;
    double messageWidth = MediaQuery.of(context).size.width * 3 /4;
    //EdgeInsets margin = isCurrentUser() ? EdgeInsets.only(right: 10.0) : EdgeInsets.only(left: 10.0);
    EdgeInsets finalMargin = isCurrentUser() ? EdgeInsets.only(left: 10.0, bottom: 10.0) : EdgeInsets.only(right: 10.0, bottom: 10.0);
//    EdgeInsets timeMargin = isCurrentUser() ? EdgeInsets.only(right: 50.0, top: 5.0, bottom: 5.0) : EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0);
    CrossAxisAlignment crossAxisAlignment = isCurrentUser() ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    //print(this.messageId);
    switch (messageBody.type) {
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
        break;
      default:
        Widget content = new Text(messageBody.content, style: Theme.of(context).textTheme.body1);
        if(isLink()) {
          content = RichLinkPreview(
              link: messageBody.content,
              appendToLink: true,
              backgroundColor: TOPIC_COLORS[color],
              borderColor: TOPIC_COLORS[color],
              textColor: Colors.black);
        }
        messageWidget = Container(
          child: content,
          padding: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 10.0),
          width: messageWidth,
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
    }
    // Time
    Container timeWidget = Container(
      child: Text(
        DateFormat('dd MMM kk:mm').format(
            new DateTime.fromMicrosecondsSinceEpoch(
                messageBody.created.microsecondsSinceEpoch)),
        style: Theme.of(context).textTheme.subtitle,
      ),
      //margin: timeMargin,
    );
    Widget userWidget;
    if(!isCurrentUser()) {
      userWidget = new Text(getUserName(this.messageBody.createdUser.uuid),
      style: Theme.of(context).textTheme.subtitle);
    }
    List<Widget> footers =[];
    if(userWidget != null) {
      footers.add(userWidget);
    }
    footers.add(Expanded(flex: 1, child: Container()));
    footers.add(timeWidget);

    rv = Padding(
            padding: const EdgeInsets.all(4.0),
            child:  Container(
              padding: EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: TOPIC_COLORS[color],
                border: Border.all(width: 1, color: Colors.grey),
                boxShadow: [
                  new BoxShadow(
                    color: Colors.grey,
                    offset: new Offset(0.0, 2.5),
                    blurRadius: 4.0,
                    spreadRadius: 0.0
                  )
                ],
                //borderRadius: BorderRadius.circular(6.0)
                ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      //Expanded(child:
                         Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: messageWidget,
                        ),
                      //),
                    ],
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: footers)
                ],
                crossAxisAlignment: crossAxisAlignment,
              ),
            margin: finalMargin),

         );
    return rv;
  }
}
