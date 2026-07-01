String? normalizeStockCode(String raw) {
  final s = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (s.isEmpty) return null;
  if (RegExp(r'^(sh|sz|bj)\d{6}$').hasMatch(s)) return s;
  if (RegExp(r'^\d{6}$').hasMatch(s)) {
    if (s[0] == '6' || s.startsWith('90') || s[0] == '5') return 'sh$s';
    if ('0321'.contains(s[0])) return 'sz$s';
    if ('84'.contains(s[0]) || s.startsWith('92')) return 'bj$s';
  }
  return null;
}

String sessionHint() {
  final now = DateTime.now();
  if (now.weekday >= 6) return '休市';
  final t = now.hour * 100 + now.minute;
  if (t >= 930 && t <= 1130 || t >= 1300 && t <= 1500) return '交易中';
  if (t >= 915 && t < 930) return '集合竞价';
  return '已收盘';
}
