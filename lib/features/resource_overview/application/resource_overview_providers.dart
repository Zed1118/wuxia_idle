import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/inventory_providers.dart';
import '../../../data/game_repository.dart';
import '../domain/resource_overview_item.dart';
import 'resource_overview_service.dart';

final resourceOverviewProvider =
    FutureProvider.autoDispose<List<ResourceOverviewSection>>((ref) async {
      final items = await ref.watch(allInventoryItemsProvider.future);
      return ResourceOverviewService(GameRepository.instance).build(items);
    });
