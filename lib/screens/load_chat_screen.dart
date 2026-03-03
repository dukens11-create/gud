import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/load.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/notification_service.dart';

/// Real-time chat screen for a specific load.
///
/// Accessible by both the admin and the load's assigned driver.
/// [senderRole] must be `'admin'` or `'driver'` so that each message is
/// labelled with the correct role in the UI and in Firestore.
class LoadChatScreen extends StatefulWidget {
  final LoadModel load;
  final String senderRole; // 'admin' or 'driver'

  const LoadChatScreen({
    super.key,
    required this.load,
    required this.senderRole,
  });

  @override
  State<LoadChatScreen> createState() => _LoadChatScreenState();
}

class _LoadChatScreenState extends State<LoadChatScreen> {
  final _messageService = MessageService();
  final _notificationService = NotificationService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  int _previousMessageCount = 0;
  bool _hasReceivedFirstSnapshot = false;

  String get _currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // Clear unread counter for current user's role when chat is opened.
    _messageService.resetUnreadCount(
      loadId: widget.load.id,
      role: widget.senderRole,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _messageService.sendMessage(
        loadId: widget.load.id,
        text: text,
        senderRole: widget.senderRole,
      );
      _textController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Called every time the message stream emits a new list.
  ///
  /// Plays a notification sound when a message from the other party arrives
  /// and resets the unread counter so the badge on the calling screen clears.
  void _onMessagesUpdated(List<MessageModel> messages) {
    final previousCount = _previousMessageCount;
    final isNewMessage =
        _hasReceivedFirstSnapshot && messages.length > previousCount;

    _previousMessageCount = messages.length;
    _hasReceivedFirstSnapshot = true;

    if (isNewMessage) {
      // New messages arrived – check if any are from the other party.
      final incoming = messages.sublist(previousCount);
      final hasIncoming = incoming.any((m) => m.senderId != _currentUserId);
      if (hasIncoming) {
        final load = widget.load;
        final senderLabel =
            widget.senderRole == 'admin' ? 'Driver' : 'Admin';
        _notificationService.showChatMessageNotification(
          title: 'New message - ${load.loadNumber.isNotEmpty ? load.loadNumber : "Load"}',
          body: '$senderLabel sent you a message',
          loadId: load.id,
        );
        // Reset counter again in case messages came in while screen is open.
        _messageService.resetUnreadCount(
          loadId: load.id,
          role: widget.senderRole,
        );
      }
    }

    // Scroll to the latest message.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final load = widget.load;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat – ${load.loadNumber.isNotEmpty ? load.loadNumber : "Load"}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${load.pickupAddress} → ${load.deliveryAddress}',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messageService.streamMessages(load.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                // Always track the snapshot count so that the first message
                // to arrive (even into a previously empty chat) triggers sound.
                if (!_hasReceivedFirstSnapshot ||
                    messages.length != _previousMessageCount) {
                  // Defer side-effects (sound, reset) to after the build phase.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _onMessagesUpdated(messages),
                  );
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSend the first message!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _currentUserId;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              tooltip: 'Send',
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a');
    final label = message.senderRole == 'admin' ? 'Admin' : 'Driver';
    final bubbleColor =
        isMe ? Theme.of(context).primaryColor : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : Colors.black87;
    final labelColor = isMe ? Colors.white70 : Colors.grey.shade600;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
            Text(
              message.text,
              style: TextStyle(fontSize: 15, color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              timeFormat.format(message.createdAt),
              style: TextStyle(fontSize: 10, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
