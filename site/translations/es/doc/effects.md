# Effects

Los effects representan trabajo transitorio de la UI fuera del estado persistente.
Importa todas las APIs de effects desde `package:jintent/jintent.dart`.

| Tipo | Propósito |
| --- | --- |
| `JFireAndForgetEffect` | Retroalimentación sin valor de retorno esperado |
| `JResultEffect<T>` | Trabajo que produce un resultado |
| `JDialogEffect<T>` | Interacción de UI que produce un resultado |

## Registro

```dart
class ConfirmDelete extends JDialogEffect<bool> {}

class CounterEffects extends JSideEffectHandler<CounterState> {
  CounterEffects(super.controller) {
    register<ConfirmDelete>((effect, controller, context) async {
      // Replace with the application's confirmation dialog.
      effect.complete(true);
    });
  }
}
```

`CounterState` es el estado de aplicación del [README](../README.md).
Conecta un `JEffectListener` con el controlador, el handler y el widget hijo antes
de emitir effects. El registro coincide con el tipo concreto en tiempo de
ejecución, no con una clase base.

Emite retroalimentación con `controller.emitSideEffect(effect)`. Espera el
trabajo de UI con:

```dart
final confirmed = await controller.emitAndWaitSideEffect(
  ConfirmDelete(),
  timeout: const Duration(seconds: 30),
);
```

Captura los fallos en el límite de la operación. Los handlers deben completar los
effects esperados con `complete(value)` o `completeError(error, stackTrace)`.

## Fallos y ciclo de vida

- Sin un listener en el stream, los effects esperados fallan con `StateError`;
  las emisiones fire-and-forget se descartan, salvo que el controlador use un
  búfer de effects (ver más abajo).
- Con un listener pero sin handler registrado, la estrategia predeterminada
  `warnAndCompleteError` hace fallar el resultado con `StateError`.
  `throwError` también hace fallar `handle`; `warnOnly` deja el resultado
  pendiente. La obsoleta `warnAndAutoComplete` también completa con error.
- `JEffectsConfig().defaultTimeout` o el timeout de cada llamada acotan la
  espera; no existe un timeout finito implícito. Al vencer falla con
  `TimeoutException`.
- Las excepciones de un handler hacen fallar los resultados pendientes.
  `JEffectListener` reporta los fallos del handler con `FlutterError.reportError`;
  quienes esperan el resultado igualmente reciben el error.
- Quitar o reemplazar un listener no cancela los handlers en ejecución. Los
  resultados pendientes requieren completarse, un timeout o la liberación del
  controlador. Comprueba `context.mounted` antes de acceder a la UI tras un
  intervalo asíncrono.
- Liberar el controlador hace fallar los resultados pendientes y rechaza nuevas
  emisiones. No cancela el trabajo externo ni sobrescribe resultados ya
  completados.

## Effects emitidos antes de que la UI se conecte

Un controlador puede emitir durante `onInit`, antes de que exista cualquier
`JEffectListener`. De forma predeterminada esos effects se pierden o fallan.
Activa en su lugar un búfer acotado:

```dart
class SplashController extends JController<SplashState> {
  SplashController() : super(const SplashState(), effectBufferSize: 8);

  @override
  void onInit() => emitSideEffect(ShowWelcome());
}
```

Con `effectBufferSize` mayor que cero, los effects emitidos mientras nadie
escucha se retienen, en orden, y se entregan poco después de que se suscriba el
siguiente listener.

- Cada effect se entrega una sola vez, a quien escuche primero. Un segundo
  listener no lo recibe de nuevo.
- Los effects esperables permanecen pendientes mientras se retienen, así que
  `emitAndWaitSideEffect` espera en lugar de fallar; usa un timeout. Los effects
  ya completados (por ejemplo por un timeout) se omiten al entregar.
- Cuando el búfer se llena, el effect más antiguo se descarta y se completa con
  `StateError`.
- La liberación hace fallar los effects esperables retenidos y descarta el resto.
- Los observadores reciben `onEffectEmitted` cuando el effect se emite, no
  cuando se entrega.

El búfer es una ayuda de arranque, no una cola para una UI ausente por mucho
tiempo: los effects retenidos pueden estar obsoletos cuando se muestren.

Cualquier suscripción a `controller.sideEffects` cuenta como listener, así que un
`sideEffects.listen` de diagnóstico conectado antes de la UI recibe los effects
retenidos y el `JEffectListener` que le sigue no recibe ninguno. Para observar
effects sin consumirlos usa `JObserver` (`onEffectEmitted`), que ve cada effect
cuando se emite y nunca lo toma del búfer.

Para los cambios que afectan a los consumidores y los detalles de cancelación,
consulta la [guía de migración](migration.md).
