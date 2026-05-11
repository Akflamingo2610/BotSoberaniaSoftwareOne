// Stub para plataformas não-web - sem persistência síncrona extra.
void savePositionSync(String phase, int index) {}

void registerBeforeUnload(void Function() onSave) {}

String? getLastPhaseSync() => null;

int? getLastIndexSync(String phase) => null;

void clearPositionSync() {}
