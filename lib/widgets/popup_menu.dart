import 'package:flutter/material.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/services/user_service.dart';
import 'package:ourland_native/pages/about.dart';
import 'package:ourland_native/pages/settings.dart';
import 'package:ourland_native/pages/registration_screen.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PopupMenu extends StatelessWidget {
  
  UserService userService = new UserService();
  final User user;
  final SharedPreferences preferences;

  PopupMenu(this.user, @required this.preferences);

  void _select(BuildContext context, String item) {
    switch(item) {
      case MENU_ITEM_SETTINGS: 
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (context) => SettingsScreen(this.user, this.preferences)));
        break;
      case MENU_ITEM_ABOUT:
        Navigator.of(context)
            .push(new MaterialPageRoute(builder: (context) => About()));
        break;
      case MENU_ITEM_LOGOUT:
        userService.logout();
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (context) => PhoneAuthenticationScreen(preferences: preferences, isFirstPage: true)));
        break;
      case REG_BUTTON_TEXT:
        Navigator.of(context).push(new MaterialPageRoute(
            builder: (context) => PhoneAuthenticationScreen(preferences: preferences, isFirstPage: false)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> items = [REG_BUTTON_TEXT, MENU_ITEM_ABOUT];
    if(this.user != null) {
       items = <String>[
        MENU_ITEM_SETTINGS,
        MENU_ITEM_ABOUT,
        MENU_ITEM_LOGOUT
      ];
    }
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
