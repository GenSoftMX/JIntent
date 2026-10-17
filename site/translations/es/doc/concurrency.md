# Estrategias de concurrencia

Un controlador despacha los intents mediante un `JIntentDispatcher`. Elige la
estrategia que corresponda a la acción del usuario e inyéctala en el
constructor:

```dart
class SearchController extends JController<SearchState> {
  SearchController()
    : super(const SearchState(), dispatcher: JRestartableIntentDispatcher());

  Future<void> search(String query) => intent(SearchIntent(query));

  @override
  void onInit() {}
}
```

| Dispatcher | Comportamiento | Úsalo para |
| --- | --- | --- |
| `JSequentialIntentDispatcher` (predeterminado) | Un intent a la vez, en orden FIFO. | Todo lo sensible al orden. |
| `JDefaultIntentDispatcher` | Ejecuta cada intent de inmediato, de forma concurrente. | Trabajo independiente e idempotente. |
| `JDroppableIntentDispatcher` | Descarta un intent mientras otro con la misma clave está en ejecución. | Enviar, refrescar, dobles toques. |
| `JRestartableIntentDispatcher` | Cancela el intent en ejecución con la misma clave y arranca el nuevo. | Búsqueda mientras se escribe, gana el último. |

Los dispatchers droppable y restartable agrupan los intents por `runtimeType`.
Pasa `keyOf` (un `JIntentKey`) para agrupar de otra forma, por ejemplo por id de
entidad. Las claves distintas nunca se afectan entre sí y se rastrean por
controlador, así que una misma instancia de dispatcher puede compartirse.

## Intents descartados

Un intent descartado no se encola ni se ejecuta, y su future se completa con
normalidad. Los observadores reciben `onIntentDropped` por él;
`onIntentDispatched` se emite solo para los intents que se ejecutaron.

## Cancelación cooperativa

Reiniciar nunca interrumpe el código en ejecución. Llama a `JIntent.cancel()` en
el intent reemplazado, lo que tiene dos efectos:

- `intent.isCancelled` pasa a `true`; compruébalo después de cada `await` y
  retorna pronto para evitar trabajo inútil.
- `JController.update` ignora las actualizaciones hechas por ese intent. Esto es
  lo que evita que una solicitud lenta anterior sobrescriba un resultado más
  nuevo. `invoke` ejecuta `onInvoke` en una zona que lleva el intent
  (`JIntent.current`), y `update` la usa como origen cuando no pasas uno. Las
  llamadas simples a `controller.update(...)` quedan por tanto cubiertas, incluso
  después de `await` y desde timers o callbacks de streams creados dentro del
  intent. Un `origin` explícito tiene prioridad.

El trabajo programado fuera de esa zona, como un callback registrado antes de que
el intent empezara, no se atribuye a él. Las actualizaciones a un controlador
*distinto* nunca se atribuyen ni se bloquean. Los effects no se filtran, y las
operaciones externas siguen ejecutándose salvo que uses su propia API de
cancelación.

El future del intent reemplazado sigue informando su propio resultado o error, y
los observadores reciben `onIntentCancelled` en lugar de `onIntentDispatched`
cuando termina. `cancel()` no hace nada en un intent que no está en ejecución, y
la marca se reinicia cuando el intent se invoca de nuevo.

## Liberación

Estos dispatchers no mantienen cola, así que no hay nada que rechazar al liberar.
Los intents en ejecución no se interrumpen; el controlador rechaza los intents
nuevos con `StateError`, como con cualquier dispatcher. Los dispatchers
personalizados que retengan trabajo en cola deben implementar
`JPendingIntentCancellation`.
