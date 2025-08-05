/// Generic interface for mapping objects of type [INPUT] to [OUTPUT].
abstract class IMapper<INPUT, OUTPUT> {
  /// Transforms a single [INPUT] entity into an [OUTPUT] object.
  OUTPUT transform(INPUT entity);

  /// Transforms a list of [INPUT] entities into a list of [OUTPUT] objects.
  List<OUTPUT> transformList(List<INPUT> array);

  /// Dynamically transforms either a single [INPUT] or a list of [INPUT]
  /// into its corresponding [OUTPUT] or [List<OUTPUT>].
  ///
  /// Throws [ArgumentError] if the input type is unsupported.
  dynamic transformDynamic(dynamic entityOrArray);
}

/// Base abstract class implementing [IMapper] to simplify concrete mappers.
///
/// Implementers only need to override [map] to define how to transform a single [INPUT]
/// to [OUTPUT]. Other transformation methods are implemented here.
abstract class JMapper<INPUT, OUTPUT> implements IMapper<INPUT, OUTPUT> {
  OUTPUT map(INPUT entity);

  @override
  OUTPUT transform(INPUT entity) => map(entity);

  @override
  List<OUTPUT> transformList(List<INPUT> array) => array.map(map).toList();

  @override
  dynamic transformDynamic(dynamic entityOrArray) {
    if (entityOrArray is List<INPUT>) {
      return transformList(entityOrArray);
    } else if (entityOrArray is INPUT) {
      return transform(entityOrArray);
    } else {
      throw ArgumentError('Unsupported type');
    }
  }
}

/// Extension on [List] providing a convenient method to map elements
/// with a [JMapper].
extension MapWithExtension<T> on List<T> {
  /// Maps the list elements using the provided [mapper].
  ///
  /// Returns a new list with the mapped elements of type [R].
  List<R> mapWith<R>(JMapper<T, R> mapper) => mapper.transformList(this);
}

/// Interface defining a bidirectional mapper between types [A] and [B].
abstract class IBiMapper<A, B> {
  /// Maps an instance of [A] to [B].
  B to(A input);

  /// Maps an instance of [B] back to [A].
  A from(B output);
}
