import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ourland_native/models/user_model.dart';
import 'package:ourland_native/models/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';

final CollectionReference userCollection =
    Firestore.instance.collection('getChatUsers');

class UserService {

  Future register(
      String uuid, String username, File avatarImage) async {
    if (avatarImage != null) {
      return await uploadAvatar(uuid, avatarImage).then((avatarUrl) {
        return createUser(uuid, username, avatarImage, avatarUrl);
      });
    } else {
      return await createUser(
          uuid, username, avatarImage, DEFAULT_AVATAR_IMAGE_PATH);
    }
  }

  Future<User> createUser(String uuid, String username, File avatarImage,
      String avatarUrl) async {
    DateTime now = new DateTime.now();
    final User user =
          new User(uuid, username, avatarUrl, null, null, now, now);
    final Map<String, dynamic> data = user.toMap();
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(userCollection.document(uuid));
      await tx.set(ds.reference, data);
      return data;
    };

    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      if(data.length == mapData.length) {
        return user;
      } else {
        return null;
      }
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Future<void> updateUser(String uuid, var newValues) {
    return getUserMap(uuid).then((Map userMap) {
      newValues.forEach((k, v) {
        userMap[k] = v;
      });
      userMap['updatedAt'] = new DateTime.now();
      return userCollection.document(uuid).updateData(userMap);
    });
  }

  Future<User> updateRecentTopic(String userID, String topicID, GeoPoint messageLocation) 
    async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(userCollection.document(userID).collection('recentTopic').document(topicID));

