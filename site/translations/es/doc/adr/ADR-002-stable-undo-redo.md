# ADR-002: Undo/redo opcional y estable

**Estado:** Aceptado para la 3.0.0

**Fecha:** 2026-10-16

**Se relaciona con:** ADR-000 (D3, D7, D9, D12) y ADR-001 (D16).

## Decisión

Promover el historial de instantáneas y de comandos al punto de entrada opcional y
estable `package:jintent/undo_redo.dart`, según lo autorizó el mantenedor.
Conservar `experimental.dart` como exportación de compatibilidad; la
implementación pasa a `lib/src/undo_redo/`. El punto de entrada del núcleo sigue
enfocado.

El mixin del controlador expone un `JUndoHistoryState` inmutable mediante un
listenable de solo lectura. Los metadatos del historial están separados del estado
de dominio, de modo que vaciar o deshabilitar el historial puede notificar a la UI
sin inventar un cambio de dominio ni duplicar banderas en el estado de cada
aplicación. El controlador es dueño de la liberación del notifier.

El undo/redo de instantáneas usa las actualizaciones del controlador y la
observación global de estado. Sus métodos síncronos no se encolan a sí mismos: los
consumidores que necesiten orden respecto de ediciones asíncronas los llaman dentro
de un intent despachado de forma secuencial. Los intents cancelados y los
controladores liberados no pueden modificar el historial. Las capacidades
positivas, las instantáneas inmutables y los comandos puros son contratos
explícitos.

## Consecuencias y verificación

Los nombres de tipos y métodos existentes siguen disponibles. Las capacidades
inválidas ahora lanzan. Las operaciones tras la liberación pasan a no hacer nada y
los cambios de estado de undo/redo pasan a ser visibles para los observadores. Los
consumidores deben suscribirse a los metadatos del historial para los cambios que
solo afectan al historial. No se añade persistencia, compensación remota ni
serialización automática de intents.

La [guía](../undo-redo.md) especifica el comportamiento y la migración. Las suites
de contrato y de regresión están en `test/src/undo_redo/`; el ejemplo de notas
cubre el controlador y la UI reactiva. Los resultados de las pruebas se reportan
cuando se ejecutan estas comprobaciones, no se dan por supuestos por el estado
aceptado de este registro.
