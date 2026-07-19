import 'package:flutter/material.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import '../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String channelUrl;
  const ChatScreen({super.key, required this.channelUrl});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    implements MessageCollectionHandler {
  GroupChannel? _channel;
  MessageCollection? _collection;
  List<BaseMessage> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _myUserId = SendbirdChat.currentUser?.userId;
    _setup();
  }

  Future<void> _setup() async {
    try {
      final channel = await GroupChannel.getChannel(widget.channelUrl);

      final collection = MessageCollection(
        channel: channel,
        params: MessageListParams(),
        handler: this,
        startingPoint: DateTime.now().millisecondsSinceEpoch,
      );

      await collection.initialize();

      if (!mounted) return;
      setState(() {
        _channel = channel;
        _collection = collection;
        _messages = collection.messageList.reversed.toList();
        _loading = false;
      });

      channel.markAsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kanal yüklenemedi: $e')));
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _channel == null) return;
    _controller.clear();

    final params = UserMessageCreateParams(message: text);
    _channel!.sendUserMessage(
      params,
      handler: (message, error) {
        if (error != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mesaj gönderilemedi: $error')),
          );
        }
      },
    );
  }

  // ---- MessageCollectionHandler metodları ----

  @override
  void onMessagesAdded(
    MessageContext context,
    GroupChannel channel,
    List<BaseMessage> messages,
  ) {
    if (!mounted) return;
    setState(() {
      _messages.insertAll(0, messages.reversed);
    });
  }

  @override
  void onMessagesUpdated(
    MessageContext context,
    GroupChannel channel,
    List<BaseMessage> messages,
  ) {
    if (!mounted) return;
    setState(() {
      for (final m in messages) {
        final i = _messages.indexWhere((e) => e.messageId == m.messageId);
        if (i >= 0) _messages[i] = m;
      }
    });
  }

  @override
  void onMessagesDeleted(
    MessageContext context,
    GroupChannel channel,
    List<BaseMessage> messages,
  ) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere(
        (m) => messages.any((d) => d.messageId == m.messageId),
      );
    });
  }

  @override
  void onChannelUpdated(GroupChannelContext context, GroupChannel channel) {}

  @override
  void onChannelDeleted(
    GroupChannelContext context,
    String deletedChannelUrl,
  ) {}

  @override
  void onHugeGapDetected() {}

  // ---- UI ----

  @override
  void dispose() {
    _collection?.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceContainer,
              backgroundImage: (_channel?.coverUrl.isNotEmpty ?? false)
                  ? NetworkImage(_channel!.coverUrl)
                  : null,
              child: (_channel?.coverUrl.isEmpty ?? true)
                  ? Text(
                      _channel != null && _channel!.name.isNotEmpty
                          ? _channel!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _channel?.name.isNotEmpty == true ? _channel!.name : 'Sohbet',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBackground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.surfaceContainer, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz mesaj yok, ilk mesajı sen gönder 👋',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      if (msg is UserMessage) {
                        final isMine = msg.sender?.userId == _myUserId;
                        return _buildBubble(
                          text: msg.message,
                          time: _formatTime(msg.createdAt),
                          isMine: isMine,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble({
    required String text,
    required String time,
    required bool isMine,
  }) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.bubbleOut : AppColors.bubbleIn,
          borderRadius: BorderRadius.circular(16),
          border: isMine
              ? null
              : Border.all(color: AppColors.bubbleBorder.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.onBackground,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceContainer)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yazın...',
                    hintStyle: TextStyle(color: AppColors.outline),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
