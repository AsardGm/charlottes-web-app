import 'package:supabase_flutter/supabase_flutter.dart';

/// Typ nahlaseneho obsahu
enum ReportContentType {
  post,
  comment,
  user,
  message,
}

/// Duvod nahlaseni
enum ReportReason {
  spam,
  harassment,
  hateSpeech,
  violence,
  nudity,
  falseInformation,
  scam,
  selfHarm,
  other,
}

/// Stav nahlaseni
enum ReportStatus {
  pending,
  reviewing,
  resolved,
  dismissed,
}

/// Extension pro konverzi enum na DB hodnoty
extension ReportContentTypeExt on ReportContentType {
  String get dbValue {
    switch (this) {
      case ReportContentType.post:
        return 'post';
      case ReportContentType.comment:
        return 'comment';
      case ReportContentType.user:
        return 'user';
      case ReportContentType.message:
        return 'message';
    }
  }

  static ReportContentType fromDb(String value) {
    switch (value) {
      case 'post':
        return ReportContentType.post;
      case 'comment':
        return ReportContentType.comment;
      case 'user':
        return ReportContentType.user;
      case 'message':
        return ReportContentType.message;
      default:
        return ReportContentType.post;
    }
  }
}

extension ReportReasonExt on ReportReason {
  String get dbValue {
    switch (this) {
      case ReportReason.spam:
        return 'spam';
      case ReportReason.harassment:
        return 'harassment';
      case ReportReason.hateSpeech:
        return 'hate_speech';
      case ReportReason.violence:
        return 'violence';
      case ReportReason.nudity:
        return 'nudity';
      case ReportReason.falseInformation:
        return 'false_information';
      case ReportReason.scam:
        return 'scam';
      case ReportReason.selfHarm:
        return 'self_harm';
      case ReportReason.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Obtezovani';
      case ReportReason.hateSpeech:
        return 'Nenavistny projev';
      case ReportReason.violence:
        return 'Nasili';
      case ReportReason.nudity:
        return 'Nahota';
      case ReportReason.falseInformation:
        return 'Dezinformace';
      case ReportReason.scam:
        return 'Podvod';
      case ReportReason.selfHarm:
        return 'Sebeposkozo­vani';
      case ReportReason.other:
        return 'Jine';
    }
  }

  static ReportReason fromDb(String value) {
    switch (value) {
      case 'spam':
        return ReportReason.spam;
      case 'harassment':
        return ReportReason.harassment;
      case 'hate_speech':
        return ReportReason.hateSpeech;
      case 'violence':
        return ReportReason.violence;
      case 'nudity':
        return ReportReason.nudity;
      case 'false_information':
        return ReportReason.falseInformation;
      case 'scam':
        return ReportReason.scam;
      case 'self_harm':
        return ReportReason.selfHarm;
      case 'other':
      default:
        return ReportReason.other;
    }
  }
}

extension ReportStatusExt on ReportStatus {
  String get dbValue {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewing:
        return 'reviewing';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.dismissed:
        return 'dismissed';
    }
  }

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Ceka na zpracovani';
      case ReportStatus.reviewing:
        return 'Probiha kontrola';
      case ReportStatus.resolved:
        return 'Vyreseno';
      case ReportStatus.dismissed:
        return 'Zamitnuto';
    }
  }

  static ReportStatus fromDb(String value) {
    switch (value) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewing':
        return ReportStatus.reviewing;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }
}

