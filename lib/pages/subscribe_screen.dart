import 'package:flutter/material.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/subscribe_service.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/models/subscribe_model.dart';
import 'package:ourland_native/widgets/property_selector_widget.dart';


// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class SubscribeScreen extends StatefulWidget  {
  final String fcmToken;
  List<String> youtubeChannelList = [];
  SubscribeScreen({@required this.fcmToken, @required this.youtubeChannelList});

  @override
  _SubscribeScreenState createState() => new _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  _SubscribeScreenState(
      {Key key}) {
        _selectedFields = [];
      }
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  SubscribeService _subscribeService;
  List<Property> _properties = [];
  List<String> _selectedFields;
  Widget _optionWidget = Container();

  @override
  void initState() {
    super.initState();
    _subscribeService = new SubscribeService();
    getUnsubscribedRecord();
  }

  void getUnsubscribedRecord() {
    List<Property> properties = [];
    List<String> selectedField = [];
    selectedField.addAll(widget.youtubeChannelList);
    widget.youtubeChannelList.forEach((element) {
      properties.add(new Property(element, 0));
    });
    _subscribeService.getSubscribeRecord(widget.fcmToken).then((record) {
      print(record);
      if(record != null) {
        record.unsubscribedChannels.forEach((element1) {
          selectedField.remove(element1);
          selectedField.join();
          /*
          properties.forEach((element2) { 
            if(element2.propertyField == element1) {
              element2.updateValue(0);
            }
          });
          */
        });
      }
      setState(() {
        this._properties = properties;
        _optionWidget = PropertySelectorWidget(widget.youtubeChannelList, properties, widget.youtubeChannelList.length, selectedField, selectChannel, false, false, false, false);
      });
    });
  }

  void selectChannel(List<String> selectField, bool isUp) {
    setState(() {
      if(selectField.length > 0) {
        print(selectField);
        _selectedFields = selectField;
      } else {
        _selectedFields = [];
      }
    });
    //print("Report: ${_selectedField}");
  }


  @override
  Widget build(BuildContext context) {
    void onSubmit() {
      _subscribeService.getSubscribeRecord(widget.fcmToken).then((record) {
        // update unsubscribeService List;
        List<String> unsubscribeField = [];
        unsubscribeField.addAll(widget.youtubeChannelList);
        _selectedFields.forEach((element) {
          unsubscribeField.remove(element);
          unsubscribeField.join();
        });
        record.unsubscribedChannels = unsubscribeField;
        _subscribeService.updateSubscribeRecord(record).then((void v) {
            Navigator.of(context).pop();
        });
      });
    }
    List<Widget> widgets = [RaisedButton(
        onPressed: onSubmit,
        child: Text(BROADCAST_MENU_ITEM_SUBCRIBE),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue)];
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(BROADCAST_MENU_ITEM_SUBCRIBE),
      ),
      body: new Center(
        child: Container(
            child: Column(children: <Widget>[
          Text(SUBSCRIBE_DESC, maxLines: 3),
          _optionWidget,
          Row(mainAxisAlignment: MainAxisAlignment.center, children: widgets)
        ])),
      ),
    );
  }
}
