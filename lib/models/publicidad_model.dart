import 'dart:convert';

class Publicidad {
  final int? id;
  final int? casinoId;
  final String mediaUrl;
  final String mediaType; // IMAGE | VIDEO
  final String? description;

  const Publicidad({
    this.id,
    this.casinoId,
    required this.mediaUrl,
    required this.mediaType,
    this.description,
  });

  bool get isVideo => mediaType.toUpperCase() == 'VIDEO';

  factory Publicidad.fromJson(Map<String, dynamic> json) {
    // Keys may vary; align with provided payload (casinoGralId, startAt, endAt, mediaUrl, text).
    final mediaUrl =
        (json['mediaUrl'] ??
                json['mediaurl'] ??
                json['url'] ??
                json['archivoUrl'] ??
                json['archivo'] ??
                '')
            .toString();

    // Derive type if not provided: check extension for simple image/video hint.
    String typeRaw = (json['mediaType'] ?? json['tipo'] ?? json['type'] ?? '')
        .toString()
        .toUpperCase();
    if (typeRaw.isEmpty) {
      final lower = mediaUrl.toLowerCase();
      if (lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.m3u8')) {
        typeRaw = 'VIDEO';
      } else {
        typeRaw = 'IMAGE';
      }
    }

    return Publicidad(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id'] ?? ''}'),
      casinoId: json['casinoId'] is int
          ? json['casinoId'] as int
          : int.tryParse(
              '${json['casinoId'] ?? json['casino_id'] ?? json['casinoGralId'] ?? json['casino_gral_id'] ?? json['casino_gral'] ?? ''}',
            ),
      mediaUrl: mediaUrl,
      mediaType: typeRaw,
      description:
          (json['text'] ??
                  json['descripcion'] ??
                  json['description'] ??
                  json['texto'] ??
                  json['detalle'])
              ?.toString(),
    );
  }

  static List<Publicidad> listFromJson(dynamic body) {
    if (body == null) return const [];
    List<dynamic>? items;

    if (body is List) {
      items = body;
    } else if (body is Map) {
      // Handle wrapped responses: { data: [...] } or { content: [...] }
      final map = Map<String, dynamic>.from(body as Map);
      if (map['data'] is List) items = map['data'] as List;
      if (map['content'] is List) items = map['content'] as List;
    } else if (body is String && body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded as Map);
          if (map['data'] is List) items = map['data'] as List;
          if (map['content'] is List) items = map['content'] as List;
        }
      } catch (_) {}
    }

    if (items == null) return const [];
    return items
        .whereType<Map>()
        .map((e) => Publicidad.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
