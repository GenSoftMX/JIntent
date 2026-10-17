# Migración: de 2.x a 3.0.0

La versión 3.0.0 es una versión mayor. Las firmas públicas se conservan en su
mayor parte, pero los cambios de comportamiento descritos abajo son incompatibles
con 2.x y requieren la revisión del consumidor.

## Estado inmutable e igualdad

`update` y el obsoleto `setState` omiten los estados iguales al valor actual
(`==`). Esto reemplaza el comportamiento descrito en 2.0.1. Usa campos `final`,
protege las colecciones anidadas, incluye los valores relevantes en `props` y
devuelve un estado nuevo en lugar de modificar objetos existentes. `@immutable`
no congela los objetos en tiempo de ejecución. Para los campos anulables de
`copyWith`, distingue omitir un valor de asignar null; consulta el ejemplo en la
documentación de la API de `JState`.

## Espera y gestiona los fallos de los intents

Devuelve el future del despacho desde los métodos del controlador:

```dart
Future<void> increment() => intent(_incrementIntent);
```

Consúmelo en el límite de la UI:

```dart
Future<void> onIncrementPressed() async {
  try {
    await controller.increment();
  } catch (error, stackTrace) {
    // Record unexpected or lifecycle failures; do not re-emit them here.
    debugPrint('Increment failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
```

`unawaited(future)` por sí solo no gestiona un error. Si un callback `void` inicia
trabajo asíncrono, usa `unawaited` solo después de que ese método asíncrono
gestione sus fallos. Traduce los fallos recuperables de la operación a effects
dedicados en el límite de la operación y presenta la retroalimentación solo en el
handler del effect. Por ejemplo, los intents del contador capturan las
`Exception`s de persistencia y emiten `ShowSaveFailureEffect` mientras su
controlador está montado. Los `Error`s inesperados y los fallos posteriores a la
liberación siguen propagándose hasta el límite de registro de la UI. Un fallo en
el handler de un effect no debe producir otro effect de presentación por esa vía
alternativa. Espera también las operaciones hijas dentro de un intent: los
helpers `void async` o los futures de `fold` descartados pueden escapar del ciclo
de vida y del manejo de errores del intent.

La misma instancia de intent no puede ejecutarse de forma concurrente. Puede
reutilizarse tras completarse o fallar. Prefiere una instancia separada para
controladores independientes. Invocarla en un controlador liberado falla antes de
vincularse o ejecutarse.

## Effects y handlers ausentes

La estrategia predeterminada ahora es `UnhandledEffectStrategy.warnAndCompleteError`:
los handlers ausentes completan los resultados esperables con un `StateError`
descriptivo, incluso para tipos de resultado anulables. El miembro obsoleto del
enum `warnAndAutoComplete` sigue disponible, pero también completa con error.
Reemplaza las referencias a él; no dependas de null como resultado de reserva.
`throwError` además hace fallar `handle()`; `warnOnly` registra un aviso y
deliberadamente deja el resultado pendiente. Actualiza los `switch` exhaustivos
sobre `UnhandledEffectStrategy` para contemplar el nuevo miembro.

Registra cada tipo concreto de effect: registrar una clase base no gestiona las
subclases. La configuración de effects ahora se exporta desde
`package:jintent/jintent.dart`.

Los fallos de handler completan los resultados pendientes con el error original.
Las llamadas directas a `handle()` deben gestionar el future que devuelven.
`JEffectListener` reporta los fallos de handler con `FlutterError.reportError`;
una aplicación que espera el resultado debe igualmente capturar su fallo. Un fallo
tardío nunca sobrescribe un resultado que ya se completó. Los timeouts ahora
fallan con `TimeoutException`.

## Tener un listener no es una confirmación

Un effect esperado sin ningún listener en el stream falla con `StateError`. Una
emisión fire-and-forget sin listeners se descarta; esperarla explícitamente con
`emitAndWaitSideEffect` también requiere un listener.

`hasListener` solo detecta una suscripción al stream, no un handler coincidente ni
un resultado completado. Un listener que solo registra, una suscripción en pausa o
un handler que olvida `complete`/`completeError` pueden dejar un resultado
pendiente. Configura un timeout adecuado por llamada o un
`JEffectsConfig().defaultTimeout` a nivel de aplicación. No existe un timeout
finito implícito.

