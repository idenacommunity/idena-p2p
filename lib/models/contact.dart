import 'package:idena_p2p/models/idena_account.dart';

/// Contact model representing an Idena user in the contact list
class Contact {
  /// Idena address (0x...)
  final String address;

  /// Optional nickname for the contact
  final String? nickname;

  /// Identity state (Human, Verified, Newbie, etc.)
  final String state;

  /// Identity age in epochs
  final int age;

  /// Stake amount
  final double stake;

  /// Whether the contact is a verified human
  final bool isVerifiedHuman;

  /// Public key for message encryption (to be implemented)
  final String? publicKey;

  /// When the contact was added
  final DateTime addedAt;

  /// Last time identity was verified
  final DateTime? lastVerified;

  /// Notes about the contact
  final String? notes;

  /// Whether this contact is blocked
  final bool isBlocked;

  Contact({
    required this.address,
    this.nickname,
    required this.state,
    required this.age,
    required this.stake,
    required this.isVerifiedHuman,
    this.publicKey,
    required this.addedAt,
    this.lastVerified,
    this.notes,
    this.isBlocked = false,
  });

  /// Create Contact from IdenaAccount
  factory Contact.fromAccount(IdenaAccount account, {String? nickname}) {
    return Contact(
      address: account.address,
      nickname: nickname,
      state: account.identityStatus,
      age: account.age ?? 0,
      stake: account.stake,
      isVerifiedHuman: _isVerifiedHuman(account.identityStatus),
      addedAt: DateTime.now(),
      lastVerified: DateTime.now(),
    );
  }

  /// Check if identity state is verified human
  static bool _isVerifiedHuman(String state) {
    return state == 'Human' || state == 'Verified';
  }

  /// Get display name (nickname or shortened address)
  String get displayName {
    if (nickname != null && nickname!.isNotEmpty) {
      return nickname!;
    }
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  /// Get identity badge emoji
  String get identityBadge {
    switch (state) {
      case 'Human':
        return '✅'; // Green checkmark
      case 'Verified':
        return '⭐'; // Gold star
      case 'Newbie':
        return '🆕'; // Blue dot
      case 'Suspended':
        return '⚠️'; // Yellow warning
      case 'Zombie':
      case 'Killed':
        return '❌'; // Red X
      default:
        return '⭕'; // Gray circle - unverified
    }
  }

  /// Get trust level description based on age
  String get trustLevel {
    if (age > 50) return '🌟🌟🌟🌟🌟 Long-standing human';
    if (age > 10) return '⭐⭐⭐ Verified human';
    if (age > 3) return '⭐⭐ Established identity';
    return '🆕 New identity';
  }

  /// Check if identity verification is stale (>24 hours)
  bool get needsVerification {
    if (lastVerified == null) return true;
    return DateTime.now().difference(lastVerified!) > const Duration(hours: 24);
  }

  /// Create a copy with updated fields
  Contact copyWith({
    String? address,
    String? nickname,
    String? state,
    int? age,
    double? stake,
    bool? isVerifiedHuman,
    String? publicKey,
    DateTime? addedAt,
    DateTime? lastVerified,
    String? notes,
    bool? isBlocked,
  }) {
    return Contact(
      address: address ?? this.address,
      nickname: nickname ?? this.nickname,
      state: state ?? this.state,
      age: age ?? this.age,
      stake: stake ?? this.stake,
      isVerifiedHuman: isVerifiedHuman ?? this.isVerifiedHuman,
      publicKey: publicKey ?? this.publicKey,
      addedAt: addedAt ?? this.addedAt,
      lastVerified: lastVerified ?? this.lastVerified,
      notes: notes ?? this.notes,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'nickname': nickname,
      'state': state,
      'age': age,
      'stake': stake,
      'isVerifiedHuman': isVerifiedHuman,
      'publicKey': publicKey,
      'addedAt': addedAt.toIso8601String(),
      'lastVerified': lastVerified?.toIso8601String(),
      'notes': notes,
      'isBlocked': isBlocked,
    };
  }

  /// Create Contact from JSON
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      address: json['address'] as String,
      nickname: json['nickname'] as String?,
      state: json['state'] as String,
      age: json['age'] as int,
      stake: (json['stake'] as num).toDouble(),
      isVerifiedHuman: json['isVerifiedHuman'] as bool,
      publicKey: json['publicKey'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastVerified: json['lastVerified'] != null
          ? DateTime.parse(json['lastVerified'] as String)
          : null,
      notes: json['notes'] as String?,
      isBlocked: json['isBlocked'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}
