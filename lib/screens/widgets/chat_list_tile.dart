import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Add this import for date formatting

class ChatListTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final bool isUnread;
  final VoidCallback onTap;

  ChatListTile({
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('hh:mm a').format(lastMessageTime.toDate());

    return ListTile(
      leading: CircleAvatar(
      ),
      title: Text(name),
      subtitle: Text(lastMessage),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(formattedTime),
          if (isUnread)
            Text(
              'Unread',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