Reemplazar un listener desconecta el stream anterior. Desmontar cancela la
suscripción, pero ninguna de las dos acciones cancela los handlers que ya están en
ejecución ni completa sus resultados. Los eventos cancelados antes de entregarse
pueden ser descartados por el stream broadcast. Un resultado pendiente necesita
entonces que el handler lo complete, un timeout o la liberación del controlador.
Comprueba `context.mounted` antes de usar un contexto de UI tras un intervalo
asíncrono.

## Liberación del controlador y cancelación

- Los intents nuevos tras la liberación devuelven un future fallido con
  `StateError`.
- El dispatcher secuencial rechaza de inmediato las tareas en cola del controlador
  liberado, conservando el orden de las tareas de los demás controladores. Captura
  esos futures.
- Los dispatchers personalizados con cola pueden implementar
  `JPendingIntentCancellation`. Los decoradores deben propagar ese contrato;
  `LoggingDispatcher` lo hace.
- Los intents en ejecución y las operaciones externas no se interrumpen. Usa la API
  de cancelación del servicio externo cuando exista y comprueba
  `controller.mounted` después de cada espera antes de leer un estado liberado o
  iniciar más trabajo.
- Los resultados de effects pendientes fallan al liberar el controlador. Los
  resultados ya completados conservan su valor o su error original.
- `emitSideEffect` tras la liberación lanza de forma síncrona y hace fallar el
  resultado del effect. `emitAndWaitSideEffect` expone el fallo mediante el future
  que devuelve.

## Puntos de entrada

`package:jintent/jintent.dart` ahora exporta solo el núcleo, los helpers de
dominio, `JObserver` y los contratos de dispatcher. Importa el resto de forma
explícita; el contenido y el comportamiento no cambian:

| Símbolos | Nueva importación |
| --- | --- |
| `JMetrics`, `Metric`, `MetricType`, `JStructuredLogger`, `LogLevel`, `CorrelationContext`, `JDevToolsOverlay`, `JEffectsLogger`, `enableLoggingObserver` | `package:jintent/devtools.dart` |
| `UndoRedoMixin`, `UndoableIntent`, `UndoableCommand`, `CommandHistory`, `JUndoHistoryState` | `package:jintent/undo_redo.dart` |
| `JNavigator`, `JNavigatorImpl` | `package:jintent/navigation.dart` |
| `JThrottler`, `JValidationUtils`, `JColorUtils`, `JPlatformInfo` | `package:jintent/utils.dart` |

La navegación, la validación y las demás utilidades quedan fuera del alcance
declarado de la librería (ADR-000); siguen disponibles pero no forman parte del
contrato del núcleo.

## Either es sellado

`Either` es una clase `sealed` con las subclases `final` `Left` y `Right`:

- Un `switch` sobre un `Either` es exhaustivo y puede desestructurar `value`.
- El código ya no puede extender ni implementar `Either`.
- `Left` y `Right` exponen `value`, tienen un `toString` y se comparan por valor y
  tipo exacto en tiempo de ejecución, de modo que `Left<String, int>('x')` no es
  igual a `Left<String, num>('x')` en ninguna de las dos direcciones.
- `Right` tiene un constructor `const`; `Left` no, porque puede notificar a
  `EitherConfig.errorLogger`. Un valor `null` en `Left` ya no se convierte con un
  cast a `Object` (antes lanzaba si el logger estaba configurado).

## Los métodos de intent no se pueden sobrescribir

`JIntent.run` y `JIntent.invoke` están anotados con `@nonVirtual`; el analizador
reporta las sobrescrituras. Sobrescribe `onInvoke`, como la documentación siempre
exigió.

Una clase que hace `implements JIntent` (un fake escrito a mano, no una subclase)
ahora debe implementar también `cancel()` e `isCancelled`, o dejará de compilar
(salvo que reenvíe los miembros desconocidos mediante `noSuchMethod`). Extiende
`JIntent` o usa una librería de mocks que los simule.

## Atribución de intents y cancelación

