import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:jintent/src/core/dispatchers/sequential_intent_dispatcher.dart';
import 'package:jintent/src/core/effects/jeffect.dart';
import 'package:jintent/src/core/effects/jeffect_config.dart';
import 'package:jintent/src/core/jintent.dart';
import 'package:jintent/src/devtools/jobserver.dart';
import 'package:jintent/src/core/jstate.dart';
import 'package:jintent/src/extensions/logging_dispatcher.dart';
import 'package:state_notifier/state_notifier.dart';

/// Base controller for managing state and side effects in a reactive architecture.
///
/// Extends [StateNotifier<T>] to provide controlled state updates and exposes
/// a [sideEffects] stream for one-time UI events.
///
/// Use [intent] to dispatch intents which encapsulate business logic,
/// [update] to safely mutate the state using reducers,
/// and [emitSideEffect] or [emitAndWaitSideEffect] for UI events like dialogs or navigation.
///
/// Implements lifecycle hook [onInit] for initialization logic.
///
/// Tracks state changes and side effects via [JObserver] for debugging and tooling.
abstract class JController<T extends JState> extends StateNotifier<T> {
  /// Dispatcher responsible for handling the execution of [JIntent]s.
  ///
  /// This field holds an instance of [JIntentDispatcher], which abstracts
  /// how intents are dispatched and executed. By default, it uses
  /// [JSequentialIntentDispatcher], but can be replaced with a custom
  /// implementation (e.g., for logging or analytics).
  ///
  /// It allows decoupling the dispatching mechanism from the controller logic.
  final JIntentDispatcher _dispatcher;

  /// Stream of side effects emitted by the controller.
  ///
  /// UI layers can subscribe to this stream to react to one-time effects,
  /// such as navigation, dialogs, snackbars, etc.
  late final _sideEffectController = StreamController<JEffect>.broadcast(
    onListen: () => scheduleMicrotask(_deliverBufferedEffects),
  );
  final _pendingEffects = Set<JEffect>.identity();
  final _bufferedEffects = Queue<JEffect>();
  final int _effectBufferSize;

  /// A broadcast stream of side effects emitted by the controller.
  Stream<JEffect> get sideEffects => _sideEffectController.stream;

  /// Returns the current state of type [T].
  T get currentState => state;

  /// Creates a new [JController] with the given initial state.
  ///
  /// Calls [onInit] synchronously from this base constructor. Overrides must
  /// not rely on fields initialized later by a subclass constructor body.
  ///
  /// By default effects emitted while nobody listens to [sideEffects] are
  /// dropped (fire-and-forget) or failed (awaitable). Set [effectBufferSize] to
  /// a positive value to retain up to that many effects until a listener
  /// attaches; see [emitSideEffect].
  JController(
    super.initialState, {
    JIntentDispatcher? dispatcher,
    int effectBufferSize = 0,
  }) : assert(effectBufferSize >= 0, 'effectBufferSize must not be negative'),
       _dispatcher = dispatcher ?? JSequentialIntentDispatcher(),
       _effectBufferSize = effectBufferSize {
    onInit();
  }

  /// Initialization lifecycle method.
  ///
  /// Override this method to set up initial subscriptions, data loading, etc.
  void onInit();

  /// Handles a given [JIntent] to update the state.
  ///
  /// Invokes the logic encapsulated in the intent and applies any state changes.
  /// Returns a failed future with [StateError] after disposal. Dispatchers that
  /// implement [JPendingIntentCancellation] reject pending tasks on disposal;
  /// already running work is not interrupted.
  /// Await or handle the returned future, including disposal cancellations.
  Future<void> intent(JIntent<T> intent) {
    if (!mounted) {
      return Future<void>.error(StateError('JController has been disposed.'));
    }
    return _dispatcher.dispatch(intent, this);
  }

  /// Sets a new state of type [T] if different from the current state.
  ///
  /// If the new state is equal to the current state, no update is performed.
  ///
  @Deprecated(
    'setState is deprecated. Use update((state) => newState) instead for a safer, reactive state update.',
  )
  void setState(T newState, {JIntent? origin}) {
    update((_) => newState, origin: origin);
  }

  /// Updates the current state by applying the given [reducer] function.
  ///
  /// The [reducer] receives the current state and returns a new modified state.
  /// Equivalent states (`previous == next`) are neither assigned nor reported
  /// to observers. After disposal the reducer is not called, and updates made
  /// by a cancelled intent ([JIntent.isCancelled]) are ignored. Reducers must
  /// return immutable states rather than mutate the current state in place.
  ///
  /// - [reducer]: A function that takes the current state and returns a new state.
  /// - [origin]: (Optional) The intent that triggered this state update. When
  ///   omitted, the intent currently executing in this zone ([JIntent.current])
  ///   is used if it runs on this controller; updates from elsewhere keep a
  ///   `null` origin.
  /// Callers outside an intent are unaffected.
  void update(T Function(T state) reducer, {JIntent? origin}) {
    if (!mounted) {
      if (kDebugMode) debugPrint('JController is no longer mounted.');
      return;
    }
    origin ??= _currentIntentOnThisController();
    if (origin != null && origin.isCancelled) return;
    final newState = reducer(currentState);
    if (!mounted) return;

    final prev = currentState;
    if (prev == newState) return;

    state = newState;

    JObserver.notifyStateChanged(prev, newState, origin);
  }

  JIntent? _currentIntentOnThisController() {
    final current = JIntent.current;
    return current != null && identical(current.controller, this)
        ? current
        : null;
  }