      DateTime now = new DateTime.now();
      final RecentTopic recentTopic = 
          new RecentTopic(topicID, now, messageLocation);
      final Map<String, dynamic> data = recentTopic.toMap();
      await tx.set(ds.reference, data);
      return data;
    };

    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return User.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Stream<QuerySnapshot> getRecentTopicSnap(String userID) {
    Stream<QuerySnapshot> rv;
    rv = userCollection.document(userID).collection('recentTopic')
          .orderBy('lastUpdate', descending: true)
          .snapshots();
    return rv;
  }

  Future<Map> getRecentTopic(String userID, String topicID) async {
    userCollection.document(userID).collection('recentTopic').document(topicID).get().then((onValue) {
      if (onValue.exists) {
        return onValue.data;
      } else {
        return null;
      }
    });
  }

  Future<Map> getUserMap(String uuid) async {
    var userReference = userCollection.document(uuid);
    return userReference.get().then((onValue) {
      if (onValue.exists) {
        return onValue.data;
      } else {
        return null;
      }
    });
  }

  Future<User> getUser(String uuid) async {
    var userReference = userCollection.document(uuid);
    return userReference.get().then((onValue) {
      if (onValue.exists) {
        User user = User.fromMap(onValue.data);
        return user;
      } else {
        return null;
      }
    });
  }

  Future<dynamic> userExist(uuid) async {
    final TransactionHandler th = (Transaction tx) async {
      // check if user exists
      QuerySnapshot _query =
          await userCollection.where("uuid", isEqualTo: uuid).getDocuments();
      // create one if not
      Map<String, dynamic> map = new Map<String, dynamic>();
      map['userExist'] = _query.documents.length == 1 ? true : false;
      return map;
    };

    return Firestore.instance.runTransaction(th).then((map) {
      return map['userExist'];
    }).catchError((error) {
      print('error: $error');
      return false;
    });
  }

  // Upload Avatar images to firestore
  Future uploadAvatar(uuid, avatarImage) async {
    String imagePath = FIRESTORE_USER_AVATAR_IMG_PATH;
    String imageFile = uuid + JPEG_EXTENSION;
    final StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(imagePath).child(imageFile);
    final StorageUploadTask task = firebaseStorageRef.putFile(avatarImage);
    return await (await task.onComplete).ref.getDownloadURL();
  }

  Future<void> logout() async {
    return FirebaseAuth.instance.signOut();
  }

  String getSecretName(String topicID, int idx) {
    int topicIDHash = topicID.hashCode + idx;
    return _POSTIVE_ADJ[topicIDHash % _POSTIVE_ADJ.length] + _POSTIVE_NAME[topicIDHash % _POSTIVE_NAME.length];
  }
    static List<String> _POSTIVE_ADJ = [
      "善良的",
      "清潔的",
      "悲傷的",
      "重要的",
      "寬闊的",
      "快速的",
      "嶄新的",
      "愉快的",
      "寂靜的",
      "狹窄的",
      "簡單的",
      "輕巧的",
      "明亮的",
      "高大的",
      "苗條的",
      "富裕的",
      "肥沃的",
      "新鮮的",
      "深厚的",
      "堅硬的",
      "勇敢的",
      "慷慨的",
      "善意的",
      "堅強的",
      "活潑的",
      "開朗的",
      "坦率的",
      "爽快的",
      "豁達的",
      "豪邁的",
      "不拘小節的",
      "樂觀的",
      "意志堅定的",
      "勇敢的",
      "果斷的",
      "堅毅不屈的",
      "熱情的",
      "文靜的",
      "文質彬彬的",
      "溫文有禮的",
      "謹慎的",
      "心思縝密的",
      "成熟穩重的",
      "平易近人的",
      "溫柔體貼的",
      "和藹可親的",
      "親切的",
      "細心的",
      "談吐得體的",
      "誠實的",
      "宅心仁厚的",
      "善良的",
      "待人寬厚的",
      "實事求事的",
      "樂於助人的",
      "有恩必報的",
      "有信用的",
      "公平無私的",
      "不平則鳴的",
      "勤奮的",
      "聰明的",
      "精明的",
      "學識淵博的",
      "好學不倦的",
      "謙虛的",
      "謙遜的",
      "有智謀的",
      "有遠見的",
      "天資聰敏的",
      "靈活變通的",
      "機靈的",
      "才思敏捷的",
      "才華洋溢的",
      "智勇雙全的",
      "有幽默感的",
      "有領導才能的"
    ];
  static List<String> _POSTIVE_NAME = [
      "涂謹申",
      "梁耀忠",
      "李國麟",
      "毛孟靜",
      "胡志偉",
      "莫乃光",
      "陳志全",
      "梁繼昌",
      "郭家麒",
      "郭榮鏗",
      "張超雄",
      "黃碧雲",
      "葉建源",
      "楊岳橋",
      "尹兆堅",
      "朱凱廸",
      "何君堯",
      "林卓廷",
      "邵家臻",
      "陳沛然",
      "陳淑莊",
      "許智峯",
      "鄭松泰",
      "鄺俊宇",
      "譚文豪",
      "范國威",
      "區諾軒",
      "梁頌恆",
      "游蕙禎",
      "梁天琦",
      "陳浩天",
      "黃台仰",
      "周庭",
      "古思堯",
      "黃之鋒",
      "羅冠聰",
      "梁國雄",
      "戴耀廷",
      "吳文遠",
      "劉小麗",
      "游蕙禎"
    ];
  static List<String> _NEGATIVE_ADJ = [
      "陳舊的",
      "緩慢的",
      "骯髒的",
      "次要的",
      "笨重的",
      "昏暗的",
      "矮小的",
      "肥胖的",
      "貧困的",
      "貧瘠的",
      "腐爛的",
      "便宜的",
      "怯懦的",
      "稀疏的",
      "吝嗇的",
      "邪惡的",
      "天真的",
      "衝動的",
      "粗心大意的",
      "冒失的",
      "衝動的",
      "馬虎的",
      "草率的",
      "敷衍塞責的",
      "魯莽的",
      "脾氣暴躁的",
      "急躁的",
      "橫蠻無理的",
      "膽小怕事的",
      "自卑的",
      "容易緊張的",
      "不擅交際的",
      "不合群的",
      "狡猾的",
      "陰險的",
      "刻薄的",
      "挑剔的",
      "自私自利的",
      "心胸狹隘的",
      "殘忍的",
      "卑鄙的",
      "寡情薄倖的",
      "虛偽的",
      "貪財好利的",
      "貪心的",
      "忘恩負義的",
      "見利忘義的",
      "沒有信用的",
      "懶惰的",
      "好逸惡勞的",
      "糊塗的",
      "魯鈍的",
      "愚昧無知的",
      "吊兒郎當的",
      "狂妄自大的",
      "驕傲的",
      "不自量力的",
      "好高騖遠的",
      "輕佻的",
      "昏庸無能的",
      "孤陋寡聞的",
      "自以為是的",
      "喜歡逞強的"
    ];
  static List<String> _NEGATIVE_NAME = [
      "田北辰",
      "何俊賢",
      "梁君彥",
      "黃定光",
      "李慧琼",
      "馬逢國",
      "陳克勤",
      "麥美娟",
      "陳健波",
      "陳恒鑌",
      "梁志祥",
      "石禮謙",
      "林健鋒",
      "郭偉强",
      "張宇人",
      "梁美芬",
      "黃國健",
      "葉劉淑儀",
      "謝偉俊",
      "葛珮帆",
      "廖長江",
      "蔣麗芸",
      "盧偉國",
      "鍾國斌",
      "何啟明",
      "周浩鼎",
      "柯創盛",
      "容海恩",
      "張國鈞",
      "陸頌雄",
      "劉國勳",
      "鄭泳舜",
      "謝偉銓",
      "陳凱欣",
      "湯家驊",
      "馮檢基",
      "陳云",
      "容樂其",
      "仇思達",
      "王維基",
      "鄭耀宗",
      "曾鈺成",
      "鄺保羅",
      "陳維安",
      "林鄭月娥",
      "盧寵茂",
      "梁振英",
      "吳秋北",
      "陳茂波",
      "白韻琹",
      "鄭汝樺",
      "屈穎妍",
      "董建華",
      "曾蔭權",
      "唐英年",
      "田北俊",
      "陳帆",
      "劉江華",
      "楊偉雄",
      "楊潤雄",
      "黃錦星",
      "陳淨心"
    ];
}
