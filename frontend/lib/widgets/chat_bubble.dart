import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_model/shared_model.dart';
import 'package:url_launcher/link.dart';
import 'package:wanna_chat_app/widgets/extensions.dart';

/// ChatBubble
class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.sessionInitials, required this.message, required this.maxWidth, super.key});

  final String sessionInitials;
  final WannaChatMessage message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isAi ? MainAxisAlignment.start : MainAxisAlignment.end;
    return Row(mainAxisAlignment: alignment, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (message.isAi)
        const CircleAvatar(
          backgroundImage: AssetImage('assets/ai_avatar.png'),
          radius: 24,
        ).padded(right: 12),
      _content(context).constrained(maxWidth: maxWidth - 60, minHeight: 48), // 2*24 + 12
      if (message.isHuman)
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.teal,
          child: Text(
            sessionInitials,
            style: const TextStyle(color: Colors.white),
          ).padded(all: 8),
        ).padded(left: 12),
    ]).padded(vertical: 8);
  }

  Widget _content(BuildContext context) {
    final color = message.isAi ? Colors.black12 : Colors.teal.withOpacity(0.25);
    final messageText = message.isAiLoading ? '' : message.message;
    final Widget content = Column(children: [
      MarkdownBody(data: messageText, selectable: true),
      if (message.isAiLoading) const LinearProgressIndicator(),
      if (message.citations.isNotEmpty) ...[
        Text('Citations:', style: context.labelSmall.copyWith(fontWeight: FontWeight.bold))
            .aligned(Alignment.centerLeft)
            .padded(top: 16),
        ...message.citations.indexed.map((e) => _citationLink(context, e.$2, e.$1)),
      ],
    ]);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        child: content.padded(all: 12),
      ),
    );
  }

  Widget _citationLink(BuildContext context, Citation citation, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('"${citation.quote ?? ''}"', style: context.labelSmall.copyWith(fontStyle: FontStyle.italic))
            .padded(all: 6)
            .backgroundColor(Colors.white),
        if ((citation.source ?? '').isNotEmpty)
          Link(
            uri: Uri.parse(citation.source!),
            target: LinkTarget.blank,
            builder: (BuildContext context, FollowLink? followLink) => TextButton(
              onPressed: followLink,
              child: Text(citation.source ?? '', style: const TextStyle(color: Colors.blue)),
            ),
          ).aligned(Alignment.centerLeft),
      ],
    ).padded(vertical: 4);
  }
}
