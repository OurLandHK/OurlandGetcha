import 'package:flutter/material.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/report_service.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/services/message_service.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/widgets/property_selector_widget.dart';


// ----------------------------------------
// SETTING SCREEN LANDING SCREEN
// ----------------------------------------

class ReportScreen extends StatefulWidget  {
  final User user;
  final Topic topic;
  ReportScreen({@required this.topic, @required this.user});

  @override
  _ReportScreenState createState() => new _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  _ReportScreenState(
      {Key key}) {
        _selectedField = "";
      }
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ReportService _reportService;
  UserService _userService;
  MessageService _messageService;
  List<Property> _properties = [];
  String _selectedField;
  bool _alreadyReport = true;
  Widget _optionWidget = Container();

  @override
  void initState() {
    super.initState();
    _reportService = new ReportService(widget.user);
    _messageService = new MessageService(widget.user);
    _userService = new UserService();
    getReportValue();
  }

  void getReportValue() {
    List<Property> properties = [];
    bool alreadyReport = true;
    // get the report value per topic
    _reportService.getSummary(widget.topic.id).then((reports) {
      print(reports);
      if(reports != null) {
        reports.forEach((field, property) {
          print(field);
          properties.add(Property.fromMap(property));
        });
      }
      _reportService.getUserReport(widget.topic.id, widget.user.uuid).then((userReport) {
        if(userReport == null) {
          alreadyReport = false;
        }
        setState(() {
          this._properties = properties;
          this._alreadyReport = alreadyReport;
          _optionWidget = PropertySelectorWidget(BlockReasons, properties, 1, selectField, true, false, false, false);
        });
      });
    });
  }

  void selectField(List<String> selectField, bool isUp) {
    setState(() {
      if(selectField.length > 0) {
        _selectedField = selectField[0];
      } else {
        _selectedField = "";
      }
    });
    //print("Report: ${_selectedField}");
  }


  @override
  Widget build(BuildContext context) {
    void onSubmit() {
      _messageService.sendChildMessage(widget.topic, null, _selectedField, null, 8).then((var temp) {
        _reportService.sendUserReportResult(widget.topic.id, _selectedField).then((void v) {
          /*
          _scaffoldKey.currentState.showSnackBar(
              new SnackBar(content: new Text(UPDATE_LOCATION_SUCCESS)));
          */
          _userService.addBlockTopic(widget.user.uuid, widget.topic.id, _selectedField).then((void v) {
            Navigator.of(context).pop();
          });
        });
      });
    }
    void onApprove() {
      _messageService.sendChildMessage(widget.topic, null, _selectedField, null, 9).then((var temp) {
        Navigator.of(context).pop();
      });
    }
    List<Widget> widgets = [RaisedButton(
        onPressed: _selectedField != "" && !_alreadyReport ? () => onSubmit() : null,
        child: Text(CHAT_MENU_ITEM_REPORT),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue)];
    if(widget.user != null && widget.user.globalHideRight) {
      widgets.add(RaisedButton(
        onPressed: _selectedField != "" ? () => onApprove() : null,
        child: Text(REPORT_APPROVED),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue));
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(widget.topic.topic),
      ),
      body: new Center(
        child: Container(
            child: Column(children: <Widget>[
          Text(REPORT_DESC, maxLines: 3),
          _optionWidget,
          Row(mainAxisAlignment: MainAxisAlignment.center, children: widgets)
        ])),
      ),
    );
  }
}

// ----------------------------------------
// TODO: UPDATE PROFILE IMAGE SCREEN
// ----------------------------------------
