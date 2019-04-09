// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:ourland_native/pages/registration_screen.dart';


final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.blue[300],
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch:  Colors.blue,
  accentColor: Colors.yellow,
);


void main() {
  initFirestoreSettings();
  runApp(new OurlandApp());
}

void initFirestoreSettings() async {
  Firestore firestore = Firestore();
  await firestore.settings(timestampsInSnapshotsEnabled: true);
}

class OurlandApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: APP_NAME,
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: new PhoneAuthenticationScreen()
    );
  }
}



