import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ourland_native/models/constant.dart';


class ImageWidget extends StatelessWidget {
  final double width;
  final double height;
  final String imageUrl;

  ImageWidget(
      {Key key,
      @required this.width,
      @required this.height,
      @required this.imageUrl,})
      : super(key: key);

  bool isLink() {
    return this.imageUrl.contains("http");
  }

  Widget buildNetworkImage(BuildContext context) {
    return CachedNetworkImage(
      placeholder: (context, url) => new Container(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
          ),
          width: width,
          height: height,
          padding: EdgeInsets.all(70.0),
          decoration: BoxDecoration(
            color: greyColor2,
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
        ),
      errorWidget: (context, url, error) => new Material(
          child: Image.asset(
            this.imageUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(8.0),
          ),
          clipBehavior: Clip.hardEdge,
        ),
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Widget buildLocationImage(BuildContext context) {
    return Image.asset(
            'images/img_not_available.jpeg',
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
  }  

  Widget build(BuildContext context) {
    Widget imageWidget;
    if(isLink()) {
      imageWidget = buildNetworkImage(context);
    } else {
      imageWidget = buildLocationImage(context);
    }
    return Material(
            child: imageWidget,
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            clipBehavior: Clip.hardEdge,
          );}
}
