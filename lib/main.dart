// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/constant.dart';
//import 'package:ourland_native/ourland_home.dart';
import 'package:ourland_native/pages/registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: Colors.grey,
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
        primarySwatch:  Colors.blue,
        accentColor: Colors.yellow,
        
        primaryIconTheme: IconThemeData(color: Colors.black),
        primaryTextTheme: TextTheme(
          title: TextStyle(
          color: Colors.black
        )),
        //backgroundColor: Colors.black,
        textTheme: TextTheme(
          headline: TextStyle(
              fontFamily: 'Sans',
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 20),
          body1: TextStyle(
              fontFamily: 'Sans',
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16),
          body2: TextStyle(
              fontFamily: 'Sans',
              fontWeight: FontWeight.normal,
              color: Colors.black,
              fontSize: 12),
          subtitle: TextStyle(
              fontFamily: 'Sans',
              fontWeight: FontWeight.normal,
              color: Colors.black,
              fontSize: 10),
        ),
      );

void main() {
  initFirestoreSettings();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
        SharedPreferences.getInstance().then((value){
          runApp(new OurlandApp(value));
        });
  });
}

void initFirestoreSettings() async {
  Firestore firestore = Firestore();
  await firestore.settings(timestampsInSnapshotsEnabled: true);
}

class OurlandApp extends StatelessWidget {
  final SharedPreferences preferences;

  OurlandApp(@required this.preferences);
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: APP_NAME,
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: new PhoneAuthenticationScreen(preferences: preferences)
      //home: new OurlandHome(null)
    );
  }
}



