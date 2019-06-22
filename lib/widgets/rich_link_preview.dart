import 'package:flutter/material.dart';
//import 'package:open_graph_parser/open_graph_parser.dart';
import 'package:ourland_native/helper/open_graph_parser.dart';
import 'package:url_launcher/url_launcher.dart';

//import './rich_link_preview_view.dart';

//rich_link_preview.dart

class RichLinkPreview extends StatefulWidget {
  RichLinkPreview(
      {this.link,
      this.width,
      this.height,
      this.borderColor,
      this.textColor,
      this.backgroundColor,
      this.appendToLink,
      this.launchFromLink,
      this.vertical});

  final String link;
  final double height;
  final double width;
  final Color borderColor;
  final Color textColor;
  final Color backgroundColor;
  final bool appendToLink;
  final bool launchFromLink;
  final bool vertical;

  @override
  RichLinkPreviewView createState() => RichLinkPreviewView();
}

// RichLinkPreviewView

class RichLinkPreviewView extends RichLinkPreviewModel {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            children: [Container(child: buildRichLinkPreview(context))]));
  }
}

// RichLinkPreviewMode 
abstract class RichLinkPreviewModel extends State<RichLinkPreview>
    with TickerProviderStateMixin {
  AnimationController controller;
  Animation<Offset> position;
  String _link;
  double _height;
  double _width;
  Color _borderColor;
  Color _backgroundColor;
  Color _textColor;
  bool _appendToLink;
  bool _isLink;
  bool _launchFromLink;
  bool _vertical;
  Map _ogData;

  void getOGData() async {
    OpenGraphParser.getOpenGraphData(_link).then((Map data) {
      if (data != null) {
        if (this.mounted) {
          setState(() {
            _ogData = data;
          });

          controller = AnimationController(
              vsync: this, duration: Duration(milliseconds: 750));
          position = Tween<Offset>(begin: Offset(0.0, 4.0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: controller, curve: Curves.bounceInOut));

          controller.forward();
        }
      } else {
        setState(() {
          _ogData = null;
        });
      }
    });
  }

  @override
  void initState() {
    _link = widget.link ?? '';
    _height = widget.height ?? 100.0;
    _width = widget.width ?? 200.0;
    _borderColor = widget.borderColor ?? Color(0xFFE0E0E0);
    _textColor = widget.textColor ?? Color(0xFF000000);
    _backgroundColor = widget.backgroundColor ?? Color(0xFFE0E0E0);
    _appendToLink = widget.appendToLink ?? false;
    _launchFromLink = widget.launchFromLink ?? true;
    _vertical = widget.vertical ?? false;

    _fetchData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool isValidUrl(link) {
    String regexSource =
        "^(https?)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]";
    final regex = RegExp(regexSource);
    final matches = regex.allMatches(link);
    for (Match match in matches) {
      if (match.start == 0 && match.end == link.length) {
        return true;
      }
    }
    return false;
  }

  @override
  void didUpdateWidget(RichLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (this.mounted && _appendToLink == false) {
      setState(() {
        _link = oldWidget.link != widget.link ? widget.link : '';
      });
    }

    _fetchData();
  }

  void _fetchData() {
    if (isValidUrl(_link) == true) {
      getOGData();
      _isLink = true;
    } else {
      if (this.mounted) {
        setState(() {
          _ogData = null;
        });
      }
      _isLink = false;
    }
  }

  void _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget buildRichLinkPreview(BuildContext context) {
    if (_ogData == null) {
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 8, child: _buildUrl(context)),
          ]);
    } else {
      if (_appendToLink == true) {
        return _buildWrappedInkWell(_buildPreviewRow(context));
      } else {
        return (SlideTransition(
            position: position,
            child: Container(
                height: _height,
                decoration: new BoxDecoration(
                  borderRadius:
                      const BorderRadius.all(const Radius.circular(8.0)),
                ),
                child: _buildPreviewRow(context))));
      }
    }
  }

  Widget _buildRichLinkPreviewBody(BuildContext context, Map _ogData) {
    return Container(
        padding: const EdgeInsets.all(3.0),
//        height: _height,
        decoration: BoxDecoration(
          color: _backgroundColor,
/*          border: Border(
            top: BorderSide(width: 2.0, color: _borderColor),
            left: BorderSide(width: 0.0, color: _borderColor),
            right: BorderSide(width: 2.0, color: _borderColor),
            bottom: BorderSide(width: 2.0, color: _borderColor),
          ),
          */
        ),
        child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTitle(context),
              _buildDescription(context),
            ]));
  }

  Widget _buildPreviewRow(BuildContext context) {
    if (_ogData['image'] != null) {
      if(_vertical) {
        return Container(
          
          width: _width,
          child: Column(
          children: <Widget>[
                    Container(
                        child: new ClipRRect(
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                            child: Image.network(_ogData['image'],
//                                width: 120.0,
//                                height: _height,
//                                fit: BoxFit.fill))),
                            ))),
              _buildRichLinkPreviewBody(context, _ogData),
              _buildUrl(context),
            ]
          )
        );
      } else {
        return Column(
          children: <Widget>[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                          child: new ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(3.0),
                              ),
                              child: Image.network(_ogData['image'],
                                  width: 120.0,
                                  height: _height,
                                  fit: BoxFit.fill)))
                    ],
                  )),
              Expanded(
                  flex: 5, child: _buildRichLinkPreviewBody(context, _ogData)),
            ]),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Expanded(flex: 8, child: _buildUrl(context)),
            ])
          ],
        );
      }
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[_buildRichLinkPreviewBody(context, _ogData)],
      );
    }
  }

  Widget _buildTitle(BuildContext context) {
    if (_ogData != null && _ogData['title'] != null) {
      return Padding(
          padding: EdgeInsets.all(1.0),
          child: new Text(
            _ogData['title'],
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
          ));
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildDescription(BuildContext context) {
    if (_ogData != null && _ogData['description'] != null) {
      return Padding(
          padding: EdgeInsets.all(2.0),
          child: new Text(_ogData['description'],
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: TextStyle(color: _textColor)));
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildUrl(BuildContext context) {
    if (_link != '' && _appendToLink == true) {
      return Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
          ),
          child: Padding(
              padding: EdgeInsets.all(5.0),
              child: new Text(_link,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(color: _textColor))));
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildWrappedInkWell(Widget widget) {
    if (_launchFromLink == true &&
        _link != '' &&
        _isLink == true &&
        _appendToLink == true) {
      return InkWell(child: widget, onTap: () => _launchURL(_link));
    }
    return widget;
  }
}
