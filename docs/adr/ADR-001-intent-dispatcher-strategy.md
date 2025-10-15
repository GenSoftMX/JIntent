# ADR-001: Estrategia de Dispatcher de Intents

Status: Proposed  
Date: 2025-10-14  
Deciders: JIntent Maintainers (GenSoftMX)  
Supersedes: None  
Superseded by: None

---

## Contexto
ADR-000 define que los intents deben procesarse de forma secuencial por defecto para evitar condiciones de carrera y preservar el orden de las transiciones de estado. Para la siguiente fase de diseño necesitamos fijar el contrato del Dispatcher y la estrategia de concurrencia opcional.

## Decisión
- Mantener el procesamiento SECUENCIAL por defecto mediante `JSequentialIntentDispatcher`.
- Proveer un punto de extensión `JIntentDispatcher` que permita implementar estrategias alternativas (concurrente, con prioridad, etc.).
- Documentar cómo las apps pueden inyectar un dispatcher alternativo bajo su propio riesgo.

### Contrato (resumen)
- `dispatch(Intent i, Future<State> Function() work)` encola el trabajo y garantiza orden FIFO.
- Cancelación limitada: intents en cola pueden descartarse si el controlador se cierra.
- Telemetría de cola opcional vía `JObserver`.

## Alternativas consideradas
- Procesamiento concurrente por defecto: mayor throughput pero introduce condiciones de carrera y orden no determinista.
- Lock por sección crítica dentro del controlador: complejo, propenso a deadlocks y fugas.
- Sin dispatcher (llamadas directas): difícil de razonar y de instrumentar.

## Consecuencias
- Simplicidad y previsibilidad por defecto; ejecución determinista de intents.
- Posible latencia cuando un intent es lento: se recomienda offload a use cases asíncronos.
- Flexibilidad: proyectos con necesidades especiales pueden reemplazar el dispatcher.

## Referencias
- docs/adr/ADR-000-context-and-high-level-decisions.md
