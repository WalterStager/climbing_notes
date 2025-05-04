import 'dart:developer';
import 'package:climbing_notes/builders.dart';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/utility.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saver_gallery/saver_gallery.dart';

class OCRService {
  TextRecognizer? textRecognizer;

  Future<void> start() async {
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  void errorPopup(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget ocrPickerPopup(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            OutlinedButton(
              onPressed: () => (Navigator.pop(context, ImageSource.camera)),
              child: const Row(
                children: [
                  Icon(Icons.camera),
                  Text("Take picture", style: TextStyle()),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => (Navigator.pop(context, ImageSource.gallery)),
              child: const Row(
                children: [
                  Icon(Icons.file_copy),
                  Text("Choose image", style: TextStyle()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DBRoute?> filePickerOcrAdd(BuildContext context, ImageSource source) async {
    // ImageSource? pickType = await modalBottomPopup<ImageSource>(context, ocrPickerPopup);

    // if (pickType == null) {
    //   errorPopup(context, "Could not get file");
    //   return null;
    // }

    ImagePicker picker = ImagePicker();
    XFile? pickResult =
        await picker.pickImage(source: source, requestFullMetadata: true);

    if (pickResult == null) {
      errorPopup(context, "Could not get file");
      return null;
    }
    // log(pickResult.path);
    if (source == ImageSource.camera) {
      SaveResult result = await SaverGallery.saveFile(fileName: pickResult.name, filePath: pickResult.path, skipIfExists: true, androidRelativePath: "Pictures/ClimbingNotes/images");
      log(result.toString());
    }

    InputImage inputImage = InputImage.fromFilePath(pickResult.path);

    RecognizedText? recognizedText =
        await textRecognizer?.processImage(inputImage);
    if (recognizedText != null) {
      DBRoute route = DBRoute(0, "", "", null, null, null, null, null, null);
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            log("${element.text} ${element.confidence}");
            tryParseText(route, element.text);
          }
        }
      }
      log(route.toString());

      if (route.color != null &&
          route.date != null &&
          route.gradeNum != null &&
          route.rope != null) {
        return route;
      }
    }

    errorPopup(context, "Could not find route information");
    return null;
  }

  void tryParseText(DBRoute route, String text) {
    String textlower = text.toLowerCase();
    if (route.color == null) {
      for (String colorString in colorStrings) {
        if (textlower == colorString.toLowerCase()) {
          route.color = colorString;
          return;
        }
      }
    }

    if (route.date == null) {
      DateTime? time =
          likelyTimeFromTimeDisplay(SmallDateFormat.mmdd, textlower);
      if (time != null) {
        route.date = time.toUtc().toIso8601String();
        return;
      }
    }

    if (route.gradeNum == null) {
      RegExpMatch? match = strictGradeExp.firstMatch(textlower);
      String? num = match?.namedGroup("num");
      String? let = match?.namedGroup("let");
      if (num != null) {
        route.gradeNum = stringToInt(num);
        route.gradeLet = let;
        return;
      }
    }

    if (route.rope == null) {
      int? rope = stringToInt(textlower);
      if (rope != null) {
        route.rope = rope;
        return;
      }
    }
  }
}
