# JIntent

[![Pub Version](https://img.shields.io/pub/v/jintent.svg)](https://pub.dev/packages/jintent)
[![Build](https://img.shields.io/github/actions/workflow/status/GenSoftMX/JIntent/ci.yml?branch=main)](https://github.com/GenSoftMX/JIntent/actions)

JIntent es una librería de Flutter para intents explícitos, estado inmutable y
effects de UI de un solo uso. Los controladores gestionan el estado; los intents
realizan las operaciones; los handlers de effects presentan diálogos, navegación y
retroalimentación fuera del estado persistente.

Consulta la [guía interactiva](https://gensoftmx.github.io/JIntent/) (en inglés y
español) con los conceptos, demos en vivo y la referencia de la API.

## Instalación

```sh
flutter pub add jintent
```

O decláralo tú mismo. La versión 3.0.0 requiere Flutter 3.29.2 o superior:

```yaml
dependencies:
  jintent: ^3.0.0
```

Importa el punto de entrada público:

```dart
import 'package:jintent/jintent.dart';
```

Las piezas opcionales tienen sus propios puntos de entrada, para que el núcleo se
mantenga pequeño:

| Importación | Contenido |
| --- | --- |
| `package:jintent/jintent.dart` | Estado, intents, controlador, effects, dispatchers, `JObserver`, `Either`, casos de uso, mappers |
| `package:jintent/devtools.dart` | Registro estructurado, correlación, métricas, overlay de depuración |
| `package:jintent/testing.dart` | Recorders de estado y de effects, reinicio global |
| `package:jintent/widgets.dart` | Builder y selector de controlador sin paquete de providers |
| `package:jintent/undo_redo.dart` | Undo/redo estable, historial observable y comandos |
| `package:jintent/navigation.dart` | Abstracción ligera de `Navigator` |
| `package:jintent/utils.dart` | Throttler, validación, utilidades de color y de plataforma |

Consulta [undo y redo](doc/undo-redo.md) para el historial local de ediciones, la
integración con la UI, el orden y la migración desde la importación experimental
heredada.

Actualizar desde 2.x cambia la igualdad de estado, los fallos de effects y el
comportamiento de la liberación. Revisa primero la
[guía de migración](doc/migration.md).

## Novedades de la 3.0.0

- **Entry points:** `jintent.dart` contiene solo el núcleo; devtools, undo/redo,
  widgets, navegación, utilidades y helpers de pruebas pasaron a sus propios
  imports.
- **Estado predecible:** las actualizaciones iguales al estado actual se omiten,
  así que listeners y observadores solo ven cambios reales.
- **Effects más seguros:** un effect esperado sin listener ni handler falla con
  `StateError`, y la liberación hace fallar los resultados pendientes. El buffer
  de effects es opcional.
- **Concurrencia:** dispatchers droppable y restartable, con cancelación
  cooperativa mediante `JIntent.cancel`.
- **Observabilidad:** `JObserverDelegate` componibles que también reportan
  intents fallidos, cancelados y descartados, además de métricas y overlay más
  completos.
- **También nuevo:** undo/redo estable con historial observable,
  `JControllerBuilder` y `JControllerSelector`, y grabadores de pruebas en
  `package:jintent/testing.dart`.

Varios de estos cambios modifican el comportamiento respecto a 2.x. Consulta el
[changelog](CHANGELOG.md) completo y la [guía de migración](doc/migration.md).

## Ejemplo mínimo

```dart
import 'package:jintent/jintent.dart';

class CounterState extends JState {
  final int count;
  const CounterState({this.count = 0});

  @override
  CounterState copyWith({int? count}) =>
      CounterState(count: count ?? this.count);

  @override
  List<Object?> get props => [count];
}

class IncrementIntent extends JIntent<CounterState>
    with JIntentHelpers<CounterState> {
  @override
  Future<void> onInvoke() async {
    update((state) => state.copyWith(count: state.count + 1));
  }
}

class CounterController extends JController<CounterState> {
  CounterController() : super(const CounterState());

  Future<void> increment() => intent(IncrementIntent());

  @override
  void onInit() {}
}

Future<void> main() async {
  final controller = CounterController();
  try {
    await controller.increment();
    print(controller.currentState.count); // 1
  } finally {
    controller.dispose();
  }
}
```

Conecta el controlador directamente con `JControllerBuilder` o
`JControllerSelector` de `package:jintent/widgets.dart`, o usa tu integración con
StateNotifier. La [guía de widgets](doc/widgets.md) cubre la propiedad, el
reemplazo del controlador y la selección de una parte del estado. La
[galería de ejemplos](example/) usa los builders en sus cuatro laboratorios y
Riverpod con `JEffectListener` en el contador.

## Contratos

- `JState`: incluye los valores relevantes en `props`; devuelve estados nuevos e
  inmutables. Las actualizaciones iguales al estado actual se omiten.
- `JIntent`: sobrescribe `onInvoke` y espera su trabajo. Una instancia no puede
  ejecutarse de forma concurrente; puede reutilizarse tras completarse.
- `JController`: despacha de forma secuencial por defecto. Devuelve los futures de
  los despachos y gestiona sus errores en el límite de la UI. `onInit` se ejecuta
  de forma síncrona desde el constructor base, antes del cuerpo del constructor de
  la subclase. Pasa `effectBufferSize` para retener los effects emitidos antes de
  que la UI se conecte.
- `JEffect`: eventos de UI transitorios. Registra cada tipo concreto de effect en
  un `JSideEffectHandler` y completa los resultados esperados. Una suscripción por
  sí sola no garantiza la finalización; configura un timeout para el trabajo de UI
  que se espera.
- `JObserver`: registra `JObserverDelegate`s para observar intents (incluidos los
  fallos), estados y effects; consulta [observabilidad](doc/observability.md).
- La liberación rechaza los intents en cola y los resultados de effects pendientes;
  los servicios y handlers en ejecución necesitan su propia cancelación o
  comprobaciones de ciclo de vida.

Consulta [effects](doc/effects.md) para el registro, los fallos y los timeouts, y
[manejo de errores](doc/error-handling.md) para los límites de las operaciones.
