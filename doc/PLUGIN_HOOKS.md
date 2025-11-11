# Plugin Hooks & Extensibility Guide

**Status:** Published  
**Version:** 1.0  
**Date:** 2025-10-15  
**Audience:** Plugin developers and advanced users

---

## Table of Contents

1. [Overview](#overview)
2. [Observer Pattern](#observer-pattern)
3. [Custom Dispatchers](#custom-dispatchers)
4. [Custom Effect Handlers](#custom-effect-handlers)
5. [Middleware Pattern](#middleware-pattern)
6. [Plugin Examples](#plugin-examples)
7. [Best Practices](#best-practices)

---

## Overview

JIntent provides multiple extensibility points for building plugins and custom behavior:

- **Observer hooks**: React to intents, state changes, and effects
- **Custom dispatchers**: Control how intents are processed
- **Custom effect handlers**: Handle application-specific side effects
- **Middleware pattern**: Intercept and modify operations

This guide shows how to build plugins and extensions for JIntent.

---

## Observer Pattern

### JObserver Hooks

The `JObserver` class provides global hooks for observing JIntent operations:

```dart
import 'package:jintent/jintent.dart';

class MyPlugin {
  void install() {
    // Called when any intent is dispatched
    JObserver.onIntentDispatched = (intent) {
      print('Intent: ${intent.runtimeType}');
    };

    // Called when state changes
    JObserver.onStateChanged = (prev, next, origin) {
      print('State: $prev → $next (from ${origin?.runtimeType})');
    };

    // Called when an effect is emitted
    JObserver.onEffectEmitted = (effect) {
      print('Effect: ${effect.runtimeType}');
    };
  }

  void uninstall() {
    JObserver.onIntentDispatched = null;
    JObserver.onStateChanged = null;
    JObserver.onEffectEmitted = null;
  }
}
```

### Use Cases

**Analytics Plugin:**
```dart
class AnalyticsPlugin {
  final AnalyticsService _analytics;

  AnalyticsPlugin(this._analytics);

  void install() {
    JObserver.onIntentDispatched = (intent) {
      _analytics.logEvent(
        'intent_dispatched',
        parameters: {'type': intent.runtimeType.toString()},
      );
    };

    JObserver.onStateChanged = (prev, next, origin) {
      _analytics.logEvent(
        'state_changed',
        parameters: {
          'from': prev.runtimeType.toString(),
          'to': next.runtimeType.toString(),
        },
      );
    };
  }
}
```

**Crash Reporting Plugin:**
```dart
class CrashReportingPlugin {
  final CrashReporter _reporter;

  CrashReportingPlugin(this._reporter);

  void install() {
    JObserver.onIntentDispatched = (intent) {
      _reporter.addBreadcrumb('Intent: ${intent.runtimeType}');
    };

    JObserver.onStateChanged = (prev, next, origin) {
      _reporter.setContext('lastState', next.toString());
    };

    JObserver.onEffectEmitted = (effect) {
      _reporter.addBreadcrumb('Effect: ${effect.runtimeType}');
    };
  }
}
```

**Time Travel Debugger:**
```dart
class TimeTravelPlugin<T extends JState> {
  final List<StateSnapshot<T>> _history = [];

  void install() {
    JObserver.onStateChanged = (prev, next, origin) {
      _history.add(StateSnapshot(
        state: next as T,
        timestamp: DateTime.now(),
        origin: origin,
      ));
    };
  }

  void travelTo(int index) {
    if (index >= 0 && index < _history.length) {
      // Restore state from history
      final snapshot = _history[index];
      // Implementation depends on your architecture
    }
  }

  List<StateSnapshot<T>> get history => List.unmodifiable(_history);
}

class StateSnapshot<T extends JState> {
  final T state;
  final DateTime timestamp;
  final JIntent? origin;

  StateSnapshot({
    required this.state,
    required this.timestamp,
    this.origin,
  });
}
```

---

## Custom Dispatchers

### JIntentDispatcher Interface

Create custom dispatchers to control how intents are processed:

```dart
import 'package:jintent/jintent.dart';

class MyCustomDispatcher implements JIntentDispatcher {
  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    // Custom dispatching logic
    await intent.run(controller);
  }
}
```

### Example: Priority Dispatcher

```dart
class PriorityDispatcher implements JIntentDispatcher {
  final Map<Type, int> _priorities = {};
  final List<_PendingIntent> _queue = [];
  bool _isProcessing = false;

  void setPriority(Type intentType, int priority) {
    _priorities[intentType] = priority;
  }

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    final priority = _priorities[intent.runtimeType] ?? 0;
    
    _queue.add(_PendingIntent(intent, controller, priority));
    _queue.sort((a, b) => b.priority.compareTo(a.priority));

    if (!_isProcessing) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessing = true;
    
    while (_queue.isNotEmpty) {
      final pending = _queue.removeAt(0);
      await pending.intent.run(pending.controller);
    }
    
    _isProcessing = false;
  }
}

class _PendingIntent {
  final JIntent intent;
  final JController controller;
  final int priority;

  _PendingIntent(this.intent, this.controller, this.priority);
}
```

### Example: Debouncing Dispatcher

```dart
class DebouncingDispatcher implements JIntentDispatcher {
  final JIntentDispatcher inner;
  final Duration debounceDuration;
  final Map<Type, Timer?> _timers = {};

  DebouncingDispatcher({
    required this.inner,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    final type = intent.runtimeType;
    
    // Cancel previous timer for this intent type
    _timers[type]?.cancel();
    
    // Create new timer
    _timers[type] = Timer(debounceDuration, () async {
      await inner.dispatch(intent, controller);
      _timers[type] = null;
    });
  }
}
```

### Using Custom Dispatchers

```dart
class MyController extends JController<MyState> {
  MyController() : super(
    MyState.initial(),
    dispatcher: PriorityDispatcher()
      ..setPriority(CriticalIntent, 100)
      ..setPriority(NormalIntent, 50),
  );

  @override
  void onInit() {}
}
```

---

## Custom Effect Handlers

### JSideEffectHandler

Create custom handlers for application-specific side effects:

```dart
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

// Define your custom effect
class ShowToastEffect extends JFireAndForgetEffect {
  final String message;
  final ToastType type;

  ShowToastEffect(this.message, {this.type = ToastType.info})
      : super(category: 'toast');
}

enum ToastType { info, success, warning, error }

// Create a custom handler
class ToastEffectHandler extends JSideEffectHandler<MyState> {
  ToastEffectHandler(JController<MyState> controller) : super(controller);

  @override
  void initialize() {
    // Register handler for ShowToastEffect
    register<ShowToastEffect>((effect, ctrl, context) async {
      final color = _getColorForType(effect.type);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(effect.message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
      
      effect.complete(null);
    });
  }

  Color _getColorForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.error:
        return Colors.red;
      case ToastType.info:
        return Colors.blue;
    }
  }
}

// Use in your widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(myControllerProvider.notifier);
    
    return JEffectListener<MyState>(
      controller: controller,
      handler: ToastEffectHandler(controller),
      child: Scaffold(/* ... */),
    );
  }
}
```

---

## Middleware Pattern

### Composable Middleware

Create middleware that wraps dispatchers:

```dart
abstract class Middleware implements JIntentDispatcher {
  final JIntentDispatcher next;

  Middleware(this.next);
}

class LoggingMiddleware extends Middleware {
  LoggingMiddleware(JIntentDispatcher next) : super(next);

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    print('→ ${intent.runtimeType}');
    final stopwatch = Stopwatch()..start();
    
    await next.dispatch(intent, controller);
    
    stopwatch.stop();
    print('← ${intent.runtimeType} (${stopwatch.elapsedMilliseconds}ms)');
  }
}

class ErrorHandlingMiddleware extends Middleware {
  final Function(Object error, StackTrace stack) onError;

  ErrorHandlingMiddleware(JIntentDispatcher next, {required this.onError})
      : super(next);

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    try {
      await next.dispatch(intent, controller);
    } catch (error, stack) {
      onError(error, stack);
      rethrow;
    }
  }
}

class MetricsMiddleware extends Middleware {
  final MetricsService metrics;

  MetricsMiddleware(JIntentDispatcher next, this.metrics) : super(next);

  @override
  Future<void> dispatch<T extends JState>(
    JIntent<T> intent,
    JController<T> controller,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await next.dispatch(intent, controller);
      metrics.recordSuccess(intent.runtimeType.toString(), stopwatch.elapsed);
    } catch (e) {
      metrics.recordFailure(intent.runtimeType.toString(), stopwatch.elapsed);
      rethrow;
    }
  }
}
```

### Composing Middleware

```dart
final dispatcher = LoggingMiddleware(
  ErrorHandlingMiddleware(
    MetricsMiddleware(
      JDefaultIntentDispatcher(),
      metricsService,
    ),
    onError: (error, stack) {
      crashReporter.recordError(error, stack);
    },
  ),
);

class MyController extends JController<MyState> {
  MyController() : super(MyState.initial(), dispatcher: dispatcher);

  @override
  void onInit() {}
}
```

---

## Plugin Examples

### Complete Analytics Plugin

```dart
import 'package:jintent/jintent.dart';

class JIntentAnalyticsPlugin {
  final AnalyticsService _analytics;
  bool _installed = false;

  JIntentAnalyticsPlugin(this._analytics);

  void install() {
    if (_installed) return;
    
    JObserver.onIntentDispatched = _onIntentDispatched;
    JObserver.onStateChanged = _onStateChanged;
    JObserver.onEffectEmitted = _onEffectEmitted;
    
    _installed = true;
  }

  void uninstall() {
    if (!_installed) return;
    
    JObserver.onIntentDispatched = null;
    JObserver.onStateChanged = null;
    JObserver.onEffectEmitted = null;
    
    _installed = false;
  }

  void _onIntentDispatched(JIntent intent) {
    final metadata = <String, dynamic>{
      'type': intent.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (intent is JMetaData) {
      metadata['intentType'] = intent.type;
      metadata['intentName'] = intent.name;
    }

    _analytics.logEvent('jintent_dispatched', parameters: metadata);
  }

  void _onStateChanged(JState prev, JState next, JIntent? origin) {
    _analytics.logEvent('jintent_state_changed', parameters: {
      'fromType': prev.runtimeType.toString(),
      'toType': next.runtimeType.toString(),
      'originType': origin?.runtimeType.toString() ?? 'unknown',
    });
  }

  void _onEffectEmitted(JEffect effect) {
    _analytics.logEvent('jintent_effect_emitted', parameters: {
      'type': effect.runtimeType.toString(),
      'category': effect.resolvedCategory,
      'id': effect.id,
    });
  }
}

// Usage
void main() {
  final analytics = FirebaseAnalytics.instance;
  final plugin = JIntentAnalyticsPlugin(analytics);
  
  plugin.install();
  
  runApp(MyApp());
}
```

### State Persistence Plugin

```dart
class StatePersistencePlugin<T extends JState> {
  final String storageKey;
  final SharedPreferences prefs;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  StatePersistencePlugin({
    required this.storageKey,
    required this.prefs,
    required this.fromJson,
    required this.toJson,
  });

  void install() {
    JObserver.onStateChanged = (prev, next, origin) {
      if (next is T) {
        _saveState(next);
      }
    };
  }

  T? loadState() {
    final json = prefs.getString(storageKey);
    if (json == null) return null;
    
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return fromJson(map);
    } catch (e) {
      print('Error loading state: $e');
      return null;
    }
  }

  Future<void> _saveState(T state) async {
    try {
      final json = jsonEncode(toJson(state));
      await prefs.setString(storageKey, json);
    } catch (e) {
      print('Error saving state: $e');
    }
  }

  Future<void> clearState() async {
    await prefs.remove(storageKey);
  }
}
```

---

## Best Practices

### 1. Clean Installation/Uninstallation

Always provide both install and uninstall methods:

```dart
class MyPlugin {
  bool _installed = false;

  void install() {
    if (_installed) return;
    // Setup hooks
    _installed = true;
  }

  void uninstall() {
    if (!_installed) return;
    // Clean up hooks
    _installed = false;
  }
}
```

### 2. Avoid Memory Leaks

Clean up observers when done:

```dart
class MyPlugin {
  late Function(JIntent)? _originalHandler;

  void install() {
    _originalHandler = JObserver.onIntentDispatched;
    JObserver.onIntentDispatched = _myHandler;
  }

  void uninstall() {
    JObserver.onIntentDispatched = _originalHandler;
  }
}
```

### 3. Performance Considerations

Be mindful of observer overhead:

```dart
// Bad: Heavy processing in observer
JObserver.onStateChanged = (prev, next, origin) {
  expensiveAnalytics(prev, next);  // Blocks state updates!
};

// Good: Async processing
JObserver.onStateChanged = (prev, next, origin) {
  Future.microtask(() => expensiveAnalytics(prev, next));
};
```

### 4. Error Handling

Always handle errors in plugins:

```dart
class SafePlugin {
  void install() {
    JObserver.onIntentDispatched = (intent) {
      try {
        _handleIntent(intent);
      } catch (e, stack) {
        print('Plugin error: $e');
        // Don't crash the app
      }
    };
  }
}
```

### 5. Plugin Composition

Design plugins to work together:

```dart
class PluginManager {
  final List<Plugin> _plugins = [];

  void register(Plugin plugin) {
    _plugins.add(plugin);
    plugin.install();
  }

  void unregisterAll() {
    for (final plugin in _plugins) {
      plugin.uninstall();
    }
    _plugins.clear();
  }
}

abstract class Plugin {
  void install();
  void uninstall();
}
```

### 6. Documentation

Document your plugin's:
- Installation steps
- Configuration options
- Performance impact
- Compatibility requirements

---

## Community Plugins

Share your plugins with the community:

1. Publish to pub.dev with prefix `jintent_`
2. Tag with `jintent-plugin`
3. Include examples and tests
4. Document performance characteristics

**Example plugins to build:**
- `jintent_firebase_analytics`
- `jintent_redux_devtools`
- `jintent_sentry`
- `jintent_hydrated_state`
- `jintent_time_travel`

---

## Summary

JIntent provides powerful extensibility through:

- **Observer hooks** for monitoring operations
- **Custom dispatchers** for controlling execution
- **Custom effect handlers** for side effects
- **Middleware pattern** for composable behavior

Use these patterns to build plugins that extend JIntent's capabilities without modifying the core library.

---

**Related Documentation:**
- [Observability Guide](./OBSERVABILITY_GUIDE.md)
- [ADR-008: Observability Strategy](./adr/ADR-008-observability-strategy.md)
- [API Documentation](https://pub.dev/documentation/jintent/latest/)
