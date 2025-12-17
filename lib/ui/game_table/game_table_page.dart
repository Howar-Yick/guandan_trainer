import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/game_providers.dart';
import '../../domain/engine/actions.dart';
import '../../domain/enums/seat.dart';
import 'widgets/action_bar.dart';
import 'widgets/hand_view.dart';
import 'widgets/player_panel.dart';
import 'widgets/table_trick_view.dart';

class GameTablePage extends ConsumerWidget {
  const GameTablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (event) {
        if (event is! RawKeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.space) {
          notifier.dispatch(PassAction(Seat.s0));
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          notifier.dispatch(PlaySelectedAction(Seat.s0));
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          notifier.dispatch(ClearSelectionAction());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('guandan_trainer  |  级牌=${state.levelRank.name}  |  轮到：座位${state.currentTurn.index}'),
          actions: [
            TextButton(
              onPressed: () => notifier.dispatch(DealAction()),
              child: const Text('发牌'),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            // 上方：对手/队友信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                PlayerPanel(seat: Seat.s1),
                PlayerPanel(seat: Seat.s2),
                PlayerPanel(seat: Seat.s3),
              ],
            ),
            const SizedBox(height: 8),
            const TableTrickView(),
            const SizedBox(height: 8),
            const ActionBar(),
            const Divider(height: 1),
            // 底部：自己的手牌
            const SizedBox(height: 8),
            const Text('你的手牌（座位0）：点击选牌，Enter出牌，Space过牌，Esc清空'),
            const SizedBox(height: 8),
            const Expanded(child: HandView(seat: Seat.s0)),
            const Divider(height: 1),
            // 简易日志
            Expanded(
              child: ListView.builder(
                itemCount: state.log.entries.length,
                itemBuilder: (_, i) {
                  final e = state.log.entries[i];
                  return ListTile(
                    dense: true,
                    title: Text(e.text),
                    subtitle: Text(e.ts.toIso8601String()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
