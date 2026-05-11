// Import condicional: web usa localStorage síncrono, outras plataformas usam stub.
export 'position_storage_stub.dart'
    if (dart.library.html) 'position_storage_web.dart';
