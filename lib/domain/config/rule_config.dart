import '../enums/rank.dart';
import '../enums/suit.dart';

class RuleConfig {
  final int deckCount; // 两副牌=2
  final Rank initialLevel; // 级牌从2开始
  final int straightLen; // 5
  final int straightFlushLen; // 5

  // 癞子：红桃级牌可当任意非王
  final bool enableWildcard;
  final Suit wildcardSuit; // heart
  // 天王炸定义：必须 2 big + 2 small
  final bool strictTianWangZha;

  // 牌型优先级：天王炸 > 8炸>7炸>6炸 > 同花顺 > 5炸 > 4炸 > 普通
  const RuleConfig({
    required this.deckCount,
    required this.initialLevel,
    required this.straightLen,
    required this.straightFlushLen,
    required this.enableWildcard,
    required this.wildcardSuit,
    required this.strictTianWangZha,
  });

  factory RuleConfig.defaultConfig() => const RuleConfig(
        deckCount: 2,
        initialLevel: Rank.two,
        straightLen: 5,
        straightFlushLen: 5,
        enableWildcard: true,
        wildcardSuit: Suit.heart,
        strictTianWangZha: true,
      );
}
