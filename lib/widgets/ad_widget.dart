// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'dart:io';

// You can also test with your own ad unit IDs by registering your device as a
// test device. Check the logs for your device's ID value.
const String testDevice = 'YOUR_DEVICE_ID';

class AdWidget extends StatefulWidget {
  final bool isBannerAd;
  @override
  AdWidget(this.isBannerAd);
  _AdWidgetState createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> {
  MobileAdTargetingInfo targetingInfo;

  String getAppId() {
    if (Platform.isIOS) {
      return "IOS_APP_ID";
    } else if (Platform.isAndroid) {
      return "ca-app-pub-7890979707970567~9764203327";
    }
    return null;
  }
  String getBannerAdUnitId() {
    if (Platform.isIOS) {
      return "IOS_AD_UNIT_BANNER";
    } else if (Platform.isAndroid) {
      return "ca-app-pub-7890979707970567/7138039988";
    }
    return null;
  }
  String getInterstitialAdUnitId() {
    if (Platform.isIOS) {
      return "IOS_AD_UNIT_INTERSTITIAL";
    } else if (Platform.isAndroid) {
      return "ca-app-pub-7890979707970567/3198794974";
    }
    return null;
  }

  MobileAd _adWidget;
  BannerAd _bannerAd;
  InterstitialAd _interstitialAd;
  int _coins = 0;

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: getBannerAdUnitId(),
      size: AdSize.banner,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("BannerAd event $event");
      },
    );
  }

  InterstitialAd createInterstitialAd() {
    return InterstitialAd(
      adUnitId: getInterstitialAdUnitId(),
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("InterstitialAd event $event");
      },
    );
  }

  @override
  void initState() {
    int seed = DateTime.now().second;
    targetingInfo = MobileAdTargetingInfo(
    testDevices: testDevice != null ? <String>[testDevice] : null,
    keywords: <String>['Hong Kong', '香港'],
    contentUrl: 'http://ourland.hk',
    gender: (seed % 2 == 1) ? MobileAdGender.female : MobileAdGender.male,
    designedForFamilies: (seed % 2 == 1),
    childDirected: false,
    nonPersonalizedAds: false,
  );
    super.initState();
    FirebaseAdMob.instance.initialize(appId: getAppId());
    _bannerAd = createBannerAd()..load();
    RewardedVideoAd.instance.listener =
        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      print("RewardedVideoAd event $event");
      if (event == RewardedVideoAdEvent.rewarded) {
        setState(() {
          _coins += rewardAmount;
        });
      }
    };
    if(widget.isBannerAd) {
      _bannerAd ??= createBannerAd();
      _bannerAd..load().then((value) {
        setState(() {
          _adWidget = _bannerAd;
        });
      });
    } else {
      _interstitialAd ??= createInterstitialAd();
      _interstitialAd..load().then((value) {
        setState(() {
          _adWidget = _interstitialAd;
        });
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_adWidget != null) _adWidget.show();
    return Container();
  }
}