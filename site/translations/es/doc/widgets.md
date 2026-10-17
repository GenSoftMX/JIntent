# Consumir el estado del controlador en Flutter

Importa el punto de entrada opcional de widgets:

```dart
import 'package:jintent/widgets.dart';
```

Estos widgets funcionan directamente con `JController`; un paquete de providers
es opcional. No crean ni liberan controladores. Quien los llama es dueño del
controlador y debe mantenerlo vivo mientras el widget lo usa.

## Construir a partir de un estado

Dado un `CounterController` con un campo `CounterState.count`:

```dart
JControllerBuilder<CounterState>(
  controller: controller,
  builder: (context, state) => Text('${state.count}'),
)
```

El estado inicial está disponible en la primera construcción. Las notificaciones
de estado posteriores programan una reconstrucción; varios cambios antes de un
frame de Flutter pueden fusionarse. Es una vista del estado actual, no un
registro de cada transición. Usa `JStateRecorder` del
[punto de entrada de pruebas](testing.md) para registrar las transiciones.

## Seleccionar un valor

```dart
JControllerSelector<CounterState, int>(
  controller: controller,
  selector: (state) => state.count,
  builder: (context, count) => Text('$count'),
)
```

Ante las notificaciones del controlador, el selector se reconstruye solo cuando
el valor seleccionado difiere según `==`. Actualizar un campo no relacionado no
reconstruye ese builder. Las reconstrucciones del padre o de widgets heredados
siguen funcionando con normalidad. Selecciona valores inmutables con una igualdad
significativa; modificar en el lugar una lista seleccionada no está soportado.

Reemplazar el controlador desconecta el listener anterior y usa el nuevo estado
de inmediato. Reemplazar el selector recalcula la selección, incluso sin una
notificación de estado. Quitar el widget desconecta su listener sin liberar el
controlador.

## Mantén los effects fuera de los builders

Usa `JEffectListener` para diálogos, navegación y retroalimentación. Los builders
y selectors pueden ejecutarse repetidamente y no deben realizar efectos
secundarios únicos.

Que un effect esperado venza por timeout no descarta automáticamente su UI. La
política de esa UI le corresponde al consumidor. El
[helper de diálogo del ejemplo](../example/lib/src/demos/shared/effect_dialog.dart)
vincula la ruta de un diálogo con el resultado de su effect: elimina únicamente
esa ruta cuando el effect termina externamente y deja intactas las rutas más
nuevas. Consulta [effects](effects.md) para los contratos subyacentes de timeout
y liberación.
