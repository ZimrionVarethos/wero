/// Role of the message sender in the disaster assistant chat.
enum ChatRole { user, assistant, system }

/// Action chip/button attached to assistant responses.
class ChatAction {
  const ChatAction({
    required this.label,
    this.route,
    this.routeExtra,
    this.phoneNumber,
    this.iconName,
  });

  final String label;
  final String? route;
  final dynamic routeExtra;
  final String? phoneNumber;
  final String? iconName;

  Map<String, dynamic> toJson() => {
    'label': label,
    if (route != null) 'route': route,
    if (routeExtra != null) 'routeExtra': routeExtra,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (iconName != null) 'iconName': iconName,
  };

  factory ChatAction.fromJson(Map<String, dynamic> json) => ChatAction(
    label: json['label'] as String,
    route: json['route'] as String?,
    routeExtra: json['routeExtra'],
    phoneNumber: json['phoneNumber'] as String?,
    iconName: json['iconName'] as String?,
  );
}

/// Message model for the AI disaster assistant conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isOfflineFallback = false,
    this.relatedGuideId,
    this.suggestedActions = const [],
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final bool isOfflineFallback;
  final String? relatedGuideId;
  final List<ChatAction> suggestedActions;

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isOfflineFallback': isOfflineFallback,
    if (relatedGuideId != null) 'relatedGuideId': relatedGuideId,
    'suggestedActions': suggestedActions.map((a) => a.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: ChatRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => ChatRole.assistant,
    ),
    text: json['text'] as String,
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    isOfflineFallback: json['isOfflineFallback'] as bool? ?? false,
    relatedGuideId: json['relatedGuideId'] as String?,
    suggestedActions: (json['suggestedActions'] as List<dynamic>? ?? [])
        .map((a) => ChatAction.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}
