# Undo y redo

Undo/redo es una API estable y opcional en la versión 3.0.0 aún sin publicar.
Impórtala junto a los tipos del núcleo:

```dart
import 'package:jintent/jintent.dart';
import 'package:jintent/undo_redo.dart';
```

Úsala para ediciones locales en notas, formularios o editores. Restaura
instantáneas de estado inmutable; no revierte una escritura en base de datos, una
petición HTTP, un diálogo ni otro efecto secundario. Persistir una edición y
compensar una operación externa siguen siendo responsabilidad de la aplicación.
El historial existe solo en memoria para un controlador.

## Controlador e intents

Mantén el estado, el controlador, los intents y la presentación en archivos
separados. Un estado mínimo podría ser:

```dart
class EditorState extends JState {
  const EditorState({this.text = ''});
  final String text;

  @override
  EditorState copyWith({String? text}) => EditorState(text: text ?? this.text);

  @override
  List<Object?> get props => [text];
}
```

El controlador habilita el historial y elige una capacidad positiva:

```dart
class EditorController extends JController<EditorState>
    with UndoRedoMixin<EditorState> {
  EditorController() : super(const EditorState());

  @override
  void onInit() => enableUndoRedo(maxHistorySize: 20);

  Future<void> replaceText(String text) => intent(ReplaceTextIntent(text));
}
```

Solo los cambios registrados explícitamente con `updateWithUndo` entran al
historial. `UndoableIntent` ofrece esa operación a los intents:

```dart
class ReplaceTextIntent extends UndoableIntent<EditorState> {
  ReplaceTextIntent(this.text);
  final String text;

  @override
  Future<void> onInvoke() async {
    performUndoableUpdate((state) => state.copyWith(text: text));
  }
}
```

Fuera de un intent, `controller.updateWithUndo(reducer)` registra el mismo tipo de
cambio. En un controlador sin `UndoRedoMixin`, `UndoableIntent` recurre a una
actualización normal y no ofrece historial.

Las instantáneas conservan referencias a los estados, no copias profundas. Usa
valores inmutables y copias defensivas o colecciones no modificables, incluidos
los valores anidados. Los reducers deben ser puros y devolver un estado nuevo;
nunca modifiques dentro de un reducer el estado actual, sus colecciones ni el
ciclo de vida del controlador. Incluye en `props` todos los datos del estado que
sean relevantes para la igualdad.

## Comportamiento del historial

| Operación | Contrato |
| --- | --- |
| Cambio registrado | Apila el estado anterior en undo, descarta la entrada más antigua al superar la capacidad y vacía redo. |
| Estado igual o reducer que lanza | Deja el historial intacto, incluida una rama de redo existente. |
| `undo()` / `redo()` | Devuelven `true` cuando se consume una instantánea y `false` si no hay ninguna. Los cambios reales de estado notifican a los listeners del controlador y a `JObserver.onStateChanged`. |
| Restauración de una instantánea igual | Puede consumir una instantánea sin emitir un cambio de estado de dominio; los metadatos del historial sí se actualizan. |
| `clearHistory()` | Vacía ambas pilas y notifica a los listeners del historial; conserva el estado de dominio actual y el estado de habilitación. |
| `disableUndoRedo()` | Vacía el historial, desactiva el registro y publica los metadatos. Las actualizaciones posteriores se comportan como actualizaciones normales. |
| `enableUndoRedo(maxHistorySize: n)` | Activa el registro. Exige una capacidad positiva; una entrada inválida lanza antes de cambiar el historial. Reducir la capacidad recorta las entradas más antiguas de ambas pilas. |
| `update()` normal | Cambia el estado de dominio sin registrar ni vaciar el historial. Vacía el historial explícitamente al reemplazar un documento o aceptar un estado remoto. |
| Cancelación / liberación | Los intents cancelados de este controlador no pueden cambiar su historial. Tras la liberación, las mutaciones del historial no hacen nada y undo/redo devuelven `false`. La liberación suelta las instantáneas y el notifier de metadatos. |

La disponibilidad de undo/redo y los tamaños de las pilas siguen disponibles como
getters del controlador. El máximo se aplica a cada pila; reducir el límite puede
descartar instantáneas. Los callbacks de listeners u observadores no son
operaciones transaccionales de la aplicación: las excepciones en código externo no
pueden deshacer un estado ya confirmado ni un efecto secundario externo.

## Observar el historial en la UI

