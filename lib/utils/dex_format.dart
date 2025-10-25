// Format a Pokédex number as `#001` or `#025`.
String formatDex(int? dex, {int pad = 3}) {
  if (dex == null) return '#—';
  final s = dex.toString().padLeft(pad, '0');
  return '#$s';
}