/// Model nahlaseni
class ReportModel {
  final String id;
  final String reporterId;
  final ReportContentType contentType;
  final String contentId;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNote;
  final String? actionTaken;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.contentType,
    required this.contentId,
    required this.reason,
    this.description,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNote,
    this.actionTaken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      contentType: ReportContentTypeExt.fromDb(json['content_type'] as String),
      contentId: json['content_id'] as String,
      reason: ReportReasonExt.fromDb(json['reason'] as String),
      description: json['description'] as String?,
      status: ReportStatusExt.fromDb(json['status'] as String),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      adminNote: json['admin_note'] as String?,
      actionTaken: json['action_taken'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Sluzba pro spravu nahlaseni
class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Vytvori nove nahlaseni
  Future<void> createReport({
    required ReportContentType contentType,
    required String contentId,
    required ReportReason reason,
    String? description,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Uzivatel neni prihlasen');
    }

    await _supabase.from('reports').insert({
      'reporter_id': _currentUserId,
      'content_type': contentType.dbValue,
      'content_id': contentId,
      'reason': reason.dbValue,
      'description': description,
    });
  }

  /// Nahlasi prispevek
  Future<void> reportPost({
    required String postId,
    required ReportReason reason,
    String? description,
  }) async {
    await createReport(
      contentType: ReportContentType.post,
      contentId: postId,
      reason: reason,
      description: description,
    );
  }

  /// Nahlasi komentar
  Future<void> reportComment({
    required String commentId,
    required ReportReason reason,
    String? description,
  }) async {
    await createReport(
      contentType: ReportContentType.comment,
      contentId: commentId,
      reason: reason,
      description: description,
    );
  }

  /// Nahlasi uzivatele
  Future<void> reportUser({
    required String oderId,
    required ReportReason reason,
    String? description,
  }) async {
    await createReport(
      contentType: ReportContentType.user,
      contentId: oderId,
      reason: reason,
      description: description,
    );
  }

  /// Nahlasi zpravu
  Future<void> reportMessage({
    required String messageId,
    required ReportReason reason,
    String? description,
  }) async {
    await createReport(
      contentType: ReportContentType.message,
      contentId: messageId,
      reason: reason,
      description: description,
    );
  }

  /// Zkontroluje, zda uzivatel uz nahlasil dany obsah
  Future<bool> hasReported({
    required ReportContentType contentType,
    required String contentId,
  }) async {
    if (_currentUserId == null) return false;

    final response = await _supabase
        .from('reports')
        .select('id')
        .eq('reporter_id', _currentUserId!)
        .eq('content_type', contentType.dbValue)
        .eq('content_id', contentId)
        .maybeSingle();

    return response != null;
  }

  /// Ziska nahlaseni aktualniho uzivatele
  Future<List<ReportModel>> getMyReports() async {
    if (_currentUserId == null) return [];

    final response = await _supabase
        .from('reports')
        .select()
        .eq('reporter_id', _currentUserId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReportModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================
  // ADMIN FUNKCE
  // ============================================

  /// Ziska vsechna nahlaseni (pouze admin)
  Future<List<ReportModel>> getAllReports({
    ReportStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase.from('reports').select();

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ReportModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Ziska pocet nevyrizenych nahlaseni
  Future<int> getPendingReportsCount() async {
    final response = await _supabase.rpc('get_pending_reports_count');
    return response as int? ?? 0;
  }

  /// Aktualizuje stav nahlaseni (pouze admin)
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminNote,
    String? actionTaken,
  }) async {
    await _supabase.from('reports').update({
      'status': status.dbValue,
      'reviewed_by': _currentUserId,
      'reviewed_at': DateTime.now().toIso8601String(),
      if (adminNote != null) 'admin_note': adminNote,
      if (actionTaken != null) 'action_taken': actionTaken,
    }).eq('id', reportId);
  }

  /// Oznaci nahlaseni jako vyresene
  Future<void> resolveReport({
    required String reportId,
    String? adminNote,
    String? actionTaken,
  }) async {
    await updateReportStatus(
      reportId: reportId,
      status: ReportStatus.resolved,
      adminNote: adminNote,
      actionTaken: actionTaken,
    );
  }

  /// Zamitne nahlaseni
  Future<void> dismissReport({
    required String reportId,
    String? adminNote,
  }) async {
    await updateReportStatus(
      reportId: reportId,
      status: ReportStatus.dismissed,
      adminNote: adminNote,
    );
  }
}
