import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _wordCount = ChatProvider.wordCount(_messageController.text);
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final user = auth.user;
    if (user == null) return;

    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    final success = await chat.sendMessage(
      userId: user.id,
      userName: user.name,
      userPhotoUrl: user.photoUrl,
      text: text,
    );

    if (!mounted) return;

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else if (chat.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chat.error!),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      chat.clearError();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
      ),
      body: Column(
        children: [
          _ChatInfoBanner(),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                if (chat.messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        '¡Sé el primero en saludar a la comunidad! 👋\n'
                        'Comparte qué estás leyendo o anima a otros lectores.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppConstants.textSecondaryColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    final max = _scrollController.position.maxScrollExtent;
                    final current = _scrollController.offset;
                    if (max - current < 120) {
                      _scrollToBottom();
                    }
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: chat.messages.length,
                  itemBuilder: (context, index) {
                    final message = chat.messages[index];
                    final isMine =
                        message.userId == context.read<AuthProvider>().user?.id;
                    return _ChatBubble(
                      message: message,
                      isMine: isMine,
                    );
                  },
                );
              },
            ),
          ),
          _MessageInputBar(
            controller: _messageController,
            wordCount: _wordCount,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _ChatInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppConstants.secondaryColor.withOpacity( 0.6),
      child: Text(
        'Chat global · Máx. ${AppConstants.chatMaxWordsPerMessage} palabras · '
        '1 mensaje cada ${AppConstants.chatCooldownSeconds ~/ 60} min · '
        'Se borra cada ${AppConstants.chatRetentionHours} h',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.textSecondaryColor,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _ChatBubble({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppConstants.primaryColor,
              backgroundImage: message.userPhotoUrl != null
                  ? NetworkImage(message.userPhotoUrl!)
                  : null,
              child: message.userPhotoUrl == null
                  ? Text(
                      message.userName.isNotEmpty
                          ? message.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.userName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppConstants.primaryColor
                        : AppConstants.whiteColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity( 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: AppConstants.textPrimaryColor,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppConstants.textSecondaryColor
                              .withOpacity( 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final int wordCount;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.wordCount,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final overLimit = wordCount > AppConstants.chatMaxWordsPerMessage;
    final canSend = chat.canSend && !overLimit && wordCount > 0;
    final cooldown = chat.cooldownSecondsRemaining ?? 0;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity( 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$wordCount / ${AppConstants.chatMaxWordsPerMessage} palabras',
                style: TextStyle(
                  fontSize: 12,
                  color: overLimit
                      ? AppConstants.errorColor
                      : AppConstants.textSecondaryColor,
                  fontWeight: overLimit ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (cooldown > 0)
                Text(
                  'Espera ${cooldown}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escribe al chat global...',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: canSend ? (_) => onSend() : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend ? onSend : null,
                icon: chat.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppConstants.textPrimaryColor,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  disabledBackgroundColor:
                      AppConstants.secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
