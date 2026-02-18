import 'package:supabase_flutter/supabase_flutter.dart';

class WorkflowRun {
  WorkflowRun({
    required this.intent,
    required this.status,
    required this.executedAt,
  });

  final String intent;
  final String status;
  final DateTime? executedAt;

  factory WorkflowRun.fromRow(Map<String, dynamic> row) {
    final executedAtRaw = row['executed_at'];
    DateTime? executedAt;
    if (executedAtRaw is String) {
      executedAt = DateTime.tryParse(executedAtRaw);
    } else if (executedAtRaw is DateTime) {
      executedAt = executedAtRaw;
    }

    return WorkflowRun(
      intent: (row['intent'] as String?)?.trim().isNotEmpty == true
          ? (row['intent'] as String).trim()
          : 'Untitled',
      status: (row['status'] as String?)?.trim().isNotEmpty == true
          ? (row['status'] as String).trim()
          : 'pending',
      executedAt: executedAt,
    );
  }
}

class WorkflowRepository {
  WorkflowRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<WorkflowRun>> fetchRecentRuns({
    required String userId,
    int limit = 12,
  }) async {
    final rows = await _client
        .from('workflow_runs')
        .select('intent,status,executed_at')
        .eq('user_id', userId)
        .order('executed_at', ascending: false)
        .limit(limit);

    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.map(WorkflowRun.fromRow).toList(growable: false);
  }

  Future<void> insertRun({
    required String userId,
    required String intent,
    required String status,
  }) async {
    await _client.from('workflow_runs').insert({
      'user_id': userId,
      'intent': intent,
      'status': status,
    });
  }
}

String formatExecutedLabel(DateTime? dt) {
  if (dt == null) return '—';

  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final day = DateTime(local.year, local.month, local.day);

  String dayLabel;
  if (day == today) {
    dayLabel = 'Today';
  } else if (day == yesterday) {
    dayLabel = 'Yesterday';
  } else {
    dayLabel =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$dayLabel • $hh:$mm';
}

