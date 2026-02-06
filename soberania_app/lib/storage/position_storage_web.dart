// Implementação web: localStorage síncrono para sobreviver ao fechamento da aba.
import 'package:web/web.dart' as web;

const _kKeyPhase = 'soberania_last_phase';
const _kKeyIndex = 'soberania_last_index';

void registerBeforeUnload(void Function() onSave) {
  // beforeunload tem limitações de tipo no package:web; o Timer.periodic + sync write bastam
}

void savePositionSync(String phase, int index) {
  try {
    web.window.localStorage.setItem(_kKeyPhase, phase);
    web.window.localStorage.setItem(_kKeyIndex, index.toString());
  } catch (_) {}
}

String? getLastPhaseSync() {
  try {
    return web.window.localStorage.getItem(_kKeyPhase);
  } catch (_) {
    return null;
  }
}

int? getLastIndexSync(String phase) {
  try {
    final storedPhase = web.window.localStorage.getItem(_kKeyPhase);
    if (storedPhase != phase) return null;
    final s = web.window.localStorage.getItem(_kKeyIndex);
    if (s == null || s.isEmpty) return null;
    return int.tryParse(s);
  } catch (_) {
    return null;
  }
}

void clearPositionSync() {
  try {
    web.window.localStorage.removeItem(_kKeyPhase);
    web.window.localStorage.removeItem(_kKeyIndex);
  } catch (_) {}
}
