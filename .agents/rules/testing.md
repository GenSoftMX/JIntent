# Verificación

- Documentación: revisar contenido, rutas y `git diff --check`; no requiere
  ejecutar Flutter si no cambia código ni configuración.
- Código: ejecutar `dart format --output=none --set-exit-if-changed` sobre los
  archivos afectados, `flutter analyze` y pruebas relevantes con `flutter test`.
- Bugs de lógica: agregar regresión que reproduzca el fallo y compruebe el
  resultado esperado. Para async, cubrir errores y ciclo de vida relevantes;
  preferir sincronización determinista frente a esperas arbitrarias.
- Antes de entregar cambios de biblioteca, ejecutar `flutter test --coverage`.
  CI actualmente verifica formato del repositorio, análisis, tests y umbral
  global del 80%; comprobar `.github/workflows/ci.yml` si cambia.
- El análisis raíz excluye `example/**`. Un resultado raíz no prueba que el
  ejemplo compile o que una plataforma nativa funcione. Validar aparte si aplica.
- No alterar pruebas ni reducir gates para esconder fallos. Distinguir fallos
  previos de los introducidos; no repararlos fuera de alcance.
- Si falta SDK, dependencia o servicio, reportar el bloqueo y los comandos no
  ejecutados; no instalar ni actualizar herramientas globales sin autorización.
- Ante fallos: diagnosticar, reparar dentro del alcance y volver a verificar.
  Tras tres intentos sin resolver la misma causa, reportar evidencia y pedir
  la decisión o información necesaria; no repetir indefinidamente.
- No afirmar cobertura, compatibilidad ni éxito de CI sin evidencia de ejecución.
