class Utils {
  static String getProgramNoString(int programNo) {
    String numPart = ((programNo ~/ 4) + 1).toString();
    if (numPart.length == 1) {
      numPart = '0$numPart';
    }

    String charPart = '';
    switch (programNo % 4) {
      case 0:
        charPart = 'A';
        break;
      case 1:
        charPart = 'B';
        break;
      case 2:
        charPart = 'C';
        break;
      case 3:
        charPart = 'D';
    }

    return numPart + charPart;
  }
}
