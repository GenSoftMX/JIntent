# ADR-003: Compatibilidad con equatable 2.x y 3.x

**Estado:** Aceptado para la 3.0.1

**Fecha:** 2026-10-16

**Se relaciona con:** ADR-001 (D21). Reemplaza la parte de `equatable` de D21; la
parte de `state_notifier` se mantiene.

## Contexto

pub.dev puntúa si todas las dependencias de un paquete admiten sus últimas
versiones. `equatable: ^2.0.5` excluía la 3.0.0 (publicada el 2026-09-15). D21
mantuvo la 2.x porque se creía que la 3.0.0 dejaba de comparar `runtimeType`, lo
que haría iguales a dos clases de estado distintas con `props` iguales y omitiría
su transición.

## Decisión

Declarar `equatable: '>=2.0.5 <4.0.0'`. `JState` y `JEquatable` siguen extendiendo
la clase `Equatable`, así que la igualdad de estado no cambia.

## Evidencia (verificada el 2026-10-16)

- La clase `Equatable` de la 3.0.0 sigue comparando `runtimeType` en `==` y lo usa
  en `hashCode`. Su changelog indica la eliminación de `EquatableMixin`, que
  JIntent no usa. La premisa de D21 fue una mala lectura de ese changelog.
- Una prueba con la 3.0.0 resuelta: los estados `Initial` y `Loading` con `props`
  vacías no son iguales, y `update` de uno a otro notifica a los listeners. La
  misma prueba pasa con la 2.x. Ahora forma parte de
  `test/src/core/jstate_test.dart`.
- Las pruebas de la librería y el analizador pasan en Flutter 3.29.2 y 3.47.6 con
  `equatable` 3.0.0 y con la versión mínima permitida, 2.0.5.

## Consecuencias

- Las aplicaciones con `equatable` 2.x siguen funcionando, y las que usan la 3.x
  ahora pueden resolver JIntent.
- Una aplicación que mezcla `EquatableMixin` en sus propias clases debe migrar ese
  código antes de pasar a `equatable` 3.x. Eso es independiente de JIntent.
- La igualdad de estado la define `equatable`. La prueba de regresión falla si una
  versión futura cambia cómo se comparan clases de estado distintas.
