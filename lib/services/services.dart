import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../widgets/drop_down.dart';
import '../widgets/text_widget.dart';

/*
import 'package:canvas/canvas/canvas_object.dart';
import 'package:canvas/main.dart';
import 'package:canvas/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
*/
class Services {
  static Future<void> showModalSheet({required BuildContext context}) async {
    await showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        backgroundColor: scaffoldBackgroundColor,
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Flexible(
                  child: TextWidget(
                    label: "Chosen Model:",
                    fontSize: 16,
                  ),
                ),
                Flexible(flex: 2, child: ModelsDrowDownWidget()),
              ],
            ),
          );
        });
  }

  // Show image picker
  

  /*
  Future<void> _uploadImage() async {
    assert(widget.object != null,
        'An object needs to be selected before uploading an image.');
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1980,
      maxHeight: 1980,
    );
    if (image == null) return;
    final imageBytes = await image.readAsBytes();
    final storagePath =
        'objects/${widget.object!.id}${DateTime.now().millisecondsSinceEpoch}';
    await supabase.storage.from(Constants.storageBucketName).uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(
            contentType: image.mimeType,
            upsert: true,
          ),
        );

    widget.onObjectChanged(widget.object!.copyWith(imagePath: storagePath));
    if (widget.object?.imagePath != null) {
      await supabase.storage
          .from(Constants.storageBucketName)
          .remove([widget.object!.imagePath!]);
    }
  }
  */
}
