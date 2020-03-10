class StringHelper {

  StringHelper();

  // use to find hash tag or http
  static List<String> keywordSearch(String value, String keyword) {
    List<String> rv = []; 
    List<String> words = value.split(" ");
    print(words);
    words.forEach((word) {
      if(word.startsWith(keyword) && word.length > 1) {
        String rest = word.substring(keyword.length);
        if(!rest.startsWith(" ") && !rv.contains(rest)) {
          rv.add(rest);
        }
      }
    });
    rv = rv.toSet().toList();
    return rv;
  }

  static String parseAddress(String messageDesc) {
        String rv;
        RegExp regExp = new RegExp(r'(地點|地址)(:| :|：| ：)(.*)', unicode: true);
        if(regExp.hasMatch(messageDesc)) {
          Match match = regExp.firstMatch(messageDesc); 
          if(match != null) {
            rv = match.group(3);
          }
        }
        return rv;
  }


// TODO for extract Date and time from Description
  /*
  static String parseDate(messageDesc) {
    String rv;
    RegExp r1 = RegExp(r'/(20[1-9]{2})(-|\/)([1-9]|0[1-9]|1[0-2])(-|\/)([1-9]|0[1-9]|[12]\d|3[01])/');
    Match m1 = r1.firstMatch(messageDesc);
    // DD/MM/YYYY
    RegExp r2 = RegExp(r'/([1-9]|0[1-9]|[12]\d|3[01])(-|\/)([1-9]|0[1-9]|1[0-2])(-|\/)(20[1-9]{2})/');
    Match m2 = r2.firstMatch(messageDesc);
    // 10月31日
    RegExp r3 = RegExp(r'/([1-9]|0[1-9]|1[0-2])月([1-9]|0[1-9]|[12]\d|3[01])日/u');
    Match m3 = r3.firstMatch(messageDesc);
    // 2018年10月31日
    RegExp r4 = RegExp(r'/(20[1-9]{2})年([1-9]|0[1-9]|1[0-2])月([1-9]|0[1-9]|[12]\d|3[01])日/u');
    Match m4 = r4.firstMatch(messageDesc);


        if(messageDesc.match(r1) != null) {
            resolve(messageDesc.match(r1)[0]);
        } else if(messageDesc.match(r2) != null) {
            let YYYY = messageDesc.match(r2)[3];
            let MM = messageDesc.match(r2)[2];
            let DD = messageDesc.match(r2)[1];
            if(MM.length === 1) {
                MM = '0'+MM;
            }
            if(DD.length === 1) {
                DD = '0'+DD;
            }
            resolve(YYYY + '-' + MM + '-' + DD);
        } else if(messageDesc.match(r3) != null) {
            let YYYY = new Date().getFullYear();
            let MM = messageDesc.match(r3)[1];
            let DD = messageDesc.match(r3)[2];
            if(MM.length === 1) {
                MM = '0'+MM;
            }
            if(DD.length === 1) {
                DD = '0'+DD;
            }
            resolve(YYYY + '-' + MM + '-' + DD);
        } else if(messageDesc.match(r4) != null) {
            let YYYY = messageDesc.match(r4)[1];
            let MM = messageDesc.match(r4)[2];
            let DD = messageDesc.match(r4)[3];
            if(MM.length === 1) {
                MM = '0'+MM;
            }
            if(DD.length === 1) {
                DD = '0'+DD;
            }
            resolve(YYYY + '-' + MM + '-' + DD);
        } else {
            resolve(null);
        }
    }); 
}

/**
 * Parse message description and return a string with HH:MM format if it matches with below regex
 * @param {string} messageDesc
 * @returns {(string|null)} 
 */
export function parseTime(messageDesc) {
    return new Promise( (resolve, reject) => {
        // HH:MM
        let r1 = /(2[0-3]|[01]?[0-9]):([0-5]?[0-9])/;
        let r2 = /(下午)/;
        
        if(messageDesc.match(r1) != null) {
            let HH = messageDesc.match(r1)[1];
            let MM = messageDesc.match(r1)[2];

            if(HH.length === 1) {
                HH = '0' + HH;
            }

            if(MM.length === 1) {
                MM = '0' + MM;
            }

            if(messageDesc.match(r2) != null) {
                if(parseInt(HH) < 12) {
                    HH = parseInt(HH) + 12;
                }
            }
            
            resolve(HH + ':' + MM);
        } else {
            resolve(null);
        }
    }); 
}
*/
}