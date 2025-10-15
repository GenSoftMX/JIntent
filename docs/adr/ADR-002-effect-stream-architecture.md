# ADR-002: Arquitectura de Stream de Efectos

Status: Proposed  
Date: 2025-10-14  
Deciders: JIntent Maintainers (GenSoftMX)  
Supersedes: None  
Superseded by: None

---

## Contexto
ADR-000 establece que los efectos (navegación, diálogos, toasts) no deben residir en el estado persistente. Se requiere un mecanismo explícito y observable para eventos de una sola vez.

## Decisión
- Implementar un stream broadcast de efectos a nivel de controlador.
- Cada efecto puede opcionalmente llevar un `Completer<T>` para request/response.
- Soportar timeout configurable y estrategia para efectos no manejados (log, no-op, throw en debug).
- Clasificar efectos por tipo/categoría para facilitar filtros (UI, Analytics, ErrorReporting).

## Alternativas consideradas
- Guardar efectos en el estado: mezcla preocupaciones y rompe la inmutabilidad semántica.
- Callbacks directos en UI: acoplamiento fuerte y difícil observabilidad.
- EventBus global: aumenta acoplamiento y reduce trazabilidad.

## Consecuencias
- Efectos desacoplados del estado; mejor testabilidad y depuración.
- Requiere disciplina en listeners para evitar fugas (suscripción y cancelación).
- Facilita instrumentación (métricas y tracing) sin afectar la lógica de negocio.

## Referencias
- docs/adr/ADR-000-context-and-high-level-decisions.md
