# Flujo de tarea

1. Revisar solicitud y estado Git. Distinguir análisis de implementación.
2. Definir objetivo, límites y criterio de éxito. Para documentación menor basta
   un alcance breve; para cambios funcionales usar los campos de la plantilla
   de alcance, en la conversación o un archivo si aporta valor.
3. Para arquitectura, seguridad, infraestructura, dependencias críticas o refactor
   transversal: presentar alcance, plan e impacto y comprobar autorización antes
   de implementar. Resolver decisiones faltantes sin repetir aprobaciones válidas.
4. Descubrir fuentes cercanas: instrucciones aplicables, código, tests y contratos.
   Evaluar relevancia, autoridad y vigencia; leer reglas del dominio afectado.
   Cargar Knowledge o ADR únicamente para una pregunta concreta.
5. Ejecutar el cambio mínimo autorizado. Si se necesita ampliar alcance, informar
   la causa y obtener autorización antes de realizar esa ampliación.
6. Aplicar las reglas de testing. Si falla, diagnosticar antes de reparar y acotar
   los intentos. Distinguir verificación estática, ejecución y evidencia nativa.
7. Revisar diff final y cerrar con resultado, contexto clave usado, archivos,
   validaciones ejecutadas, bloqueos y riesgos pendientes. No inventar métricas.
8. Si queda trabajo para otra sesión, usar la plantilla de handoff con el mínimo
   contexto necesario y un siguiente paso concreto.

Dependencias: `../rules/architecture.md`, `../rules/code-style.md`,
`../rules/testing.md`, `../rules/git.md`, según alcance.
