class ForumPost {
  final int id;
  final String content;
  final int? parentId;
  final String username;
  final int? casinoGralId;
  final DateTime createdAt;
  final String avatarUrl;

  ForumPost({
    required this.id,
    required this.content,
    this.parentId,
    required this.username,
    this.casinoGralId,
    required this.createdAt,
    this.avatarUrl = '',
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
    id: json['id'] as int,
    content: json['content'] as String,
    parentId: json['parentId'] as int?,
    username: json['username'] as String,
    casinoGralId: (json['casinoGralId'] is int)
        ? (json['casinoGralId'] as int)
        : int.tryParse('${json['casinoGralId'] ?? ''}'),
    createdAt: _parseBackendCreatedAt(
      json['createdAt'] ?? json['created_at'] ?? json['timestamp'],
    ),
    avatarUrl: _extractAvatar(json),
  );

  bool get isReply => parentId != null;

  ForumPost copyWith({
    int? id,
    String? content,
    int? parentId,
    String? username,
    int? casinoGralId,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return ForumPost(
      id: id ?? this.id,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      username: username ?? this.username,
      casinoGralId: casinoGralId ?? this.casinoGralId,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  static String _extractAvatar(Map<String, dynamic> json) {
    final direct =
        json['userIconUrl'] ??
        json['avatarUrl'] ??
        json['iconUrl'] ??
        json['avatar'] ??
        json['icon'];
    if (direct is String && direct.isNotEmpty) return direct;

    final user =
        json['user'] ?? json['author'] ?? json['usuario'] ?? json['owner'];
    if (user is Map<String, dynamic>) {
      final nested =
          user['userIconUrl'] ??
          user['avatarUrl'] ??
          user['iconUrl'] ??
          user['avatar'] ??
          user['icon'];
      if (nested is String && nested.isNotEmpty) return nested;
    }
    return '';
  }

  static DateTime _parseBackendCreatedAt(dynamic rawValue) {
    final createdAtFromBackend = (rawValue ?? '').toString().trim();
    if (createdAtFromBackend.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final fecha = DateTime.parse(createdAtFromBackend);
    final fechaLocal = fecha.toLocal();
    return fechaLocal;
  }
}

class PageableResponse<T> {
  final int totalPages;
  final int totalElements;
  final int size;
  final List<T> content;
  final int number;
  final bool first;
  final bool last;
  final bool empty;

  PageableResponse({
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.content,
    required this.number,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PageableResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageableResponse(
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
      size: json['size'] as int,
      content: (json['content'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      number: json['number'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
      empty: json['empty'] as bool,
    );
  }
}

class CreatePostRequest {
  final String content;
  final int? parentId;
  final int? casinoGralId;

  CreatePostRequest({required this.content, this.parentId, this.casinoGralId});

  Map<String, dynamic> toJson() {
    // Contrato backend:
    // - Publicación nueva: parent_id = null
    // - Respuesta: parent_id = ID (>= 0)
    return {
      'content': content,
      'parent_id': parentId,
      // Para foro BoomBet: casino_gral_id = null.
      'casino_gral_id': casinoGralId,
    };
  }
}
