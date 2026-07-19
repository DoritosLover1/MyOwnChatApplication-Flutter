import 'package:flutter/material.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen>
    implements GroupChannelCollectionHandler {
  late GroupChannelCollection _collection;
  List<GroupChannel> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final query = GroupChannelListQuery()
      ..includeEmpty = true
      ..order = GroupChannelListQueryOrder.latestLastMessage;

    _collection = GroupChannelCollection(query: query, handler: this);

    _loadChannels();
  }

  Future<void> _loadChannels() async {
    try {
      if (_collection.hasMore) {
        await _collection.loadMore();
      }

      if (!mounted) return;
      setState(() {
        _channels = _collection.channelList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.wifi_off_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Konuşmalar yüklenemedi. Bağlantınızı kontrol edin.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          elevation: 8,
        ),
      );
    }
  }

  @override
  void onChannelsAdded(
    GroupChannelContext context,
    List<GroupChannel> channels,
  ) => _refreshFromCollection();

  @override
  void onChannelsUpdated(
    GroupChannelContext context,
    List<GroupChannel> channels,
  ) => _refreshFromCollection();

  @override
  void onChannelsDeleted(
    GroupChannelContext context,
    List<String> deletedChannelUrls,
  ) => _refreshFromCollection();

  void _refreshFromCollection() {
    if (!mounted) return;
    setState(() {
      _channels = _collection.channelList;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await SendbirdChat.disconnect();
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _collection.dispose();
    super.dispose();
  }

  String _formatTime(int? timestampMs) {
    if (timestampMs == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h.$m';
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.chat_bubble, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              'Mesajlar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.surfaceContainer, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _channels.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadChannels,
              color: AppColors.primary,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _channels.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 84,
                  color: AppColors.surfaceContainer,
                ),
                itemBuilder: (context, index) =>
                    _buildChannelTile(_channels[index]),
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.vividGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactsScreen()),
            ).then((_) => _loadChannels());
          },
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: AppColors.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz hiç sohbetin yok',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sağ alttaki butona basarak yeni sohbet başlat',
            style: TextStyle(color: AppColors.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _getChannelDisplayName(GroupChannel channel) {
    if (channel.name.isNotEmpty && channel.name != 'Group Channel') {
      return channel.name;
    }
    
    final currentUser = SendbirdChat.currentUser;
    if (currentUser != null) {
      final otherMembers = channel.members.where((m) => m.userId != currentUser.userId).toList();
      if (otherMembers.isNotEmpty) {
        return otherMembers.map((m) => m.nickname.isNotEmpty ? m.nickname : m.userId).join(', ');
      }
    }
    
    return 'Sohbet';
  }

  String _getChannelCoverUrl(GroupChannel channel) {
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

  Widget _buildChannelTile(GroupChannel channel) {
    final unreadCount = channel.unreadMessageCount;
    final lastMessage = channel.lastMessage;
    String subtitle = 'Henüz mesaj yok';
    if (lastMessage is UserMessage) {
      subtitle = lastMessage.message;
    } else if (lastMessage is FileMessage) {
      subtitle = '📎 Dosya';
    }

    final displayName = _getChannelDisplayName(channel);
    final coverUrl = _getChannelCoverUrl(channel);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(channelUrl: channel.channelUrl),
          ),
        ).then((_) => _loadChannels());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.surfaceContainer,
              backgroundImage: coverUrl.isNotEmpty
                  ? NetworkImage(coverUrl)
                  : null,
              child: coverUrl.isEmpty
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: unreadCount > 0
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.onBackground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? AppColors.onBackground
                          : AppColors.onSurfaceVariant,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.w400,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(lastMessage?.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: unreadCount > 0
                        ? AppColors.primary
                        : AppColors.outline,
                    fontWeight: unreadCount > 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.unreadBadge,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
