import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class Poll {
  final String question;
  final List<String> options;
  final Map<String, List<int>> votes; // User ID -> List of option indices
  final Map<String, int> userVotes;   // User ID -> Option index

  Poll({
    required this.question,
    required this.options,
    required this.votes,
    required this.userVotes,
  });

  factory Poll.fromMap(Map<String, dynamic> map) {
    return Poll(
      question: map['question'] as String,
      options: List<String>.from(map['options']),
      votes: Map<String, List<int>>.from(map['votes']),
      userVotes: Map<String, int>.from(map['userVotes']),
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



class PollWidget extends StatefulWidget {
  final Poll poll;
  final String messageId;
  final bool hasVoted;
  final Function(int) onVote;

  const PollWidget({
    required this.poll,
    required this.messageId,
    required this.hasVoted,
    required this.onVote,
    Key? key,
  }) : super(key: key);

  @override
  _PollWidgetState createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    if (widget.hasVoted) {
      _selectedOption = widget.poll.userVotes[FirebaseAuth.instance.currentUser?.uid];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50.0),
      child: Card(
        color: Colors.purple[300],
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.poll.question,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 8),
              ...List.generate(widget.poll.options.length, (index) {
                final option = widget.poll.options[index];
                return RadioListTile<int>(
                  activeColor: Colors.white,
                  title: Text(option, style: TextStyle(color: Colors.white),),
                  value: index,
                  groupValue: _selectedOption,
                  onChanged: widget.hasVoted
                      ? null // Disable changes if already voted
                      : (value) {
                    setState(() {
                      _selectedOption = value;
                    });
                    widget.onVote(index);
                  },
                );
              }),
              if (widget.hasVoted)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'You voted for: ${widget.poll.options[_selectedOption ?? 0]}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
