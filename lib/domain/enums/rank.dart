// 牌点：2~A + Jokers（大/小王）
// 注意：大小比较不直接用 enum 顺序，而用 RankOrder（包含“级牌插入”逻辑）
enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
  smallJoker,
  bigJoker,
}
