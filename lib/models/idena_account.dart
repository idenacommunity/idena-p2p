/// Model class representing an Idena account with balance and identity information
class IdenaAccount {
  final String address;
  final double balance;
  final double stake;
  final String identityStatus;
  final int? epoch;
  final int? age;

  IdenaAccount({
    required this.address,
    this.balance = 0.0,
    this.stake = 0.0,
    this.identityStatus = 'Unknown',
    this.epoch,
    this.age,
  });

  /// Creates an account with minimal information (just address)
  factory IdenaAccount.minimal(String address) {
    return IdenaAccount(
      address: address,
      balance: 0.0,
      stake: 0.0,
      identityStatus: 'Loading...',
    );
  }

  /// Creates an account from API response data
  factory IdenaAccount.fromMap(Map<String, dynamic> map) {
    return IdenaAccount(
      address: map['identityAddress'] ?? map['address'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      stake: (map['stake'] ?? 0.0).toDouble(),
      identityStatus: map['identityState'] ?? 'Unknown',
      epoch: map['epoch'],
      age: map['age'],
    );
  }

  /// Converts account to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'balance': balance,
      'stake': stake,
      'identityStatus': identityStatus,
      'epoch': epoch,
      'age': age,
    };
  }

  /// Creates a copy of this account with updated fields
  IdenaAccount copyWith({
    String? address,
    double? balance,
    double? stake,
    String? identityStatus,
    int? epoch,
    int? age,
  }) {
    return IdenaAccount(
      address: address ?? this.address,
      balance: balance ?? this.balance,
      stake: stake ?? this.stake,
      identityStatus: identityStatus ?? this.identityStatus,
      epoch: epoch ?? this.epoch,
      age: age ?? this.age,
    );
  }

  /// Gets the total balance (balance + stake)
  double get totalBalance => balance + stake;

  /// Checks if the identity is validated (not Unknown, Undefined, or Killed)
  bool get isValidated {
    final status = identityStatus.toLowerCase();
    return status != 'unknown' &&
           status != 'undefined' &&
           status != 'killed' &&
           status != 'loading...';
  }

  /// Gets a color indicator for the identity status
  /// Used for UI display
  String get statusColor {
    switch (identityStatus.toLowerCase()) {
      case 'human':
        return 'gold';
      case 'verified':
        return 'green';
      case 'newbie':
        return 'blue';
      case 'candidate':
        return 'gray';
      case 'suspended':
      case 'zombie':
      case 'killed':
        return 'red';
      default:
        return 'gray';
    }
  }

  @override
  String toString() {
    return 'IdenaAccount(address: $address, balance: $balance, stake: $stake, '
           'status: $identityStatus, epoch: $epoch)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is IdenaAccount && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}
