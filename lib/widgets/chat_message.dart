import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';
import '../pages/chat_screen.dart';
import '../models/constant.dart';


class ChatMessage extends StatelessWidget {
  final String parentId;
  final String messageId;
  GeoPoint geoTopLeft;
  GeoPoint geoBottomRight;
  final Map<String, dynamic> messageBody;
  final Function onTap;

  ChatMessage({Key key, @required this.parentId, @required this.messageId, @required this.messageBody, @required this.onTap, this.geoTopLeft, this.geoBottomRight}) : super(key: key);

  Widget build(BuildContext context) {

    void _onTap() {
      //print("onTap");
      this.onTap(this.messageBody['id'], this.messageBody['content'], this.geoTopLeft, this.geoBottomRight);
    }
    Widget rv;
    Container messageWidget;
    //print(this.messageId);
    switch(messageBody['type']) {
      case 0:
        messageWidget = Container(
                          child: Text(
                            messageBody['content'],
                            style: TextStyle(color: Colors.white),
                          ),
                          padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                          width: 200.0,
                          decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
                          margin: EdgeInsets.only(left: 10.0),
                        );
        break;
      case 1:
        messageWidget = Container(
                              child: Material(
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
                                  imageUrl: messageBody['content'],
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                clipBehavior: Clip.hardEdge,
                              ),
                              margin: EdgeInsets.only(left: 10.0),
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
                              margin: EdgeInsets.only(bottom: 10.0, right: 10.0),
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
                      DateFormat('dd MMM kk:mm')
                          .format( new DateTime.fromMicrosecondsSinceEpoch(messageBody['created'].microsecondsSinceEpoch)),
                      style: TextStyle(color: greyColor, fontSize: 12.0, fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
                  );
    Widget content = row;
    if(this.parentId.length == TOPIC_ROOT_ID.length) {
      content = new GestureDetector(
              onTap: _onTap,
              child: row
      );
    }
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