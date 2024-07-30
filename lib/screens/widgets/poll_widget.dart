import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class Poll {
  final String question;
  final List<String> options;
  final Map<String, int> votes;
  final Map<String, String> userVotes;

  Poll({
    required this.question,
    required this.options,
    required this.votes,
    required this.userVotes,
  });

  factory Poll.fromMap(Map<String, dynamic> map) {
    return Poll(
      question: map['question'] ?? '',
      options: List<String>.from(map['options']),
      votes: Map<String, int>.from(map['votes']),
      userVotes: Map<String, String>.from(map['userVotes']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'votes': votes,
      'userVotes': userVotes,
    };
  }
}

class PollWidget extends StatelessWidget {
  final Poll poll;
  final String messageId;
  final bool hasVoted;
  final Function(int) onVote;

  PollWidget({
    required this.poll,
    required this.messageId,
    required this.hasVoted,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...poll.options.asMap().entries.map((entry) {
          int index = entry.key;
          String option = entry.value;
          return ListTile(
            title: Text(option),
            trailing: hasVoted
                ? Text('${poll.votes[option] ?? 0}')
                : IconButton(
              icon: Icon(Icons.check),
              onPressed: () => onVote(index),
            ),
          );
        }).toList(),
      ],
    );
  }
}
