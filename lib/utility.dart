import 'dart:developer';
import 'package:intl/intl.dart';

RegExp gradeExp = RegExp(r'^5?\.?(?<num>\d{1,2})?(?<let>[a-d])?$');
RegExp dateExp = RegExp(r'^(?<day>\d{1,2})/?(?<month>\d{1,2})?$');

// returns null if input is null or its not a valid int
int? stringToInt(String? s) {
  if (s == null) {
    return null;
  }
  else {
    return int.tryParse(s);
  }
}

int? boolToInt(bool? b) {
  if (b == null) {
    return null;
  }
  return b == true ? 1 : 0;
}

bool? intToBool(int? i) {
  if (i == null) {
    return null;
  }
  return i == 1 ? true : false;
}

String getTimestamp() {
  return DateTime.now().toUtc().toIso8601String();
}

DateTime timeFromTimestamp(String s) {
  return DateTime.parse(s);
}

String timeDisplayFromTimestamp(String? s) {
  if (s == null) {
    return "";
  }
  return DateFormat("dd-MM").format(DateTime.parse(s));
}

DateTime? likelyTimeFromTimeDisplay(String s) {
  log("$s");
  RegExpMatch? match = dateExp.firstMatch(s);
  if (match == null) {
    return null;
  }

  DateTime now = DateTime.now();
  if (match.namedGroup("day") != null && match.namedGroup("month") != null) {
    String month = "${match.namedGroup("month")}".padLeft(2, '0');
    String day = "${match.namedGroup("day")}".padLeft(2, '0');
    DateTime earlyGuess = DateTime.parse("${now.year}-$month-$day");
    DateTime lateGuess = DateTime.parse("${now.year-1}-$month-$day");
    int earlyGuessDiff = now.difference(earlyGuess).abs().inMinutes;
    int lateGuessDiff = now.difference(lateGuess).abs().inMinutes; 

    if (earlyGuessDiff < lateGuessDiff) {
      return earlyGuess;
    }
    else {
      return lateGuess;
    }
  }
  log("2");
  return null;
}