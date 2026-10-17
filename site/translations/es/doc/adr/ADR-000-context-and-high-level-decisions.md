# ADR-000: Contexto y decisiones de alto nivel

**Estado:** Aceptado  
**Fecha:** 2025-10-15 (condensado el 2026-10-16)

Este registro recoge el contexto base de JIntent y sus decisiones de alto nivel.
Se condensó respecto de su forma original: se eliminaron la hoja de ruta por
fases, los objetivos numéricos, el proceso de gobernanza y las preguntas abiertas
porque se referían a un proceso descartado o a cifras no verificadas. Consulta el
código, las pruebas y `pubspec.yaml` para conocer el comportamiento y las
versiones actuales. Un cambio de decisión requiere un registro nuevo que
reemplace a este.

## Contexto

JIntent es un paquete de Flutter que aplica un patrón Intent de inspiración MVI a
la gestión de estado. Aborda la mezcla de lógica de UI y de negocio, los efectos
secundarios duplicados (navegación, diálogos), las transiciones difíciles de
probar, las condiciones de carrera en las actualizaciones de estado y los errores
por mutación de estado. Está dirigido a desarrolladores de Flutter de nivel
intermedio a avanzado que conocen MVI, Redux o BLoC, en aplicaciones de cualquier
tamaño.

**Fuera de alcance.** JIntent no ofrece un cliente HTTP, una capa de
persistencia, un contenedor de inyección de dependencias, un framework de
navegación, una librería de validación de formularios ni lógica de negocio. Esto
mantiene la librería enfocada y deja las decisiones a los consumidores.

## Principios

1. **Simplicidad sobre exhaustividad:** primitivas mínimas (`JState`, `JIntent`,
   `JController`), no un framework.
2. **Explícito sobre implícito:** los cambios de estado y los efectos secundarios
   son explícitos (`controller.intent(LoginIntent())`).
3. **Inmutabilidad primero:** los estados son inmutables y se actualizan con
   `copyWith`.
4. **Seguridad de tipos:** los tipos del núcleo son genéricos
   (`JController<CounterState>`).
5. **Capacidad de prueba:** cada componente se puede probar de forma aislada.
6. **Dependencias mínimas:** solo paquetes esenciales y estables.
7. **Divulgación progresiva:** los casos simples siguen siendo simples; los
   complejos son posibles.
8. **Compatibilidad hacia atrás:** seguir el versionado semántico y ofrecer rutas
   de migración para los cambios incompatibles.

## Decisiones

| # | Decisión | Justificación |
| --- | --- | --- |
| D1 | Arquitectura de inspiración MVI | Flujo unidireccional y separación clara; más simple que el código repetitivo de Redux o BLoC |
| D2 | Capas: Núcleo (estado, intent, controlador, effect) → Dominio (casos de uso, `Either`, mappers) → Presentación (UI del consumidor) | Límites claros, lógica de dominio reutilizable |
| D3 | Sistema de tipos genéricos estricto | Seguridad en tiempo de compilación, a costa de algo de verbosidad |
| D4 | `Either<Exception, T>` para los errores de dominio esperados | Manejo de errores explícito que obliga a considerarlos |
| D5 | Los efectos secundarios viajan por un stream broadcast separado, no en el estado | Mantiene el estado puro; los eventos únicos quedan desacoplados de la UI |
| D6 | Los intents se procesan de forma secuencial (FIFO) | Evita condiciones de carrera y da transiciones predecibles, con algo de retraso por la cola |
| D7 | `JController` se construye sobre `StateNotifier` | Base reactiva probada, compatible con Riverpod |
| D8 | Sin inyección de dependencias incorporada (`get_it` se eliminó en 2.0.0) | Menos acoplamiento; los consumidores eligen su propia DI |
| D9 | Hooks de `JObserver` para observar estado y effects | Extensibilidad opcional para registro, analítica y depuración |
| D10 | Distribución mediante pub.dev | Canal estándar y resolución de dependencias |
| D11 | Licencia MIT | Permisiva y ampliamente adoptada |
| D12 | Versionado semántico | Comunica con claridad los cambios incompatibles |
| D13 | Requiere el SDK de Flutter (restricciones de SDK en `pubspec.yaml`) | `StateNotifier` y el público objetivo dependen de Flutter |
| D14 | Ejemplo ejecutable del contador en `example/` | Aprendizaje con ejemplos y cobertura de integración |
| D15 | Registrar las decisiones arquitectónicas como ADR | Transparencia y contexto histórico |
