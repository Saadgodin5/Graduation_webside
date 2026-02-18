import 'package:supabase_flutter/supabase_flutter.dart';

enum ChatRole { user, bot }

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final ChatRole role;
  final String content;
  final DateTime? createdAt;

  factory ChatMessage.fromRow(Map<String, dynamic> row) {
    final roleRaw = (row['role'] as String?)?.toLowerCase().trim();
    final role = roleRaw == 'bot' ? ChatRole.bot : ChatRole.user;

    final createdAtRaw = row['created_at'];
    DateTime? createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    }

    return ChatMessage(
      role: role,
      content: (row['content'] as String?)?.trim() ?? '',
      createdAt: createdAt,
    );
  }
}

class ChatRepository {
  ChatRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ChatMessage>> fetchRecentMessages({
    required String userId,
    int limit = 30,
  }) async {
    final rows = await _client
        .from('chat_messages')
        .select('role,content,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(limit);

    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.map(ChatMessage.fromRow).toList(growable: false);
  }

  Future<void> addMessage({
    required String userId,
    required ChatRole role,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    await _client.from('chat_messages').insert({
      'user_id': userId,
      'role': role == ChatRole.bot ? 'bot' : 'user',
      'content': trimmed,
    });
  }
}

