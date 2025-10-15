# ADR-007: Hooks de Observabilidad y DevTools (JObserver)

Status: Proposed  
Date: 2025-10-14  
Deciders: JIntent Maintainers (GenSoftMX)  
Supersedes: None  
Superseded by: None

---

## Contexto
Se requiere instrumentación opcional para depuración, métricas y analytics sin impactar performance cuando no se usa.

## Decisión
- Establecer interfaz `JObserver` para observar cambios de estado, intents y efectos.
- No registrar ningún observer por defecto; costo cero cuando está deshabilitado.
- Permitir múltiples observers (logging, métricas, tracing) mediante composición.

## Alternativas consideradas
- Logging directo en el controlador: ruido y acoplamiento a una implementación.
- Integración fija con un proveedor de APM: restringe a los usuarios de la librería.

## Consecuencias
- Fácil integración con herramientas existentes sin afectar el core.
- Mejores diagnósticos en producción y desarrollo.
- Requiere guías para evitar PII en logs/telemetría.

## Referencias
- docs/adr/ADR-000-context-and-high-level-decisions.md
