import 'package:flutter/material.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<User> _users = [];
  bool _loading = true;
  bool _creating = false;

  bool _groupMode = false;
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final query = ApplicationUserListQuery();
      final users = await query.next();
      final myId = SendbirdChat.currentUser?.userId;

      if (!mounted) return;
      setState(() {
        _users = users.where((u) => u.userId != myId).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kullanıcılar yüklenemedi: $e')));
    }
  }

  Future<void> _startOneToOneChat(User user) async {
    setState(() => _creating = true);
    try {
      final params = GroupChannelCreateParams()
        ..userIds = _selectedUserIds.toList()
        ..isDistinct = true;

      final channel = await GroupChannel.createChannel(params);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(channelUrl: channel.channelUrl),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sohbet başlatılamadı: $e')));
    }
  }

  // Grup modunda: seçilen tüm kullanıcılarla grup kanalı aç
  Future<void> _createGroupChat() async {
    if (_selectedUserIds.isEmpty) return;

    final groupName = await _askGroupName();
    if (groupName == null) return; // kullanıcı iptal etti

    setState(() => _creating = true);
    try {
      final params = GroupChannelCreateParams()
        ..userIds = _selectedUserIds.toList()
        ..isDistinct =
            false // grup sohbetlerde distinct kullanılmaz, her zaman yeni kanal
        ..name = groupName;

      final channel = await GroupChannel.createChannel(params);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(channelUrl: channel.channelUrl),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Grup oluşturulamadı: $e')));
    }
  }

  Future<String?> _askGroupName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grup Adı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Örn: Proje Ekibi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              Navigator.pop(context, name.isEmpty ? 'Yeni Grup' : name);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
          onPressed: () {
            if (_groupMode) {
              // Grup modundan çık, kişi listesine geri dön
              setState(() {
                _groupMode = false;
                _selectedUserIds.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _groupMode ? '${_selectedUserIds.length} kişi seçildi' : 'Kişi Seçin',
          style: const TextStyle(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_groupMode && _selectedUserIds.isNotEmpty)
            TextButton(
              onPressed: _creating ? null : _createGroupChat,
              child: const Text(
                'Oluştur',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.surfaceContainer, height: 1),
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : Column(
                  children: [
                    // "Yeni Grup" seçeneği - sadece normal modda görünür
                    if (!_groupMode)
                      ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: const Icon(
                            Icons.group_add,
                            color: Colors.white,
                          ),
                        ),
                        title: const Text(
                          'Yeni Grup',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onBackground,
                          ),
                        ),
                        onTap: () => setState(() => _groupMode = true),
                      ),
                    if (!_groupMode)
                      Divider(
                        height: 1,
                        indent: 84,
                        color: AppColors.surfaceContainer,
                      ),

                    Expanded(
                      child: _users.isEmpty
                          ? const Center(
                              child: Text(
                                'Henüz başka kullanıcı yok',
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _users.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 84,
                                color: AppColors.surfaceContainer,
                              ),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final isSelected = _selectedUserIds.contains(
                                  user.userId,
                                );

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.surfaceContainer,
                                    backgroundImage: user.profileUrl.isNotEmpty
                                        ? NetworkImage(user.profileUrl)
                                        : null,
                                    child: user.profileUrl.isEmpty
                                        ? Text(
                                            user.nickname.isNotEmpty
                                                ? user.nickname[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    user.nickname.isNotEmpty
                                        ? user.nickname
                                        : user.userId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  subtitle: Text(
                                    user.userId,
                                    style: const TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  // Grup modundaysa checkbox göster, değilse hiçbir şey
                                  trailing: _groupMode
                                      ? Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.outline,
                                        )
                                      : null,
                                  onTap: _creating
                                      ? null
                                      : () {
                                          if (_groupMode) {
                                            _toggleUserSelection(user.userId);
                                          } else {
                                            _startOneToOneChat(user);
                                          }
                                        },
                                );
                              },
                            ),
                    ),
                  ],
                ),
          if (_creating)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
