# Trabajo agéntico en JIntent

JIntent es una biblioteca Flutter de intents, estado y efectos. Este archivo es
el punto de entrada; cargar únicamente los recursos necesarios para la tarea.

## Estructura
- `lib/jintent.dart`: entrada pública y exports.
- `lib/src/`: core, domain, devtools, navigation, utils y experimental.
- `test/`: pruebas de la biblioteca; `example/`: aplicación consumidora.
- `doc/adr/`: decisiones con estado explícito; comprobar vigencia contra código.

## Cómo debe trabajar el agente
1. Determinar alcance antes de implementar, proporcional al riesgo. Si se pide
   análisis, no editar hasta recibir una solicitud de implementación.
2. Descubrir, evaluar y seleccionar contexto por relevancia, autoridad y vigencia.
3. Leer las reglas aplicables en `.agents/rules/`; consultar Knowledge bajo demanda.
4. Ejecutar dentro del alcance siguiendo el [flujo de tarea](.agents/workflows/task.md).
5. Verificar antes de dar por terminado y distinguir aprobado, fallido y no ejecutado.
6. Reportar fuentes utilizadas, archivos cambiados, validación y pendientes.
7. No ampliar el alcance sin autorización explícita. Reutilizar autorizaciones ya dadas.
8. Cambios de arquitectura, seguridad, infraestructura o dependencias críticas
   requieren alcance y plan autorizados antes de ejecutarse.

## Fuentes canónicas
- [Arquitectura](.agents/rules/architecture.md), [estilo](.agents/rules/code-style.md),
  [pruebas](.agents/rules/testing.md), [Git y seguridad](.agents/rules/git.md).
- [Mapa del sistema](.agents/knowledge/system-overview.md).
- [Flujo de tarea](.agents/workflows/task.md).
- Plantillas de [alcance](.agents/templates/request-scope.md) y
  [handoff](.agents/templates/handoff.md).
- [Adopción y extensiones futuras](.agents/README.md).

## Validación básica
Para código Dart: formato, `flutter analyze` y pruebas según las reglas de testing.
Para documentación: revisar referencias, alcance y `git diff --check`.
La configuración ejecutable de CI está en `.github/workflows/ci.yml`.