  /// Emits a one-time [JEffect] to the UI.
  ///
  /// This can be used for side effects like showing a dialog, toast, or navigation.
  /// Awaitable effects without a listener complete with [StateError].
  /// Fire-and-forget effects without listeners are dropped, as with a broadcast
  /// stream. Emitting after disposal completes the effect with [StateError]
  /// and throws that error synchronously.
  ///
  /// With a positive `effectBufferSize`, an effect emitted while no listener is
  /// attached is retained instead, awaitable ones included, and delivered in
  /// emission order shortly after the next listener subscribes. Each effect is
  /// delivered once, to whoever listens first. When the buffer is full the
  /// oldest retained effect is discarded and completed with [StateError].
  /// Retained awaitable effects stay pending: use a timeout, or disposal, which
  /// fails them. Already completed awaitable effects are skipped on delivery.
  /// This is meant for effects emitted before the UI attaches, such as from
  /// [onInit].
  void emitSideEffect(JEffect effect) {
    if (!mounted) {
      final error = StateError(
        'Cannot emit an effect after controller disposal.',
      );
      _failEffect(effect, error);
      throw error;
    }
    final hasListener = _sideEffectController.hasListener;
    // Keep emission order while earlier effects still wait to be delivered.
    final buffer =
        _effectBufferSize > 0 && (!hasListener || _bufferedEffects.isNotEmpty);
    if (effect is! JFireAndForgetEffect) {
      if (!hasListener && !buffer) {
        _failEffect(effect, _missingListenerError(effect));
        return;
      }
      _trackEffect(effect);
    }
    if (buffer) {
      _bufferEffect(effect);
    } else {
      _sideEffectController.add(effect);
    }
    JObserver.notifyEffectEmitted(effect);
  }

  /// Emits a [JEffect] and waits for its completion or timeout.
  /// Missing listeners and disposal fail with [StateError]. This does not cancel
  /// UI handlers or external operations that have already started.
  Future<V> emitAndWaitSideEffect<V>(
    JEffect<V> effect, {
    Duration? timeout,
  }) async {
    // An explicitly awaited fire-and-forget effect also needs a listener.
    if (mounted &&
        _effectBufferSize == 0 &&
        !_sideEffectController.hasListener) {
      _failEffect(effect, _missingListenerError(effect));
      return effect.result;
    }
    // Emit the effect
    emitSideEffect(effect);
    if (effect is JFireAndForgetEffect) _trackEffect(effect);

    // Apply timeout if configured
    final appliedTimeout = timeout ?? JEffectsConfig().defaultTimeout;

    // If no timeout is set, return the effect's result immediately
    if (appliedTimeout == null) return effect.result;

    // Apply timeout logic
    return effect.result.timeout(
      appliedTimeout,
      onTimeout: () {
        final error = TimeoutException(
          'Effect ${effect.runtimeType} (id=${effect.id}) timed out after $appliedTimeout',
          appliedTimeout,
        );
        if (!effect.isCompleted) {
          effect.completeError(error);
        }
        throw error;
      },
    );
  }

  void _bufferEffect(JEffect effect) {
    _bufferedEffects.add(effect);
    while (_bufferedEffects.length > _effectBufferSize) {
      final dropped = _bufferedEffects.removeFirst();
      _failEffect(
        dropped,
        StateError(
          'Effect buffer full: ${dropped.runtimeType} (id=${dropped.id}) '
          'was discarded before a listener received it.',
        ),
      );
    }
  }

  void _deliverBufferedEffects() {
    while (mounted &&
        _bufferedEffects.isNotEmpty &&
        _sideEffectController.hasListener) {
      final effect = _bufferedEffects.removeFirst();
      if (effect.isCompleted && effect is! JFireAndForgetEffect) continue;
      _sideEffectController.add(effect);
    }
  }

  StateError _missingListenerError(JEffect effect) => StateError(
    'No listener attached for ${effect.runtimeType} (id=${effect.id}). '
    'Attach a listener before emitting an awaitable effect.',
  );

  void _trackEffect(JEffect effect) {
    if (!_pendingEffects.add(effect)) return;
    // Observe completion to release the reference on both success and error.
    // Other callers still receive the original result when awaiting it.
    effect.result.then<void>(
      (_) => _pendingEffects.remove(effect),
      onError: (Object error, StackTrace stackTrace) {
        _pendingEffects.remove(effect);
      },
    );
  }

  void _failEffect(JEffect effect, StateError error) {
    effect.result.ignore();
    if (!effect.isCompleted) effect.completeError(error, StackTrace.current);
  }

  /// Fails pending awaitable effects and closes the side effects stream.
  /// Cancels queued intents if the dispatcher supports [JPendingIntentCancellation].
  /// Already running handlers and intents are not interrupted. External work
  /// must check [mounted] or use its own cancellation API after asynchronous gaps.
  @override
  void dispose() {
    final dispatcher = _dispatcher;
    if (dispatcher is JPendingIntentCancellation) {
      (dispatcher as JPendingIntentCancellation).cancelPending(this);
    }
    for (final effect in _pendingEffects) {
      _failEffect(
        effect,
        StateError(
          'Controller disposed before ${effect.runtimeType} '
          '(id=${effect.id}) completed.',
        ),
      );
    }
    _pendingEffects.clear();
    _bufferedEffects.clear();
    _sideEffectController.close();
    super.dispose();
  }
}
