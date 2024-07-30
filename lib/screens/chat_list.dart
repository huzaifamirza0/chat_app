import 'package:chat_app/screens/user_list.dart';
import 'package:chat_app/screens/widgets/chat_list_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  final String currentUserId;

  ChatListPage({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat app'),
        actions: [
          IconButton(onPressed: (){
            Get.to(UserListPage(currentUserId: currentUserId));
          }, icon: const Icon(Icons.search_rounded))
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              var chatRoom = chatRooms[index];
              var chatRoomData = chatRoom.data() as Map<String, dynamic>;
              print(chatRoomData);

              var participants = List<String>.from(chatRoomData['participants']);
              String otherParticipantId = participants.firstWhere((id) => id != currentUserId);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherParticipantId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      title: const Text('Loading...'),
                      subtitle: Text(chatRoomData['lastMessage'] ?? 'No messages yet'),
                      trailing: Text(chatRoomData['lastMessageTime'].toDate().toString()),
                    );
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                  return ChatListTile(
                    name: userData['displayName'] ?? 'Unknown',
                    lastMessage: chatRoomData['lastMessage'] ?? 'No messages yet',
                    lastMessageTime: chatRoomData['lastMessageTime'],
                    isUnread: chatRoomData['isUnread'] ?? false,
                    onTap: () {
                      Get.to(ChatPage(chatRoomId: chatRoom.id));
                    },
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
