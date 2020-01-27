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
    return rv;
  }
}