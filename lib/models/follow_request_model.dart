import 'user_model.dart';

/// Status žádosti o sledování
enum FollowRequestStatus {
  pending,
  accepted,
  rejected,
}

/// Model pro žádost o sledování
class FollowRequestModel {
  /// ID žádosti
  final String id;

  /// ID uživatele, který žádá o sledování
  final String requesterId;

  /// ID uživatele, kterého chce sledovat
  final String targetId;

  /// Status žádosti
  final FollowRequestStatus status;

  /// Datum vytvoření
  final DateTime createdAt;

  /// Datum aktualizace
  final DateTime? updatedAt;

  /// Profil žadatele (volitelné, pro zobrazení)
  final UserModel? requester;

  /// Profil cíle (volitelné, pro zobrazení)
  final UserModel? target;

  FollowRequestModel({
    required this.id,
    required this.requesterId,
    required this.targetId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.requester,
    this.target,
  });

  /// Vytvoří model z JSON
  factory FollowRequestModel.fromJson(Map<String, dynamic> json) {
    return FollowRequestModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      targetId: json['target_id'] as String,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      requester: json['requester'] != null
          ? UserModel.fromJson(json['requester'] as Map<String, dynamic>)
          : null,
      target: json['target'] != null
          ? UserModel.fromJson(json['target'] as Map<String, dynamic>)
          : null,
    );
  }

  static FollowRequestStatus _parseStatus(String status) {
    switch (status) {
      case 'accepted':
        return FollowRequestStatus.accepted;
      case 'rejected':
        return FollowRequestStatus.rejected;
      default:
        return FollowRequestStatus.pending;
    }
  }

  /// Je žádost čekající?
  bool get isPending => status == FollowRequestStatus.pending;

  /// Byla žádost přijata?
  bool get isAccepted => status == FollowRequestStatus.accepted;

  /// Byla žádost odmítnuta?
  bool get isRejected => status == FollowRequestStatus.rejected;
}
