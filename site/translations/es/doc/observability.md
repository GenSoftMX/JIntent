# Observabilidad y puntos de extensión

JIntent ofrece registro, correlación, métricas y un overlay de depuración desde
`package:jintent/devtools.dart`; `JObserver` en sí viene de
`package:jintent/jintent.dart`. Los helpers de prueba están en
`package:jintent/testing.dart`; consulta [pruebas](testing.md). Configúralos en la
aplicación; no instalan un backend remoto. Anonimiza los datos de la aplicación
antes de registrarlos.

## Registro y correlación

```dart
final logger = JStructuredLogger(
  serviceName: 'counter',
  minLevel: LogLevel.info,
);
logger.info('Counter loaded', context: {'source': 'local'});
```

`JStructuredLogger` escribe registros en JSON. `CorrelationContext.runWithCorrelation`
ejecuta un callback asíncrono en una zona con un ID disponible mediante `current`
y `asContext`. Incluye ese contexto en los registros cuando haga falta. La
[configuración de observabilidad](../example/lib/src/@core/observability/) del
ejemplo muestra una integración.

## Observador y métricas

`JObserver` notifica el inicio, la finalización y el fallo de un intent, los
cambios de estado y los effects emitidos. Registra un `JObserverDelegate` con
`JObserver.addObserver`; sobrescribe solo las notificaciones que necesites.
Pueden coexistir tantos observadores como quieras, y la función devuelta elimina
únicamente ese registro:

```dart
class AnalyticsObserver extends JObserverDelegate {
  @override
  void onIntentFailed(JIntent intent, Object error, StackTrace stackTrace) {
    report(intent.runtimeType, error, stackTrace);
  }
}

final remove = JObserver.addObserver(AnalyticsObserver());
```

`onIntentStarted` y `onIntentFailed` los emite el propio `JIntent`, así que
cubren todos los dispatchers y las llamadas directas a `run`. Los dispatchers
informan cómo terminó un intent sin fallar: `onIntentDispatched` si tuvo éxito,
`onIntentCancelled` cuando se solicitó la cancelación
([concurrencia](concurrency.md)) y `onIntentDropped` cuando un dispatcher lo
descartó sin ejecutarlo. Los dos últimos existen solo en los observadores, no como
callbacks estáticos. Un cambio de estado hecho dentro de un intent informa a ese
intent como su origen incluso si `update` se llamó sin uno. Los rechazos antes de
la ejecución (controlador liberado, invocación solapada de una misma instancia,
entradas de cola canceladas) no son fallos del intent y no se reportan.

Los callbacks estáticos (`onIntentDispatched`, `onIntentFailed`,
`onStateChanged`, `onEffectEmitted`) tienen cada uno una sola ranura y asignar
uno reemplaza el valor anterior; se ejecutan antes que los observadores
registrados. Prefiere los observadores cuando varios consumidores comparten el
proceso. Un observador que lanza nunca afecta al código observado: el error va a
`FlutterError.reportError` y los demás siguen ejecutándose. Llama a
`JObserver.reset()` en las pruebas.

`JMetrics.enable()` activa la recolección; `attachToObserver()` registra un
observador que cuenta `intent.dispatched`, `intent.failed`, `intent.cancelled`,
`intent.dropped`, `state.changed` y `effect.emitted`, y registra
`intent.execution.duration` (microsegundos) para cada intent. Esa duración abarca
solo `onInvoke`; no se mide el tiempo de espera en la cola de un dispatcher ni la
finalización de los effects. Conectarlo dos veces no tiene efecto adicional y
`detachFromObserver()` lo detiene. Usa `incrementCounter`, `recordGauge`,
`startTimer` y `stopTimer` para mediciones explícitas, y `getMetrics` o
`getSummary` para inspeccionarlas. `JMetrics.maxMetrics` (1000 por defecto) acota
las mediciones retenidas descartando las más antiguas.

