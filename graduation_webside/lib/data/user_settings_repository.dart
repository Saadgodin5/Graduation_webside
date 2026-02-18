import 'package:supabase_flutter/supabase_flutter.dart';

class UserSettingsRepository {
  UserSettingsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, String>> fetchSettings({
    required String userId,
    required List<String> keys,
  }) async {
    if (keys.isEmpty) return {};

    final rows = await _client
        .from('user_settings')
        .select('key,value')
        .eq('user_id', userId)
        .inFilter('key', keys);

    final list = (rows as List).cast<Map<String, dynamic>>();
    final out = <String, String>{};
    for (final row in list) {
      final k = row['key'];
      if (k is! String) continue;
      final v = row['value'];
      out[k] = v == null ? '' : v.toString();
    }
    return out;
  }

  Future<void> setSetting({
    required String userId,
    required String key,
    required String value,
  }) async {
    await _client.from('user_settings').upsert(
      {
        'user_id': userId,
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,key',
    );
  }
}

bool parseBoolSetting(String? value, {required bool defaultValue}) {
  if (value == null) return defaultValue;
  final v = value.trim().toLowerCase();
  if (v == 'true' || v == '1' || v == 'yes' || v == 'on') return true;
  if (v == 'false' || v == '0' || v == 'no' || v == 'off') return false;
  return defaultValue;
}

