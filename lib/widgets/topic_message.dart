import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rich_link_preview/rich_link_preview.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/constant.dart';

class TopicMessage extends StatelessWidget {
  final String messageId;
  final User user;
  GeoPoint geoTopLeft;
  GeoPoint geoBottomRight;
  final Map<String, dynamic> messageBody;
  final Function onTap;

  TopicMessage(
      {Key key,
      @required this.user,
      @required this.messageId,
      @required this.messageBody,
      @required this.onTap,
      this.geoTopLeft,
      this.geoBottomRight})
      : super(key: key);

  Widget build(BuildContext context) {
    void _onTap() {
      //print("onTap");
      this.onTap(this.messageBody['id'], this.messageBody['topic'],
          this.geoTopLeft, this.geoBottomRight);
    }

    Widget rv;
    Container messageWidget;
    //print(this.messageId);
    switch (messageBody['type']) {
      case 0:
        messageWidget = Container(
          child: RichLinkPreview(
              link: messageBody['topic'],
              appendToLink: true,
              backgroundColor: primaryColor,
              borderColor: primaryColor,
              textColor: Colors.white),
          padding: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 10.0),
          width: 200.0,
          //decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
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
                //decoration: BoxDecoration(color: greyColor2, borderRadius: BorderRadius.all(Radius.circular(8.0),),),
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
          child: Text(
            messageBody['topic'],
            style: TextStyle(color: Colors.white),
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
          //width: 200.0,
          //decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
          margin: EdgeInsets.only(left: 10.0),
          //margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
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
      margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
    );
    //Widget content = row;
/*    content = new GestureDetector(onTap: _onTap, child: row);
    rv = Container(
      child: Column(
        children: <Widget>[
          content,
          timeWidget,
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      margin: EdgeInsets.only(bottom: 10.0),
    );*/
    rv = Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: CachedNetworkImage(
                  placeholder: Container(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.0,
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                    width: 50.0,
                    height: 50.0,
                    padding: EdgeInsets.all(15.0),
                  ),
                  imageUrl: (messageBody['createdUser'] != null) ? messageBody['createdUser']['avatarUrl'] : 'assets/images/default-avatar.jpg',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget> [
                          Container(
                            child: Text(
                              (messageBody['createdUser'] != null) ? messageBody['createdUser']['user'] : LABEL_NOBODY,
                              style: TextStyle(color: primaryColor),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                          ),
                          timeWidget
                        ]
                      ),
                      row,
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: _onTap,
          color: greyColor2,
          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    return rv;
  }
}
