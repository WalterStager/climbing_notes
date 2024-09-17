import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:climbing_notes/add_route.dart';
import 'package:climbing_notes/builders.dart';
import 'package:climbing_notes/data_structures.dart';
import 'package:climbing_notes/utility.dart';
import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

// class OCRPickerPopup extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return
//   }
// }

class OCRService {
  TextRecognizer? textRecognizer = null;

  Future<void> start() async {
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  Widget ocrPickerPopup(BuildContext context) {
    // Color textColor = contrastingThemeTextColor(context);
    return FittedBox(
      fit: BoxFit.contain,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            OutlinedButton(
              onPressed: () => (
                Navigator.pop(context, ImageSource.camera)
              ),
              child: const Row(
                children: [
                  Icon(Icons.camera),
                  Text("Take picture", style: TextStyle()),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => (
                Navigator.pop(context, ImageSource.gallery)
              ),
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

    // FilePickerResult? result = await FilePicker.platform
    //     .pickFiles(allowMultiple: false, type: FileType.image);
    // File file = File(result.files.single.path!);

  Future<DBRoute?> filePickerOcrAdd(BuildContext context) async {
    ImageSource? pickType = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: ocrPickerPopup,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 1)),
      isDismissible: true,
      enableDrag: false,
      showDragHandle: false,
      isScrollControlled: false,
    );
    if (pickType == null) {
      return null;
    }


    ImagePicker picker = ImagePicker();
    XFile? pickResult = await picker.pickImage(source: pickType, requestFullMetadata: true);

    if (pickResult == null) {
      return null;
    }

    // Uint8List bytes = await pickResult.readAsBytes();
    // Map<String, IfdTag> tags = await readExifFromBytes(bytes);
    // int? width = tags['EXIF ExifImageWidth']?.values.firstAsInt();
    // int? height = tags['EXIF ExifImageLength']?.values.firstAsInt();
    // int? orientation = tags['Image Orientation']?.values.firstAsInt();
    // int? bitsPerSample = tags['BitsPerSample']?.values.firstAsInt();
    // int? samplesPerPixel = tags['SamplesPerPixel']?.values.firstAsInt();

    // if (width == null || height == null || bitsPerSample == null || samplesPerPixel == null || orientation != null) {
    //   log("Couldnt get metadata");
    //   log("${width} ${height} ${orientation} ${bitsPerSample} ${samplesPerPixel}");
    //   log("${tags.keys.toList().toString()}");
    //   log("${tags.keys.length}");
    //   return null;
    // }

    // int bytesPerRow = (width * bitsPerSample * samplesPerPixel) ~/ 8;

    // InputImage inputImage = InputImage.fromBytes(bytes: bytes, metadata: InputImageMetadata(size: Size(width as double, height as double), bytesPerRow: bytesPerRow, rotation: InputImageRotation.rotation0deg, format: InputImageFormat.));
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

// class OCRPage extends StatefulWidget {
//   const OCRPage({super.key});

//   @override
//   State<OCRPage> createState() => _OCRPageState();
// }

// class _OCRPageState extends State<OCRPage> {
//   _OCRPageState();

//   void errorPopup(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void tryParseText(DBRoute route, String text) {
//     String textlower = text.toLowerCase();
//     if (route.color == null) {
//       for (String colorString in colorStrings) {
//         if (textlower == colorString.toLowerCase()) {
//           route.color = colorString;
//           return;
//         }
//       }
//     }

//     if (route.date == null) {
//       DateTime? time = likelyTimeFromTimeDisplay(SmallDateFormat.mmdd, textlower);
//       if (time != null) {
//         route.date = time.toUtc().toIso8601String();
//         return;
//       }
//     }

//     if (route.gradeNum == null) {
//       RegExpMatch? match = strictGradeExp.firstMatch(textlower);
//       String? num = match?.namedGroup("num");
//       String? let = match?.namedGroup("let");
//       if (num != null) {
//         route.gradeNum = stringToInt(num);
//         route.gradeLet = let;
//         return;
//       }
//     }

//     if (route.rope == null) {
//       int? rope = stringToInt(textlower);
//       if (rope != null) {
//         route.rope = rope;
//         return;
//       }
//     }
//   }

//   Future<void> tryOcr() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false, type: FileType.image);

//     if (result != null) {
//       File file = File(result.files.single.path!);
//       InputImage inputImage = InputImage.fromFile(file);
//       TextRecognizer textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
//       RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
//       String text = recognizedText.text;
//       DBRoute route = DBRoute(0, "", "", null, null, null, null, null, null);
//       for (TextBlock block in recognizedText.blocks) {
//         for (TextLine line in block.lines) {
//           for (TextElement element in line.elements) {
//             log("${element.text} ${element.confidence}");
//             tryParseText(route, element.text);
//           }
//         }
//       }
//       log(route.toString());

//       if (route.color != null && route.date != null && route.gradeNum != null && route.rope != null) {
//         Navigator.pop(context);
//         Navigator.push(context, cnPageTransition(new AddRoutePage(providedRoute: route))); //
//       }
//     } else {
//       errorPopup("Didn't get file");
//       return;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const ClimbingNotesAppBar(pageTitle: "Settings"),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: ListView(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 OutlinedButton(onPressed: tryOcr, child: Text("Press me"))
//               ],
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: Align(
//         alignment: Alignment.bottomRight,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: <Widget>[
//             FloatingActionButton(
//               heroTag: "backFloatBtn",
//               onPressed: () => {
//                 Navigator.pop(context),
//               },
//               tooltip: 'Back',
//               child: const Icon(Icons.arrow_back_rounded),
//             ),
//             const SizedBox(height: 8),
//             // FloatingActionButton(
//             //   heroTag: "saveFloatBtn",
//             //   onPressed: saveSettings,
//             //   tooltip: 'Save settings',
//             //   child: const Icon(Icons.save),
//             // ),
//           ],
//         ),
//       ),
//       drawer: const ClimbingNotesDrawer(),
//     );
//   }
// }
