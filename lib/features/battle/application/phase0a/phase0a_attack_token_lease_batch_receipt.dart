import '../../domain/phase0a/attack_token_lease_runtime.dart';

final class Phase0aAttackTokenLeaseBatchReceipt {
  Phase0aAttackTokenLeaseBatchReceipt({
    required this.before,
    required Iterable<AttackTokenLeaseMutation> mutations,
    required this.after,
  }) : mutations = List<AttackTokenLeaseMutation>.unmodifiable(mutations);

  final AttackTokenLeaseSnapshot before;
  final List<AttackTokenLeaseMutation> mutations;
  final AttackTokenLeaseSnapshot after;
}
