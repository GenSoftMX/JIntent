# Helpers de dominio

JIntent aporta helpers de casos de uso, `Either` y mappers. Los repositorios, la
persistencia, la red y el caché son responsabilidad de la aplicación que consume
la librería. La organización en capas del ejemplo del contador
([DTO](../example/lib/src/data/models/counter_dto.dart),
[mapper](../example/lib/src/data/mappers/counter_mapper.dart),
[repositorio](../example/lib/src/data/repositories/counter_repository.dart),
[casos de uso](../example/lib/src/domain/use_cases/)) es opcional. Mantén los
tipos específicos del almacenamiento fuera del estado de la UI y convierte los
fallos esperados en el límite de la operación.

`Either` es sellado (`sealed`), por lo que un `switch` sobre él se comprueba por
exhaustividad:

```dart
final text = switch (result) {
  Left(:final value) => 'Failed: $value',
  Right(:final value) => 'Got $value',
};
```

`Left` y `Right` se comparan por valor y por tipo exacto en tiempo de ejecución
(incluidos los argumentos de tipo), de modo que la igualdad es simétrica.

## Validación

`JUseCase<INPUT, OUTPUT>` y `JSyncUseCase<INPUT, OUTPUT>` aceptan validadores
mediante `addValidator`. Cada `UseCaseInputValidator<I>` devuelve
`Either<Exception, I>`.

```dart
class PositiveCounter extends JSyncUseCase<int, int> {
  PositiveCounter() {
    addValidator((value) => value < 0
        ? Left(Exception('Counter must be non-negative'))
        : Right(value));
  }

  @override
  Either<Exception, int> run(int input) => Right(input);
}

final result = PositiveCounter().call(3);
```

Llama al caso de uso mediante `call` (o con la sintaxis de llamada a función) para
ejecutar la validación. Llamar a `run` directamente omite los validadores. Los
validadores se ejecutan de forma síncrona en orden de registro y se detienen en el
primer `Left`. Los valores de los validadores exitosos no se pasan a los
siguientes ni a `run`: todos reciben la entrada original. Las excepciones lanzadas
no se convierten en `Left`. Los validadores son precondiciones de la operación, no
un sustituto de la autorización en el servidor.

`JUseCaseVoid` expone solo `run`; no tiene una cadena de validadores incorporada.
`JValidationUtils` (de `package:jintent/utils.dart`) ofrece valores
predeterminados de análisis y comprobaciones de rango, no un framework general de
validación. Consulta los
[validadores](../example/lib/src/domain/validators/common_validators.dart) del
ejemplo y sus [pruebas](../example/test/src/domain/).

## Mappers

`JMapper<INPUT, OUTPUT>` implementa `IMapper` mediante una única sobrescritura de
`map`:

```dart
class CountLabelMapper extends JMapper<int, String> {
  @override
  String map(int value) => 'Count: $value';
}

final mapper = CountLabelMapper();
final label = mapper.transform(2);
final labels = mapper.transformList([1, 2]);
final sameLabels = [1, 2].mapWith(mapper);
```

- `transform` convierte una entrada; `transformList` devuelve una lista de salida
  nueva.
- `transformDynamic` acepta `INPUT` o `List<INPUT>` y lanza `ArgumentError` para
  otros tipos. Prefiere los métodos tipados cuando sea posible.
- `IBiMapper<A, B>` define `to(A)` y `from(B)` para un mapeo explícito en ambos
  sentidos. Implementa y prueba ambas direcciones; la invertibilidad no se
  impone.

Consulta el [mapper del contador](../example/lib/src/data/mappers/counter_mapper.dart)
y sus [pruebas](../example/test/src/data/mappers/counter_mapper_test.dart).