`JIntent.invoke` ejecuta `onInvoke` en una zona que lleva el intent
(`JIntent.current`). Un `JController.update` llamado dentro de ella sin `origin`
ahora informa ese intent a los observadores (antes `null`) y se ignora una vez que
el intent se cancela. Un `origin` explícito, las llamadas fuera de intents y las
actualizaciones a otros controladores se comportan como antes.

Los dispatchers leen `JIntent.isCancelled` después de una ejecución exitosa: un
intent cancelado se informa mediante `onIntentCancelled` en lugar de
`onIntentDispatched`. Un mock de `JIntent` (por ejemplo con `mocktail`) usado con
un dispatcher debe simular `isCancelled`, igual que `run`. Un dispatcher
personalizado que llamaba a `JObserver.notifyIntentDispatched` debe llamar en su
lugar a `notifyIntentCompleted` para que los intents cancelados se informen como
cancelados; consulta los
[puntos de extensión](observability.md#extension-points).

## Búfer de effects (opcional)

Los controladores aceptan `effectBufferSize`. El valor predeterminado, 0, conserva
el comportamiento descrito arriba. Consulta [effects](effects.md).

## Observadores y métricas

- `JObserver` también expone `onIntentFailed`, `JObserverDelegate` y
  `addObserver`. Los callbacks estáticos existentes siguen funcionando.
- Los fallos de observadores y callbacks ya no se propagan al código observado (por
  ejemplo, un `onIntentDispatched` que lanzaba antes hacía fallar un intent que ya
  había tenido éxito). Se reportan mediante `FlutterError.reportError`.
- `enableLoggingObserver`, `JEffectsLogger.attach` y `JDevToolsOverlay` ahora
  registran observadores en lugar de asignar los callbacks estáticos. El código que
  comprueba `JObserver.onIntentDispatched != null` para detectarlos debe cambiar, y
  el overlay ya no borra los callbacks de otros al liberarse.
- `JMetrics.attachToObserver` registra un solo observador (las llamadas repetidas no
  hacen nada), registra un `intent.execution.duration` real y un contador
  `intent.failed`, y `JMetrics.maxMetrics` (1000 por defecto) descarta las
  mediciones más antiguas. El código que leía un historial sin límite debe subir
  el tope.
- `JController.update` ignora las actualizaciones de un intent cuyo
  `JIntent.isCancelled` es true; consulta [concurrencia](concurrency.md).
- `JController.update` ya no imprime `State updated.` mediante `debugPrint`; el aviso
  de «no montado» se imprime solo en modo debug.

## Herramientas

Cambiaron las dependencias de desarrollo (`flutter_lints` 5, se eliminaron
`mockito` y `build_runner`); los consumidores del paquete no se ven afectados. La
CI ahora analiza y prueba la librería y `example/` en Flutter 3.29.2 (el mínimo) y
3.47.6. El mínimo se declara como `flutter: >=3.29.2`, la primera versión que
incluye el Dart 3.7.2 que `sdk: ^3.7.2` ya exigía.

## Novedades

`JDroppableIntentDispatcher`, `JRestartableIntentDispatcher`, `JIntent.cancel`,
`JEffectsConfig.reset()`, el typedef `JIntentKey` y los helpers de
`package:jintent/testing.dart` son nuevos en 3.0.0 y no requieren migración.
`JEffectsConfig` y `UnhandledEffectStrategy` ahora los exporta
`package:jintent/jintent.dart`; reemplaza cualquier importación desde
`package:jintent/src/`. Hay una excepción: `JIntent` ganó los miembros públicos
`cancel()` e `isCancelled`. Una subclase de intent que ya declare un miembro con
alguno de esos nombres debe renombrarlo.

## Versionado

La versión del paquete se declara en [pubspec.yaml](../pubspec.yaml) y los cambios
publicados en [CHANGELOG.md](../CHANGELOG.md). Las firmas conservadas aún pueden
ser cambios de comportamiento incompatibles (orden, manejo de errores, ciclo de
vida), por lo que esta versión es mayor.

## Promoción de undo/redo

Undo/redo es estable desde la 3.0.0. La importación experimental
sigue siendo una exportación de compatibilidad. Usa la importación estable en el
código nuevo, observa `history` para la disponibilidad de los botones y usa
capacidades de historial positivas. Consulta la
[migración y los contratos de undo/redo](undo-redo.md#migration-from-experimental).
