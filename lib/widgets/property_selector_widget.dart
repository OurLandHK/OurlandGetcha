import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourland_native/models/constant.dart';

class Property {
  String _field;
  int _value;
  DateTime _lastUpdate;

  Property(this._field, this._value) {
    _lastUpdate = DateTime.now();
  }

  int get value => this._value;
  DateTime get lastUpdate => this._lastUpdate;
  String get propertyField => this._field;

  void updateValue(int value) {
    _value = value;
    _lastUpdate = DateTime.now();
  }

  Property.fromMap(Map<String, dynamic> map) {
    this._lastUpdate = DateTime.fromMicrosecondsSinceEpoch(map['lastUpdate'].microsecondsSinceEpoch);
    this._value = map['value'];
    this._field = map['field'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['lastUpdate'] = _lastUpdate;
    map['value'] = _value;
    map['field'] = _field;
    return map;
  }
}


class PropertySelectorWidget extends StatefulWidget {
  PropertySelectorWidget(
      @required this.defaultFields, 
      @required this.currentProperties, 
      @required this.totalSelect,
      @required this.currentSelectProperties,
      this.showLastUpdate,
      this.readOnly);


  final List<String> defaultFields;
  final List<Property> currentProperties;
  final Function currentSelectProperties;
  final int totalSelect;
  bool showLastUpdate = false;
  bool readOnly = true;


  @override
  PropertySelectorView createState() => PropertySelectorView();
}


class PropertySelectorView extends PropertySelectorModel {
  PropertySelectorView(): super();
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
            children: [Container(child: buildOptions(context, true))]));
  }
}

// RichLinkPreviewMode 
abstract class PropertySelectorModel extends State<PropertySelectorWidget>
    with TickerProviderStateMixin {
  List<String> selectedFields = [];
  Map<String, Property> _currentPropertiesMap;
  PropertySelectorModel() {
  }

  @override
  void initState() {
    _currentPropertiesMap = new Map();
    for(int i = 0; i< widget.currentProperties.length; i++) {
      String field = widget.currentProperties[i].propertyField;
      _currentPropertiesMap[field] =  widget.currentProperties[i];
    }
    for(int i = 0; i< widget.defaultFields.length; i++) {
      String field = widget.defaultFields[i];
      if(_currentPropertiesMap[field] == null) {
        _currentPropertiesMap[field] = new Property(field, 0);
      }
    }
    super.initState();
  }

  void _onTap(field) {
    setState(() {
      if(selectedFields.remove(field)) {
        selectedFields.join(', ');
      } else {
        if(selectedFields.length < widget.totalSelect) {
          selectedFields.add(field);
        }
      }      
    });
    widget.currentSelectProperties(selectedFields);
  }


  Widget buildOptions(BuildContext context, bool displayResult) {
    List<Widget> listOfWidget = [];
    double optionWidth = MediaQuery.of(context).size.width;
    _currentPropertiesMap.forEach((field, property) {
      double borderSize = 1.2;
      Color boxColor = Theme.of(context).dialogBackgroundColor;
      String resultText = "";
      String fieldText = field;
      if(widget.showLastUpdate) {
        fieldText += " Last Update:" + DateFormat('dd MMM kk:mm').format(
              new DateTime.fromMicrosecondsSinceEpoch(
                property._lastUpdate.microsecondsSinceEpoch));
      }
      Widget textWidget = Text(fieldText);
      int value = property.value;
      if(selectedFields.contains(field)) {
          value++;
          borderSize = 2;
          boxColor = Theme.of(context).accentColor;
      }
      if(displayResult) {
        resultText = value.toString();
      }
      textWidget = Row(children: [
        textWidget,
        Flexible(flex: 2,child: Container()),
        Text(resultText),
      ]);
      Widget optionBox = SizedBox(
          width: optionWidth,
          child: FlatButton(
            child: textWidget, 
            onPressed: widget.readOnly ? null : () => {_onTap(field)}
            )
          );
/*        

                //print("${_upvote[i]}");
      LinearGradient gradient;
      if(displayResult) {
        gradient = LinearGradient(colors: [widget.darkBackgroundColor , Colors.white],
                        stops: [upvoteResult / totalUpvote, upvoteResult / totalUpvote],
                        tileMode: TileMode.clamp);
      }
*/
      optionBox = Container(
                      decoration: new BoxDecoration(
                        color: boxColor,
                      ),
                      child: optionBox
        );
      listOfWidget.add(optionBox);
    });

    return Column (children: listOfWidget);    
  }
}
