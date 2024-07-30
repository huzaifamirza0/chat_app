import 'dart:io';
import 'package:chat_app/screens/widgets/message_widgget.dart';
import 'package:chat_app/screens/widgets/poll_widget.dart';
import 'package:chat_message_timestamp/chat_message_timestamp.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;


class ChatPage extends StatefulWidget {
  final String chatRoomId;

  const ChatPage({required this.chatRoomId, Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _addMessage(Map<String, dynamic> message) {
    setState(() {
      _messages.insert(0, message);
      print(message);
    });
    _saveMessage(message);
  }

  void _saveMessage(Map<String, dynamic> message) async {
    // Ensure 'content' exists and is a string
    String lastMessageText = message['content'] is String
        ? message['content']
        : 'Poll'; // Or some default value or handle the error

    try {
      // Save the message to Firestore
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add(message);

      // Update last message info in chat room
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .update({
        'lastMessage': lastMessageText,
        'lastMessageTime': Timestamp.now(),
      });
    } catch (e) {
      print('Error saving message: $e');
      // Handle error accordingly
    }
  }

  void _handleSendPressed({String? imageUrl, String? fileUrl, String? fileName}) {
    if (_messageController.text.trim().isEmpty && imageUrl == null && fileUrl == null) return;

    final message = {
      'senderId': _auth.currentUser?.uid,
      'content': _messageController.text.trim(),
      'imageUrl': imageUrl ?? '',
      'fileUrl': fileUrl ?? '',
      'fileName': fileName ?? '',
      'timestamp': Timestamp.now(),
    };

    _addMessage(message);
    _messageController.clear();
  }

  void _loadMessages() async {
    FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) => doc.data())
          .toList();
      setState(() {
        _messages = messages;
      });
    });
  }

  void _handleCreatePoll() async {
    TextEditingController questionController = TextEditingController();
    List<TextEditingController> optionControllers = [TextEditingController(), TextEditingController()];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Poll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: questionController, decoration: const InputDecoration(hintText: 'Question')),
              const SizedBox(height: 8.0),
              ...optionControllers.map((controller) => TextField(controller: controller, decoration: const InputDecoration(hintText: 'Option'))),
              const SizedBox(height: 8.0),
              TextButton(
                onPressed: () {
                  optionControllers.add(TextEditingController());
                  setState(() {});
                },
                child: const Text('Add Option'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final poll = Poll(
                  question: questionController.text.isNotEmpty ? questionController.text : 'No Question', // Ensure not empty
                  options: optionControllers.map((controller) => controller.text).where((text) => text.isNotEmpty).toList(), // Ensure not empty
                  votes: {},
                  userVotes: {},
                );
                print(poll.options);
                print(poll.question);
                print('Question: ${questionController.text}');
                print('Options: ${optionControllers.map((controller) => controller.text).toList()}');

                _handleSendPoll(poll);
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }


  void _handleSendPoll(Poll poll) {
    print('Poll Data: ${poll.toMap()}');
    final message = {
      'senderId': _auth.currentUser?.uid,
      'poll': poll.toMap(),
      'timestamp': Timestamp.now(),
    };
    _addMessage(message);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chat Room'),
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final map = _messages[index];
              return MessageWidget(size: MediaQuery.of(context).size, map: map);
            },
          ),
        ),
        _buildInput(),
      ],
    ),
  );

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _handleAttachmentPressed,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type a message',
              ),
              onSubmitted: (_) => _handleSendPressed(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.purple,),
            onPressed: () => _handleSendPressed(),
          ),
        ],
      ),
    );
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 230,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  selectAndUploadImage();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  selectAndUploadFile();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleCreatePoll();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Poll'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> selectAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = path.basename(file.path);
        String fileExtension = path.extension(file.path).toLowerCase();
        String storagePath =
            'uploads/${DateTime.now().millisecondsSinceEpoch}$fileExtension';
        UploadTask task = _storage.ref(storagePath).putFile(file);

        TaskSnapshot snapshot = await task;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        _handleSendPressed(fileUrl: downloadUrl, fileName: fileName);
      }
    } catch (e) {
      print('File upload error: $e');
    }
  }

  Future<void> selectAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File file = File(pickedFile.path);
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        UploadTask task = _storage.ref('uploads/$fileName').putFile(file);

        TaskSnapshot snapshot = await task;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        _handleSendPressed(imageUrl: downloadUrl);
      }
    } catch (e) {
      print('Image upload error: $e');
    }
  }
}

