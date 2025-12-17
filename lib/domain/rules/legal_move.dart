import '../enums/play_type.dart';
import '../model/game_state.dart';
import '../model/play.dart';
import 'play_compare.dart';

class LegalMove {
  static String? validatePlay({
    required GameState state,
    required ResolvedPlay candidate,
    required Play? lastPlay,
  }) {
    // 领出：任意合法牌型都行（判型本身已保证结构）
    if (lastPlay == null) return null;

    final candType = candidate.type;
    final lastType = lastPlay.resolved.type;

    final isBombOrSF = candType == PlayType.bomb || candType == PlayType.straightFlush5 || candType == PlayType.tianWangZha;
    final lastIsBombOrSF = lastType == PlayType.bomb || lastType == PlayType.straightFlush5 || lastType == PlayType.tianWangZha;

    // 除炸弹/同花顺外只能同牌型
    if (!isBombOrSF && !lastIsBombOrSF && candType != lastType) {
      return '只能用同牌型压制（除炸弹/同花顺外）';
    }

    // 若候选不是炸弹/同花顺/天王炸，但上一手是炸弹/同花顺/天王炸，则不能压（因为你没有越级牌型）
    if (!isBombOrSF && lastIsBombOrSF) {
      return '上一手为炸弹/同花顺/天王炸，需同级或更高牌型压制';
    }

    final cmp = PlayCompare(state.config);
    final ok = cmp.beats(candidate, lastPlay.resolved, state.levelRank);
    if (!ok) return '压不住上一手';
    return null;
  }
}
