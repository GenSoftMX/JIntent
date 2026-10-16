# Mapa del sistema

Observación estática del checkout el 2026-10-16; comprobar archivos actuales antes
de reutilizar estos datos. Es contexto informativo, no una especificación futura.

- `pubspec.yaml`: paquete Flutter `jintent`, versión 2.2.0, Dart `^3.7.2`.
- `lib/jintent.dart`: exports de core, domain, devtools, experimental, navigation
  y utils. Experimental también forma parte de la entrada principal actual.
- `JController<T>` extiende `StateNotifier<T>`, aplica reducers y emite efectos
  por stream broadcast. Su dispatcher predeterminado es secuencial por instancia.
- `JIntent<T>` guarda el controlador al invocarse y ejecuta `onInvoke()`.
- `JEffect<T>` usa un completer para resultados; listener y handler conectan UI.
- `domain/`: Either, casos de uso y mappers; `devtools/`: observadores y métricas.
- `test/src/`: pruebas de core, domain y devtools. Su presencia no acredita cobertura.
- `example/`: app Flutter consumidora con organización propia.
- `doc/adr/`: intención y decisiones; algunos documentos son propuestas y pueden
  contener ejemplos distintos de la API actual. ADR-000 figura como aceptado.
- `.github/workflows/ci.yml`: Flutter 3.35.4, formato, análisis, tests y cobertura.

Los hallazgos de análisis requieren reproducción y criterios de aceptación antes
de convertirse en cambios; este mapa no declara corregidos los riesgos existentes.
