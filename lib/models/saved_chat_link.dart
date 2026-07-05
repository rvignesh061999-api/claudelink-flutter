import 'package:uuid/uuid.dart';

class SavedChatLink {
  final String id;
  String accountId;
  String alias;
  String url;

  SavedChatLink({
    String? id,
    required this.accountId,
    required this.alias,
    required this.url,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'alias': alias,
    'url': url,
  };

  factory SavedChatLink.fromJson(Map<String, dynamic> j) => SavedChatLink(
    id: j['id'] as String?,
    accountId: j['accountId'] as String? ?? '',
    alias: j['alias'] as String? ?? '',
    url: j['url'] as String? ?? '',
  );
}
