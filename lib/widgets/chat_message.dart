import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/constant.dart';

class ChatMessage extends StatelessWidget {
  final String parentId;
  final String messageId;
  final User user;
  final GeoPoint geoTopLeft;
  final GeoPoint geoBottomRight;
  final Map<String, dynamic> messageBody;
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
    return(messageBody['createdUser'] != null && messageBody['createdUser']['uuid'] == this.user.uuid);
  }
  Widget imageWidget(imageUrl) {
    return Material(
            child: CachedNetworkImage(
              placeholder: Container(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
                width: 200.0,
                height: 200.0,
                padding: EdgeInsets.all(70.0),
                decoration: BoxDecoration(
                  color: greyColor2,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                ),
              ),
              errorWidget: Material(
                child: Image.asset(
                  'images/img_not_available.jpeg',
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(8.0),
                ),
                clipBehavior: Clip.hardEdge,
              ),
              imageUrl: imageUrl,
              width: 200.0,
              height: 200.0,
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            clipBehavior: Clip.hardEdge,
          );
  }

  Widget build(BuildContext context) {
    Widget rv;
    Container messageWidget;
    EdgeInsets margin = isCurrentUser() ? EdgeInsets.only(right: 10.0) : EdgeInsets.only(left: 10.0);
    EdgeInsets timeMargin = isCurrentUser() ? EdgeInsets.only(right: 50.0, top: 5.0, bottom: 5.0) : EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0);
    //print(this.messageId);
    switch (messageBody['type']) {
      case 0:
        messageWidget = Container(
          child: RichLinkPreview(
              link: messageBody['content'],
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
        if(messageBody['imageUrl'] != null) {
          messageWidget = Container(
            child: Column (children: <Widget>[
              imageWidget(messageBody['imageUrl']),
              messageWidget,
          ]),
          );
        }
        break;
      case 1:
        messageWidget = Container(
          child: imageWidget(messageBody['content']),
          margin: margin,
        );
        break;
      default:
        messageWidget = Container(
          child: new Image.asset(
            'assets/images/${messageBody['content']}.gif',
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
                messageBody['created'].microsecondsSinceEpoch)),
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
