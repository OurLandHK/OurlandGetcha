# OurlandGetcha

## Description:
* OurlandSearch's Native IOS/Andrioid version written with Flutter and Firebase
* A location base chat app made by Flutter and Firebase.
* Support login with phone, post to current location, send text, image and sticker, update avatar and profile.


## Getting Started

### Installation
For help getting started with Flutter, view our online
[documentation](https://flutter.io/docs/get-started/install).


### Use Stable Flutter
'
flutter channel stable
flutter channel
flutter upgrade
'

### Clean up all flutter pub .cache
'
<Flutter Home>\.pub-cache\hosted\pub.dartlang.org
'

### Check environment
`
flutter doctor
`

### Download dependencies
`
flutter packages get
`

### Run the Project
`
flutter run
`

## Google Map Configuration

### Generate API Key
1. Go to [https://console.developers.google.com/](https://console.developers.google.com/)
2. Enable `Maps SDK for Android`
3. Enable `Maps SDK for iOS`
4. Under `Credentials`, click `Create Credential` and choose `API Key`
5. Replace YOUR_API_KEY_HERE with the key in AndroidManifest.xml and AppDelegate.m 

### Firebase setting
1. Rules at Storage:
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if true && request.resource.contentType.matches('image/.*') && request.auth != null;
    }
  }
}
2. Rules at Database:
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write : if true; 
    }
  }
}
2. Enable Message:
https://pub.dartlang.org/packages/firebase_messaging
