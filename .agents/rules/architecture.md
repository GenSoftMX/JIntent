# Arquitectura

Aplica a cambios de biblioteca y contratos públicos.

- Revisar `lib/jintent.dart` y los barrels afectados antes de cambiar una API;
  identificar consumidores y pruebas. No eliminar ni cambiar firmas o semántica
  pública sin autorización para el impacto de compatibilidad.
- Mantener la separación intent / controller / state / effect. No incorporar
  infraestructura del ejemplo ni servicios específicos de una app al núcleo.
- Conservar estados inmutables y `props` coherentes con los datos de estado.
- Cambios de orden de intents, concurrencia, disposal o resultados de efectos
  deben definir antes el comportamiento esperado y los casos de error.
- Revisar el estado de cada ADR. No tratar propuestas como decisiones aceptadas
  ni corregir silenciosamente discrepancias entre documentación y ejecución.
- `example/` es consumidor: modificarlo cuando el alcance o un cambio de contrato
  lo requiera; no convertir su arquitectura en requisito para toda la biblioteca.
