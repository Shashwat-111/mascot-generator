String relativeTime(DateTime time, [DateTime? now]) {
  final clock = now ?? DateTime.now();
  final diff = clock.difference(time);
  if (diff.inSeconds.abs() < 45) return 'just now';
  if (diff.inMinutes.abs() < 60) {
    final minutes = diff.inMinutes.abs();
    return '$minutes min ago';
  }
  if (diff.inHours.abs() < 24) {
    final hours = diff.inHours.abs();
    return '${hours}h ago';
  }
  if (diff.inDays.abs() == 1) return 'yesterday';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${time.day} ${months[time.month - 1]}';
}
