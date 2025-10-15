# ADR-004: Estado Inmutable y Patrón copyWith

Status: Proposed  
Date: 2025-10-14  
Deciders: JIntent Maintainers (GenSoftMX)  
Supersedes: None  
Superseded by: None

---

## Contexto
Para garantizar cambios de estado predecibles y eficientes, los modelos de estado deben ser inmutables y comparables por valor.

## Decisión
- Todas las clases de estado son inmutables y exponen `copyWith(...)`.
- Adoptar `Equatable` (o similar) para igualdad estructural.
- Proveer base `JState` que estandarice equals/hash y facilite snapshots.

## Alternativas consideradas
- Estado mutable: más simple al inicio pero propenso a errores y efectos colaterales.
- Clonado manual sin patrón: repetitivo y menos consistente.

## Consecuencias
- Cambios de estado explícitos y trazables.
- Mejor desempeño en reconstrucciones al detectar deltas.
- Requiere disciplina en modelos complejos (nested copies).

## Referencias
- docs/adr/ADR-000-context-and-high-level-decisions.md
