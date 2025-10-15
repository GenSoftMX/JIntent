# ADR-006: Patrón Mapper (JMapper/IBiMapper)

Status: Proposed  
Date: 2025-10-14  
Deciders: JIntent Maintainers (GenSoftMX)  
Supersedes: None  
Superseded by: None

---

## Contexto
Las transformaciones entre capas (DTO ↔ Domain ↔ State) deben ser tipadas y reutilizables para evitar lógica difusa en controladores o UI.

## Decisión
- Definir interfaces `JMapper<A, B>` y `IBiMapper<A, B>` para conversiones unidireccionales y bidireccionales.
- Ubicar mappers en capa de dominio o data según corresponda; no en UI ni controlador.
- Proveer ejemplos en documentación y tests para casos comunes.

## Alternativas consideradas
- Transformaciones inline en UI/controladores: acoplamiento y duplicación.
- Extensiones utilitarias ad-hoc: difícil de testear y mantener.

## Consecuencias
- Separación clara de responsabilidades y mayor reutilización.
- Mejor testabilidad de conversiones complejas.
- Posible incremento de archivos, mitigado con convención de nombres.

## Referencias
- docs/adr/ADR-000-context-and-high-level-decisions.md
