import 'dart:developer';

import 'package:chatgpt_course/constants/constants.dart';
import 'package:chatgpt_course/providers/chats_provider.dart';
import 'package:chatgpt_course/services/services.dart';
import 'package:chatgpt_course/widgets/chat_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';  // Import for camera functionality
import 'dart:typed_data';

import '../providers/models_provider.dart';
import '../services/assets_manager.dart';
import '../widgets/text_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isTyping = false;
  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;
  Uint8List? _imageBytes;  // Store selected image bytes

  @override
  void initState() {
    super.initState();
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelsProvider = Provider.of<ModelsProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context); // Get the chat provider，有用到changeNotifier

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(AssetsManager.openaiLogo),
        ),
        title: const Text("ChatGPT"),
        actions: [
          IconButton(
            onPressed: () async {
              await Services.showModalSheet(context: context);
            },
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                  controller: _listScrollController,
                  itemCount: chatProvider.getChatList.length,
                  itemBuilder: (context, index) {
                    return ChatWidget(
                      msg: chatProvider.getChatList[index].msg,
                      chatIndex: chatProvider.getChatList[index].chatIndex,
                      shouldAnimate: chatProvider.getChatList.length - 1 == index,
                    );
                  }),
            ),
            if (_isTyping) const SpinKitThreeBounce(
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(height: 15),
            Material(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _pickImage(),
                      icon: const Icon(
                        Icons.upload_file, //image
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        controller: textEditingController,
                        onSubmitted: (value) async {
                          await _sendMessage(modelsProvider, chatProvider);
                        },
                        decoration: const InputDecoration.collapsed(
                          hintText: "How can I help you",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await _sendMessage(modelsProvider, chatProvider);
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
             // Display the selected image preview if an image is selected
            if (_imageBytes != null) ...[
              const SizedBox(height: 3),
              Image.memory(
                _imageBytes!,
                width: 150,  // 設定圖片的寬度
                height: 150, // 設定圖片的高度
                fit: BoxFit.cover, // 設定圖片的顯示模式，這裡使用 cover 會保持圖片比例並填充容器
              ),
              const SizedBox(height: 3),
            ],
          ],
        ),
      ),
    );
  }

  void scrollListToEnd() {
    _listScrollController.animateTo(
      _listScrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage(ModelsProvider modelsProvider, ChatProvider chatProvider) async {
    if (_isTyping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "You can't send multiple messages at the same time.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "Please type a message.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      String msg = textEditingController.text;

      setState(() {
        _isTyping = true;
        chatProvider.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });

      if (_imageBytes != null) {
        // If there is an image, send image and text to the image model
        await chatProvider.sendImageAndGetAnswers(
          msg: msg,
          image: _imageBytes!,
          chosenModelId: "gpt-4o-mini", // modelsProvider.getImageModel
        );
      } else {
        // If there is no image, send text message to the text model
        await chatProvider.sendMessageAndGetAnswers(
          msg: msg,
          chosenModelId: "gpt-4o-mini", //modelsProvider.getCurrentModel
        );
      }
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(label: error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        scrollListToEnd();
        _imageBytes = null;  // Clear the selected image bytes
        _isTyping = false; // Reset the typing state
      });
    }
  }

  Future<void> _pickImage() async {
    log('Image Picker pressed');

    // Show a dialog to choose between camera or gallery
    final pickedSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select image source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (pickedSource == null) return;  // If no source was selected, return

    // If the source is the camera, use ImagePicker for gallery or camera
    final image = await ImagePicker().pickImage(
      source: pickedSource,
      maxWidth: 1980,
      maxHeight: 1980,
    );

    if (image == null) {
      log("No image selected.");
      return;
    }

    log("Image selected yeah.");
    final imageBytes = await image.readAsBytes();
    setState(() {
      _imageBytes = imageBytes;
    });
  }


/* old without camera function
  Future<void> _pickImage() async {
    log('Image Picker pressed');
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery, //gallery
      maxWidth: 1980,
      maxHeight: 1980,
    );

    if (image == null) {
      log("No image selected.");
      return;
    }

    log("Image selected yeah.");
    final imageBytes = await image.readAsBytes();
    setState(() {
      _imageBytes = imageBytes;
    });
  }
  */
}
