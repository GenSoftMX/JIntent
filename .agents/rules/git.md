# Git y seguridad

- Revisar estado y diff antes de editar; preservar cambios existentes del usuario.
- No descartar archivos, reescribir historia ni ejecutar limpieza destructiva sin
  autorización explícita. No incluir archivos ajenos al objetivo en commits.
- Crear commits, publicar, hacer push o abrir PR cuando lo solicite el usuario o
  forme parte del alcance autorizado; no publicar una versión por inferencia.
- No introducir secretos, credenciales, datos privados ni rutas personales en
  documentación portable. Evitar exponerlos en logs o salidas de herramientas.
- Cambios a CI, permisos, seguridad o dependencias críticas requieren autorización
  que cubra ese impacto. No volver a solicitar una autorización ya otorgada.