Los nombres de intents, effects y estados en los logs, las etiquetas de métricas
(`type`, `stateType`, `originIntent`), los títulos del overlay y los mensajes de
error provienen de `runtimeType.toString()`. Las compilaciones que minifican u
ofuscan nombres (Flutter web `--release`, o `--obfuscate` en móvil) reportan en su
lugar nombres cortos generados, como `minified:dY`. Los contadores y el
comportamiento no cambian; solo las etiquetas. Las compilaciones web con
`--profile` conservan los nombres, por eso la guía interactiva compila así su demo.

## Overlay de depuración

`JDevToolsOverlay` muestra dentro de la aplicación las notificaciones recientes de
intents, estados y effects. Los intents que fallaron, se cancelaron o se
descartaron también aparecen, con el título `Type (failed)`, `Type (cancelled)` o
`Type (dropped)`. Es un overlay de depuración local, no una integración con
DevTools del navegador.

```dart
MaterialApp(
  builder: (context, child) => JDevToolsOverlay(
    enabled: kDebugMode,
    maxEvents: 50,
    maxEventAge: const Duration(seconds: 30),
    child: child!,
  ),
);
```

Registra su propio observador y elimina solo ese registro al liberarse, por lo que
puede combinarse con registro, métricas y callbacks estáticos. Mantenlo
desactivado fuera de la depuración: los metadatos de los eventos pueden incluir
datos de la aplicación. Consulta la
[implementación](../lib/src/devtools/devtools_overlay.dart).

## Puntos de extensión

JIntent no tiene un registro de plugins ni descubrimiento automático de plugins.
Expone:

- `JObserver`: ver arriba.
- `JIntentDispatcher`: implementa `dispatch<T>` e inyéctalo mediante el
  constructor del controlador. El controlador usa por defecto el despacho
  secuencial; `JDefaultIntentDispatcher` invoca de inmediato sin cola. Consulta
  [concurrencia](concurrency.md) para las estrategias ya preparadas. Un
  dispatcher personalizado informa a los observadores mediante los métodos
  públicos `JObserver.notify...`: llama a `notifyIntentCompleted` después de que
  `intent.run` tenga éxito (informa `onIntentCancelled` para un intent cancelado
  y `onIntentDispatched` en los demás casos) y a `notifyIntentDropped` para un
  intent que descarta sin ejecutarlo. No llames a los otros métodos `notify...`:
  el intent informa su propio inicio y fallo, y el controlador informa los
  cambios de estado y los effects.
- `JPendingIntentCancellation`: impleméntalo en los dispatchers que retienen
  trabajo en cola. Rechaza los futures pendientes al liberar, conserva el orden de
  los demás controladores y propaga la cancelación a través de los decoradores.
  `LoggingDispatcher` lo hace.
- `JSideEffectHandler`: registra handlers para tipos concretos de effect.
  Consulta [effects](effects.md).

Los dispatchers personalizados deben definir el orden, la concurrencia y el
comportamiento ante fallos. No esperes recursivamente un intent hijo en cola
detrás del intent que se está ejecutando en la misma cola secuencial.
[Undo/redo](undo-redo.md) registra cambios de estado locales seleccionados, no
operaciones de servicios externos. Sus llamadas síncronas de undo/redo informan a
los observadores los cambios reales de estado; despacha un intent personalizado
cuando estas operaciones deban compartir la cola y llevar atribución de intent.

## Medir el rendimiento

No se ha establecido ningún presupuesto de latencia, memoria, tamaño de binario ni
rendimiento. Mide en el dispositivo y el modo de compilación objetivo: el tiempo
desde el despacho hasta la finalización (incluida la espera en cola), las
reconstrucciones tras cambios de estado (los estados iguales se omiten), el
estado retenido y los eventos de depuración, y por separado las integraciones de
registro y observadores. Registra la carga de trabajo, el dispositivo, el modo de
compilación y el método junto con cualquier resultado que publiques.
