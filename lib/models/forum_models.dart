class ForumPost {
  final int id;
  final String content;
  final int? parentId;
  final String username;
  final DateTime createdAt;
  final String avatarUrl;

  ForumPost({
    required this.id,
    required this.content,
    this.parentId,
    required this.username,
    required this.createdAt,
    this.avatarUrl = '',
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
    id: json['id'] as int,
    content: json['content'] as String,
    parentId: json['parentId'] as int?,
    username: json['username'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    avatarUrl: _extractAvatar(json),
  );

  bool get isReply => parentId != null;

  ForumPost copyWith({
    int? id,
    String? content,
    int? parentId,
    String? username,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return ForumPost(
      id: id ?? this.id,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      username: username ?? this.username,
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

  CreatePostRequest({required this.content, this.parentId});

  Map<String, dynamic> toJson() {
    // Backend espera parent_id en snake_case
    // null = publicación nueva, número = respuesta
    return {
      'content': content,
      'parent_id': parentId, // null para post nuevo, ID para respuesta
    };
  }
}