El estado de dominio y los metadatos del historial son observables distintos.
`history` es un `ValueListenable<JUndoHistoryState>` de solo lectura con
`enabled`, `undoCount`, `redoCount`, `canUndo` y `canRedo`. Así se evita meter las
pilas en el estado de dominio o sincronizar a mano banderas duplicadas para los
botones.

Usa `JControllerBuilder` para el contenido del documento y escucha el historial
para los botones:

```dart
ValueListenableBuilder<JUndoHistoryState>(
  valueListenable: controller.history,
  builder: (context, history, child) => IconButton(
    onPressed: history.canUndo ? () => controller.undo() : null,
    icon: const Icon(Icons.undo),
  ),
)
```

El ejemplo de widget requiere `package:flutter/material.dart`. Los metadatos se
publican después de que una operación actualiza el estado de dominio, y solo
cuando el valor de los metadatos cambia. Vaciar el historial actualiza por tanto
los botones aunque el documento no cambie. El controlador es dueño del notifier;
los consumidores solo se suscriben y se desuscriben. Mantén vivo el controlador
mientras sus widgets lo usan y libéralo cuando se elimine su dueño.

Consulta [Undo Notes](../example/lib/src/demos/undo_notes/): muestra cómo agregar,
eliminar, deshacer, rehacer y vaciar el historial sin borrar notas.

## Orden con trabajo asíncrono

Las llamadas directas a undo/redo son síncronas y no entran en la cola de un
dispatcher. No cancelan un guardado pendiente ni otro intent. Para serializar
undo con otras ediciones, invócalo dentro de un intent personalizado y usa un
dispatcher secuencial:

```dart
class UndoEditIntent extends JIntent<EditorState> {
  @override
  Future<void> onInvoke() async {
    (controller as EditorController).undo();
  }
}

// Dispatch from the UI; do not recursively await it inside the same queue.
await controller.intent(UndoEditIntent());
```

Ese cambio de estado se atribuye al intent en ejecución según el observador. Los
dispatchers concurrente, droppable y restartable conservan sus contratos normales;
el historial no añade serialización. Consulta [concurrencia](concurrency.md).

## Comandos como alternativa

`CommandHistory<T>` almacena objetos `UndoableCommand<T>` síncronos en lugar de
instantáneas de estado. Úsalo cuando cada operación necesite su propia inversa:

```dart
class AppendCommand extends UndoableCommand<EditorState> {
  AppendCommand(this.suffix);
  final String suffix;

  @override
  EditorState execute(EditorState state) =>
      state.copyWith(text: '${state.text}$suffix');

  @override
  EditorState undo(EditorState state) =>
      state.copyWith(text: state.text.substring(0, state.text.length - suffix.length));
}

final history = CommandHistory<EditorState>(maxSize: 20);
var state = history.execute(const EditorState(), AppendCommand('hello'));
state = history.undo(state) ?? state;
state = history.redo(state) ?? state;
```

Es una alternativa, no un segundo historial que se acople a las mismas ediciones.
Su capacidad positiva se valida en el constructor. `execute` confirma un comando
solo cuando el estado devuelto es distinto. Los resultados iguales y los comandos
que lanzan conservan las pilas; undo y redo mueven un comando solo después de que
su método tenga éxito. Un undo o redo vacío devuelve `null`. El redo
predeterminado de un comando vuelve a ejecutarlo.

Los comandos deben ser puros y trabajar con estado inmutable; las mutaciones del
objeto comando o los efectos externos no pueden revertirse ante un fallo.
`CommandHistory` no tiene controlador, notifier, persistencia ni ciclo de vida de
liberación. Su dueño debe aplicar los estados devueltos, publicar sus propios
metadatos de UI y llamar a `clear()` al cambiar de documento. No modifiques el
documento por otra vía mientras conserves comandos cuyas inversas dependan de su
contenido.

## Migración desde experimental

Reemplaza `package:jintent/experimental.dart` por
`package:jintent/undo_redo.dart`. El primero sigue siendo una exportación de
compatibilidad heredada de la misma implementación; los ejemplos y pruebas activos
usan el punto de entrada estable. Las exportaciones internas de `src/experimental`
son capas de compatibilidad, no implementaciones.

Los nombres de clases y métodos existentes siguen disponibles. Las capacidades
iguales o menores que cero ahora lanzan, y las operaciones de historial de
intents cancelados o de controladores liberados ya no modifican las pilas. Undo y
redo ahora reportan los cambios reales al observador global. Migra el código de UI
que lee los getters de disponibilidad del controlador para que escuche `history`
cuando además deba reaccionar a las operaciones de vaciar, habilitar o
deshabilitar.
