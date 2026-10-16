# Estilo Dart

- Seguir `analysis_options.yaml`, el formato de Dart y las convenciones cercanas.
- Mantener tipos explícitos en contratos públicos; evitar `dynamic` y casts que
  oculten errores de null safety o genéricos.
- Conservar nombres y documentación pública en el idioma del código existente.
- No mezclar reformateos masivos, renombrados o archivos generados con cambios
  funcionales ajenos. No introducir dependencias sin necesidad del alcance.
- Al cambiar código asíncrono, definir quién espera, captura errores y libera
  recursos. Documentar las limitaciones que formen parte del contrato.
