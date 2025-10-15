# ADR-003: Abstracción de Use Cases (JUseCase/JSyncUseCase)

Status: Proposed  
Date: 2025-10-14  
Deciders: JIntent Maintainers (GenSoftMX)  
Supersedes: None  
Superseded by: None

---

## Contexto
Se requiere encapsular la lógica de negocio fuera del controlador para respetar SRP, mejorar testabilidad y permitir composición. ADR-000 propone `JUseCase` como punto central.

## Decisión
- Definir `JUseCase<In, Out>` asíncrono que retorna `Future<Either<Exception, Out>>`.
- Definir `JSyncUseCase<In, Out>` para operaciones puras sin I/O.
- Los controladores orquestan intents y delegan todo cálculo relevante a use cases.

## Alternativas consideradas
- Lógica de negocio en el controlador: incrementa complejidad y dificulta pruebas.
- Servicios estáticos/globales: acoplamiento y difícil sustitución en tests.
- Patrón Repository directo desde UI: viola separación de responsabilidades.

## Consecuencias
- Lógica de negocio modular y testeable en aislamiento.
- Inyección de dependencias más clara (desde app/framework, no desde la librería).
- Requiere definir contratos claros por caso de uso (inputs/outputs tipados).

## Referencias
- docs/adr/ADR-000-context-and-high-level-decisions.md
