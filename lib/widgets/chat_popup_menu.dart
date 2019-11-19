import 'package:flutter/material.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/pages/report_screen.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/topic_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPopupMenu extends StatelessWidget {
  
  UserService userService = new UserService();
  final Topic topic;
  final User user;

  ChatPopupMenu(@required this.topic, @required this.user);

  void _select(BuildContext context, String item) {
    switch(item) {
      case CHAT_MENU_ITEM_REPORT: 
        Navigator.of(context).push(
          new MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return new ReportScreen(topic: this.topic, user: this.user);
            },
        ) ,
      );
        break;
    }
  }
  @override
  Widget build(BuildContext context) {
    List<String> items = [CHAT_MENU_ITEM_REPORT];

    return PopupMenuButton<String>(
        elevation: 3.2,
        initialValue: items[0],
        onSelected: (String item) {
          _select(context, item);
        },
        itemBuilder: (BuildContext context) {
          return items.map((String item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList();
        });
  }
}
