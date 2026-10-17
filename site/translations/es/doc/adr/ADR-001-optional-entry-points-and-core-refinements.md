# ADR-001: Puntos de entrada opcionales y refinamientos del núcleo

**Estado:** Aceptado para la 3.0.0 aún sin publicar

**Fecha:** 2026-10-16

**Se relaciona con:** ADR-000 (D2, D6, D7, D9). No lo reemplaza.

## Contexto

El ADR-000 enumera los frameworks de navegación y la validación de formularios
como fuera de alcance, y sin embargo el punto de entrada principal exportaba
helpers de navegación, validación, color y plataforma, código experimental y todas
las herramientas de desarrollo. La observabilidad usaba callbacks estáticos de una
sola ranura que las herramientas sobrescribían, y los fallos de los intents eran
invisibles. Los effects emitidos antes de que la UI se conectara se perdían.

## Decisiones

| # | Decisión | Justificación |
| --- | --- | --- |
| D16 | `jintent.dart` exporta el núcleo, los helpers de dominio, `JObserver` y los contratos de dispatcher. Devtools, experimental, navegación y utilidades son puntos de entrada separados; los helpers de prueba están en `testing.dart`. | Alinea la superficie pública con lo que el ADR-000 deja fuera de alcance sin eliminar funciones de las que dependen los usuarios. |
| D17 | `Either` es una clase sellada con `Left`/`Right` `final`, igualdad por valor y un accesor `value`. | Coincidencia de patrones exhaustiva; elimina la necesidad de acceder solo mediante `fold`. Incompatible, aceptado porque la 3.0.0 es una versión mayor. |
| D18 | Los observadores son `JObserverDelegate`s componibles registrados con `JObserver.addObserver`; los intents informan inicio, fallo, cancelación y descarte. Los callbacks estáticos permanecen para los eventos originales. Los fallos de observadores nunca llegan al código observado. | Refina D9. Las herramientas dejan de pisarse entre sí y los fallos pasan a ser observables. |
| D19 | Las estrategias de concurrencia de intents más allá de FIFO (droppable, restartable) usan cancelación cooperativa; los intents cancelados no pueden escribir estado. Las actualizaciones se atribuyen a su intent mediante una zona (`JIntent.current`), por lo que la garantía no depende de que quien llama pase `origin`. | Extiende D6 sin cambiar el valor predeterminado. El código en ejecución nunca se interrumpe. |
| D20 | El búfer de effects es opcional (`effectBufferSize`, 0 por defecto). | Cubre los effects emitidos antes de que la UI se conecte sin cambiar la semántica predeterminada de D5. |
| D21 | `state_notifier ^1.0.0` sigue siendo la base de `JController` y `equatable` sigue en `^2.0.5`. | Ver abajo. |

## Evidencia para D21 (consultada el 2026-10-16)

- [`state_notifier` en pub.dev](https://pub.dev/packages/state_notifier): no está
  descontinuado; la última versión es la 1.0.0, publicada unos tres años antes.
- [Migración a Riverpod 3.0](https://riverpod.dev/docs/3.0_migration): los
  *providers* de `StateNotifier` pasaron a
  `package:flutter_riverpod/legacy.dart`. Eso concierne a los providers de
  Riverpod, no al paquete `state_notifier` que extiende `JController`.
- [Changelog de `equatable`](https://pub.dev/packages/equatable/changelog): la
  3.0.0 deja de comparar `runtimeType`. JIntent omite las actualizaciones a
  estados iguales, así que dos clases de estado distintas con `props` iguales (por
  ejemplo `Loading` e `Initial`, ambas con `props` vacías) pasarían a ser iguales y
  su transición se omitiría. Adoptar la 3.x exigiría que `JState` mantuviera por sí
  mismo la comprobación de tipo.

## Consecuencias

- Los consumidores actualizan las importaciones (consulta la guía de migración) y
  cualquier manejo exhaustivo de `Either`.
- La dependencia de `state_notifier` es un riesgo de mantenimiento, no un defecto.
  Reevalúala si bloquea una versión compatible de Flutter o de Riverpod, o si un
  núcleo de Dart puro pasa a ser un objetivo; eso requeriría un registro nuevo.
- No se aborda: `JEffectsConfig` y el registro estático de `JObserver` siguen
  siendo globales al proceso. `JObserver.reset()` y `resetJIntentGlobals()`
  mitigan esto en las pruebas; las instancias con alcance serían otro cambio
  incompatible.
