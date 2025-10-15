# ADR-005: Manejo de Errores con Either

Status: Proposed  
Date: 2025-10-14  
Deciders: JIntent Maintainers (GenSoftMX)  
Supersedes: None  
Superseded by: None

---

## Contexto
La librería debe evitar control de flujo implícito por excepciones para fallos esperados. ADR-000 recomienda usar `Either<Exception, T>`.

## Decisión
- Estandarizar `Either<Exception, T>` como resultado de use cases y operaciones recuperables.
- Reservar excepciones para fallos inesperados (programming errors) o límites del sistema.
- Proveer helpers para map/flatMap y conversión a efectos/estados de error.

## Alternativas consideradas
- Excepciones en todo: difícil testeo y razonamiento; flujo implícito.
- Tipos Result ad-hoc: duplicación de conceptos y menor adopción en Dart.

## Consecuencias
- Errores esperados explícitos y componibles.
- Menos sorpresas en producción y mejor cobertura en tests.
- Curva de adopción para equipos no familiarizados con Either.

## Referencias
- docs/adr/ADR-000-context-and-high-level-decisions.md
