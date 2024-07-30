import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

class UserListPage extends StatelessWidget {
  final String currentUserId;

  UserListPage({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select User'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              if (user['uid'] == currentUserId) {
                // Skip the current user
                return Container();
              }
              return ListTile(
                title: Text(user['displayName']),
                onTap: () async {
                  // Check if a chat room already exists between the current user and the selected user
                  var chatRooms = await FirebaseFirestore.instance
                      .collection('chatRooms')
                      .where('participants', arrayContainsAny: [currentUserId, user['uid']])
                      .get();
                  var chatRoomDoc;
                  if (chatRooms.docs.isEmpty) {
                    // Create a new chat room
                    chatRoomDoc = await FirebaseFirestore.instance.collection('chatRooms').add({
                      'participants': [currentUserId, user['uid']],
                      'lastMessage': '',
                      'lastMessageTime': FieldValue.serverTimestamp(),
                    });
                  } else {
                    // Use the existing chat room
                    chatRoomDoc = chatRooms.docs.first;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(chatRoomId: chatRoomDoc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
