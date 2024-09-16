// ignore: unused_import
import 'dart:developer';
import 'package:climbing_notes/data_structures.dart';
import 'package:intl/intl.dart';

RegExp gradeExp = RegExp(r'^5?\.?(?<num>\d{1,2})?(?<let>[a-d])?$');
RegExp dateExp = RegExp(r'^(?<g1>\d{1,2})[^\w]?(?<g2>\d{1,2})?$');

// returns null if input is null or its not a valid int
int? stringToInt(String? s) {
  if (s == null) {
    return null;
  } else {
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


String timeDisplayFromTimestampSafe(SmallDateFormat format, String? s) {
  try {
    return timeDisplayFromTimestamp(format, s);
  } on FormatException {
    return s ?? "";
  }
}

String timeDisplayFromTimestamp(SmallDateFormat format, String? s) {
  if (s == null) {
    return "";
  }
  if (format == SmallDateFormat.ddmm) {
    return DateFormat("dd-MM").format(DateTime.parse(s).toLocal());
  } else {
    return DateFormat("MM-dd").format(DateTime.parse(s).toLocal());
  }
}

String timeDisplayFromDateTime(SmallDateFormat format, DateTime? dt) {
  if (dt == null) {
    return "";
  }
  if (format == SmallDateFormat.ddmm) {
    return DateFormat("dd-MM").format(dt.toLocal());
  } else {
    return DateFormat("MM-dd").format(dt.toLocal());
  }
}

// parses a date like dd/mm into the nearest full datetime (in the past)
// for ease of use this will also return a datetime if s is already an Iso8601 UTC String
DateTime? likelyTimeFromTimeDisplay(SmallDateFormat format, String s) {
  DateTime? parsed = DateTime.tryParse(s);
  if (parsed != null && parsed.isUtc) {
    return parsed;
  }

  RegExpMatch? match = dateExp.firstMatch(s);
  if (match == null) {
    return null;
  }

  DateTime now = DateTime.now();
  if (match.namedGroup("g1") != null && match.namedGroup("g2") != null) {
    String g1 = "${match.namedGroup("g1")}".padLeft(2, '0'),
        g2 = "${match.namedGroup("g2")}".padLeft(2, '0');
    DateTime earlyGuess, lateGuess;
    if (format == SmallDateFormat.ddmm) {
      earlyGuess = DateTime.parse("${now.year}-$g2-$g1");
      lateGuess = DateTime.parse("${now.year - 1}-$g2-$g1");
    } else {
      earlyGuess = DateTime.parse("${now.year}-$g1-$g2");
      lateGuess = DateTime.parse("${now.year - 1}-$g1-$g2");
    }
    int earlyGuessDiff = now.difference(earlyGuess).abs().inMinutes,
        lateGuessDiff = now.difference(lateGuess).abs().inMinutes;

    if (earlyGuessDiff < lateGuessDiff) {
      return earlyGuess;
    } else {
      return lateGuess;
    }
  }
  return null;
}