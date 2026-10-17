# Pruebas con JIntent

Importa los helpers solo desde las pruebas:

```dart
import 'package:jintent/testing.dart';
```

## Registrar estados

```dart
final controller = CounterController();
final states = JStateRecorder(controller);

await controller.intent(IncrementIntent());

expect(states.states, [const CounterState(count: 1)]);
states.dispose();
controller.dispose();
```

El recorder captura, en orden, los cambios hechos después de conectarse. Las
actualizaciones iguales nunca aparecen porque los controladores las omiten.

## Hacer el papel de la UI para los effects

`JEffectRecorder` escucha los effects de un controlador, los registra y completa
los esperables con respuestas programadas, de modo que los intents que esperan un
diálogo puedan ejecutarse sin widgets:

```dart
final ui = JEffectRecorder(controller)
  ..respondTo<ConfirmDelete, bool>((effect) => true);

await controller.intent(DeleteIntent());

expect(ui.effectsOfType<ConfirmDelete>(), hasLength(1));
await ui.dispose();
```

Registra las respuestas por tipo concreto de effect. Un effect esperable sin
respuesta queda pendiente, lo que permite probar timeouts; pasa
`failUnhandled: true` para hacerlo fallar con `StateError`. Un responder que
lanza hace fallar el effect con ese error.

## Reiniciar el estado global

`JObserver`, `JEffectsConfig`, `JMetrics` y `EitherConfig` son globales al
proceso. Llama a `resetJIntentGlobals()` en `setUp` o `tearDown` para que una
prueba no afecte a otra.

```dart
setUp(resetJIntentGlobals);
```
