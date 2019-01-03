import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ourland_native/models/constant.dart';

class PhoneAuthenticationScreen extends StatefulWidget {
  @override
  _PhoneAuthenticationScreenState createState() => new _PhoneAuthenticationScreenState();
}

class _PhoneAuthenticationScreenState extends State<PhoneAuthenticationScreen> {
  String username;
  String address;
  String phoneNumber;
  String smsCode;
  String verificationId;

  Future<void> verifyPhone() async {
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      this.verificationId = verId;
    };

    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      this.verificationId = verId;
      smsCodeDialog(context).then((value) {
        print('Signed in');
      });
    };

    final PhoneVerificationCompleted verifiedSuccess = (FirebaseUser user) {
      print('verified');
    };

    final PhoneVerificationFailed veriFailed = (AuthException exception) {
      print('${exception.message}');
    };

    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: this.phoneNumber,
        codeAutoRetrievalTimeout: autoRetrieve,
        codeSent: smsCodeSent,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verifiedSuccess,
        verificationFailed: veriFailed);
  }

  Future<bool> smsCodeDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text(SMS_CODE_DIALOG_TITLE),
            content: TextField(
              onChanged: (value) {
                this.smsCode = value;
              },
            ),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              new FlatButton(
                child: Text('Done'),
                onPressed: () {
                  FirebaseAuth.instance.currentUser().then((user) {
                    if (user != null) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacementNamed('/home');
                    } else {
                      Navigator.of(context).pop();
                      signIn();
                    }
                  });
                },
              )
            ],
          );
        });
  }

  signIn() {
    FirebaseAuth.instance
        .signInWithPhoneNumber(verificationId: verificationId, smsCode: smsCode)
        .then((user) {
      Navigator.of(context).pushReplacementNamed('/home');
    }).catchError((e) {
      print(e);
    });
  }

  renderAvatar() {
    return Container(
      width: 190.0,
      height: 190.0,
      decoration: new BoxDecoration(
          shape: BoxShape.circle,
          image: new DecorationImage(
              fit: BoxFit.fill,
              image: new ExactAssetImage('assets/images/default-avatar.jpg')
          )
      )
    );
  }

  renderUsernameField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_USERNAME_HINT_TEXT),
        onChanged: (value) {
          this.username = value;
        },
        keyboardType: TextInputType.number
    );
  }

  renderPhoneNumberField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_PHONE_NUMBER_HINT_TEXT),
        onChanged: (value) {
          this.phoneNumber = value;
        },
        keyboardType: TextInputType.number
    );
  }

  renderAddressField() {
    return TextField(
        decoration: InputDecoration(hintText: REG_ADDRESS_HINT_TEXT),
        onChanged: (value) {
          this.address = value;
        },
        keyboardType: TextInputType.number
    );
  }

  renderSubmitButton() {
    return RaisedButton(
        onPressed: verifyPhone,
        child: Text(REG_BUTTON_TEXT),
        textColor: Colors.white,
        elevation: 7.0,
        color: Colors.blue
    );
  }

  renderSizeBox() {
    return SizedBox(height: 10.0);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: Container(
            padding: EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                renderAvatar(),
                renderSizeBox(),
                renderUsernameField(),
                renderSizeBox(),
                renderPhoneNumberField(),
                renderSizeBox(),
                renderAddressField(),
                renderSizeBox(),
                renderSubmitButton()
              ],
            )),
      ),
    );
  }
}