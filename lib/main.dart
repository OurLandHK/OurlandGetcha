// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/ourland_home.dart';
import 'package:ourland_native/pages/registration_screen.dart';

List<CameraDescription> cameras;

final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);


void main() {
  availableCameras().then((rv) {
    cameras = rv;
    runApp(new OurlandApp());
  });
}

class OurlandApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: APP_NAME,
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: new PhoneAuthenticationScreen(),
      routes: <String, WidgetBuilder> {
        '/auth': (BuildContext context) => new PhoneAuthenticationScreen(),
        '/home': (BuildContext context) => new OurlandHome(cameras)
      }
    );
  }
}



