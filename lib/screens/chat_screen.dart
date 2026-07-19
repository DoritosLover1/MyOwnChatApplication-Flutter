import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

  Future<void> _pickAndSendFile() async {
    if (_channel == null) return;
    try {
      final result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final params = FileMessageCreateParams.withFile(
          file,
          fileName: result.files.single.name,
        );

        _channel!.sendFileMessage(
          params,
          handler: (message, error) {
            if (error != null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dosya gönderilemedi: ${error.message}'),
                  ),
                );
              }
            }
          },
        );
      }
    } catch (e) {
      debugPrint('Dosya seçme hatası: $e');
    }
  }

  String _getChannelDisplayName(GroupChannel? channel) {
    if (channel == null) return 'Sohbet';
    if (channel.name.isNotEmpty && channel.name != 'Group Channel') {
      return channel.name;
    }

    final currentUser = SendbirdChat.currentUser;
    if (currentUser != null) {
      final otherMembers = channel.members
          .where((m) => m.userId != currentUser.userId)
          .toList();
      if (otherMembers.isNotEmpty) {
        return otherMembers
            .map((m) => m.nickname.isNotEmpty ? m.nickname : m.userId)
            .join(', ');
      }
    }
    return 'Sohbet';
  }

  String _getChannelCoverUrl(GroupChannel? channel) {
    if (channel == null) return '';
    if (channel.coverUrl.isNotEmpty) {
      return channel.coverUrl;
    }

    final currentUser = SendbirdChat.currentUser;
    if (currentUser != null && channel.members.length == 2) {
      final otherMember = channel.members.firstWhere(
        (m) => m.userId != currentUser.userId,
        orElse: () => channel.members.first,
      );
      return otherMember.profileUrl;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _getChannelDisplayName(_channel);
    final coverUrl = _getChannelCoverUrl(_channel);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.25),
              backgroundImage: coverUrl.isNotEmpty
                  ? NetworkImage(coverUrl)
                  : null,
              child: coverUrl.isEmpty
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _messages.isEmpty
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
                      final isMine = msg.sender?.userId == _myUserId;
                      if (msg is UserMessage) {
                        return _buildBubble(
                          text: msg.message,
                          time: _formatTime(msg.createdAt),
                          isMine: isMine,
                        );
                      } else if (msg is FileMessage) {
                        return _buildFileBubble(
                          fileMessage: msg,
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
          gradient: isMine ? AppColors.bubbleOutGradient : null,
          color: isMine ? null : AppColors.bubbleIn,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine
              ? null
              : Border.all(color: AppColors.bubbleBorder.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: isMine
                  ? AppColors.primary.withOpacity(0.18)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isMine ? 8 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isMine ? Colors.white : AppColors.onBackground,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: isMine
                    ? Colors.white.withOpacity(0.75)
                    : AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileBubble({
    required FileMessage fileMessage,
    required String time,
    required bool isMine,
  }) {
    final isImage = (fileMessage.type ?? '').toLowerCase().startsWith('image/');

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMine ? AppColors.bubbleOutGradient : null,
          color: isMine ? null : AppColors.bubbleIn,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine
              ? null
              : Border.all(color: AppColors.bubbleBorder.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: isMine
                  ? AppColors.primary.withOpacity(0.18)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isMine ? 8 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  fileMessage.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    color: isMine ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      fileMessage.name ?? 'Dosya',
                      style: TextStyle(
                        fontSize: 15,
                        color: isMine ? Colors.white : AppColors.onBackground,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: isMine
                    ? Colors.white.withOpacity(0.75)
                    : AppColors.outline,
              ),
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
            IconButton(
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary,
              ),
              onPressed: _pickAndSendFile,
            ),
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
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.vividGradient,
                shape: BoxShape.circle,
              ),
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
