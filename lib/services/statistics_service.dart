class StatisticsService {
  // 1~45번까지의 역대 당첨 빈도 (근사치 / 더미 데이터 믹스)
  // 실제 서비스에서는 서버나 DB에서 가져오거나 주 1회 로컬 DB를 갱신해야 합니다.
  static final Map<int, int> _frequencyData = {
    1: 175, 2: 168, 3: 165, 4: 169, 5: 159,
    6: 163, 7: 171, 8: 160, 9: 142, 10: 164,
    11: 167, 12: 178, 13: 175, 14: 173, 15: 162,
    16: 164, 17: 175, 18: 178, 19: 162, 20: 170,
    21: 166, 22: 145, 23: 153, 24: 168, 25: 157,
    26: 168, 27: 181, 28: 150, 29: 151, 30: 158,
    31: 166, 32: 152, 33: 177, 34: 188, 35: 163,
    36: 160, 37: 167, 38: 166, 39: 174, 40: 169,
    41: 152, 42: 160, 43: 192, 44: 165, 45: 166,
  };

  /// 전체 통계 데이터를 반환
  static Map<int, int> get frequencyData => _frequencyData;

  /// 가장 많이 나온 핫(Hot) 넘버 N개 반환
  static List<MapEntry<int, int>> getHotNumbers([int count = 5]) {
    final entries = _frequencyData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(count).toList();
  }

  /// 가장 적게 나온 콜드(Cold) 넘버 N개 반환
  static List<MapEntry<int, int>> getColdNumbers([int count = 5]) {
    final entries = _frequencyData.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(count).toList();
  }
}
