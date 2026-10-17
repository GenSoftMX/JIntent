# Manejo de errores

Usa `Either<Exception, T>` para los fallos esperados de una operación. `Left`
contiene el fallo; `Right` contiene el éxito. Son valores, no un límite
automático de excepciones: las excepciones lanzadas siguen propagándose.

```dart
Either<Exception, int> decrement(int value) {
  return value <= 0
      ? Left(Exception('Counter cannot be negative'))
      : Right(value - 1);
}
```

En un intent, traduce los fallos recuperables de la operación a un effect
dedicado. Presenta la retroalimentación únicamente en el handler del effect.
Devuelve los futures de `controller.intent(...)` desde los métodos del
controlador. Captura los fallos inesperados o de ciclo de vida en el límite de
la UI y regístralos sin emitir otro effect de presentación. `unawaited` por sí
solo no captura errores. Espera las ramas asíncronas, incluidos los futures que
devuelve `fold`, antes de que un intent termine.

Liberar el controlador no detiene los servicios en ejecución. Comprueba
`controller.mounted` después de cada espera antes de acceder a un estado
liberado o iniciar más trabajo. Mantén la cancelación en el servicio que es
dueño de la operación. El
[ejemplo del contador](../example/README.md#error-handling) lo muestra de
principio a fin.

## Límites de fallo

| Límite | Comportamiento ante el fallo |
| --- | --- |
| Validación en un caso de uso | El primer `Left` devuelto detiene la ejecución; las excepciones lanzadas se propagan |
| Despacho de un intent | Los fallos se propagan por el future devuelto |
| Invocación solapada de una misma instancia de intent | `StateError` |
| Intent nuevo o en cola en un controlador liberado | Future fallido con `StateError` para el dispatcher secuencial predeterminado |
| Effect esperado sin listener | El resultado falla con `StateError` |
| Effect esperable sin handler coincidente | La estrategia predeterminada hace fallar el resultado con `StateError`; es configurable |
| Timeout de un effect | `TimeoutException` |
| Excepción en un handler | El resultado pendiente y el future directo de `handle()` fallan con el error original |
| Liberación del controlador | Los resultados de effects pendientes fallan; el trabajo externo en ejecución continúa |
| Entrada no soportada en `transformDynamic` | `ArgumentError` |

Esto es un resumen de límites, no un catálogo de excepciones de la aplicación ni
de mensajes de error estables. Consulta [effects](effects.md) y
[migración](migration.md).

## Hook de registro en depuración

```dart
EitherConfig.configureLogger((error) {
  // Send a redacted diagnostic to the application's logger.
});
```

El hook se ejecuta solo en modo debug y no captura excepciones lanzadas, no
instala manejadores de errores de Flutter ni ofrece reporte de fallos.
`EitherConfig.errorLogger` es global; restáuralo después de las pruebas o de
integraciones temporales. Mantén el callback sin lanzar excepciones porque se
ejecuta al construir un `Left`. Los manejadores globales de Flutter, la analítica
y el reporte de fallos corresponden a la aplicación que consume la librería. Evita
registrar secretos o mostrar a los usuarios excepciones sin procesar.
