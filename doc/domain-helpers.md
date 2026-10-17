# Domain helpers

JIntent supplies use-case, `Either` and mapper helpers. Repositories,
persistence, networking and caching are owned by the consuming application. The
counter example's layering ([DTO](../example/lib/src/data/models/counter_dto.dart),
[mapper](../example/lib/src/data/mappers/counter_mapper.dart),
[repository](../example/lib/src/data/repositories/counter_repository.dart),
[use cases](../example/lib/src/domain/use_cases/)) is optional. Keep
storage-specific types outside UI state and convert expected failures at the
operation boundary.

`Either` is sealed, so a `switch` over it is checked for exhaustiveness:

```dart
final text = switch (result) {
  Left(:final value) => 'Failed: $value',
  Right(:final value) => 'Got $value',
};
```

`Left` and `Right` compare by value and exact runtime type (type arguments
included), so equality is symmetric.

## Validation

`JUseCase<INPUT, OUTPUT>` and `JSyncUseCase<INPUT, OUTPUT>` accept validators
through `addValidator`. Each `UseCaseInputValidator<I>` returns
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

Call the use case through `call` (or function-call syntax) to run validation.
Calling `run` directly bypasses validators. Validators execute synchronously in
registration order and stop at the first `Left`. Successful validator values
are not passed to later validators or `run`: all receive the original input.
Thrown exceptions are not converted to `Left`. Validators are operation
preconditions, not a replacement for server-side authorization.

`JUseCaseVoid` exposes only `run`; it has no built-in validator chain.
`JValidationUtils` (from `package:jintent/utils.dart`) offers parsing defaults
and range checks, not a general validation framework. See the example's
[validators](../example/lib/src/domain/validators/common_validators.dart) and
[tests](../example/test/src/domain/).

## Mappers

`JMapper<INPUT, OUTPUT>` implements `IMapper` through a single `map` override:

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

- `transform` converts one input; `transformList` returns a new output list.
- `transformDynamic` accepts `INPUT` or `List<INPUT>` and throws `ArgumentError`
  for other types. Prefer the typed methods when possible.
- `IBiMapper<A, B>` defines `to(A)` and `from(B)` for explicit two-way mapping.
  Implement and test both directions; invertibility is not enforced.

See the [counter mapper](../example/lib/src/data/mappers/counter_mapper.dart)
and its [tests](../example/test/src/data/mappers/counter_mapper_test.dart).
