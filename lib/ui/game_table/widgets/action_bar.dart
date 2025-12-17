import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/game_providers.dart';
import '../../../domain/engine/actions.dart';
import '../../../domain/enums/seat.dart';

class ActionBar extends ConsumerWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final enabled = s.currentTurn == Seat.s0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: enabled ? () => notifier.dispatch(PlaySelectedAction(Seat.s0)) : null,
          child: const Text('出牌(Enter)'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: enabled ? () => notifier.dispatch(PassAction(Seat.s0)) : null,
          child: const Text('过牌(Space)'),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => notifier.dispatch(ClearSelectionAction()),
          child: const Text('清空(Esc)'),
        ),
      ],
    );
  }
}
