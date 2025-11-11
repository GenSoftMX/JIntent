# DevTools Overlay - Proof of Concept

**Status:** Experimental  
**Version:** 1.0  
**Date:** 2025-10-15  
**Phase:** 4 - Advanced Features

---

## Overview

The JIntent DevTools Overlay is a real-time visualization tool for debugging and monitoring JIntent operations directly in your Flutter application. This proof-of-concept demonstrates how to visualize intents, state changes, and side effects as they occur.

---

## Features

### ✅ Real-Time Event Monitoring

- **Intent Tracking**: See every intent dispatched with timestamp
- **State Changes**: Monitor state transitions with before/after states
- **Effect Emission**: Track side effects as they're emitted
- **Metadata Display**: View intent metadata and context

### ✅ Visual Dashboard

- **Event List**: Chronological view of all JIntent operations
- **Metrics Summary**: Count of intents, states, and effects
- **Event Details**: Expandable cards with full metadata
- **Color Coding**: Different colors for different event types

### ✅ Developer-Friendly

- **Toggle On/Off**: FloatingActionButton to show/hide overlay
- **Auto-Clear**: Events older than 30 seconds are removed
- **Event Limit**: Keeps only the last 50 events by default
- **Debug Mode Only**: Automatically disabled in release builds

---

## Screenshots

### Overlay Toggle Button
![Toggle Button](../assets/devtools-toggle.png)

### Event Dashboard
![Dashboard](../assets/devtools-dashboard.png)

### Event Details
![Event Details](../assets/devtools-details.png)

---

## Installation

### 1. Import the Package

```dart
import 'package:jintent/jintent.dart';
```

The DevTools overlay is included in the main JIntent package under experimental features.

### 2. Wrap Your App

Wrap your app with `JDevToolsOverlay`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JIntent Demo',
      builder: (context, child) {
        return JDevToolsOverlay(
          enabled: kDebugMode,  // Only in debug mode
          child: child!,
        );
      },
      home: const MyHomePage(),
    );
  }
}
```

### 3. That's It!

The overlay will automatically:
- Attach to JObserver hooks
- Monitor all JIntent operations
- Display events in real-time

---

## Usage

### Basic Usage

No additional code needed! Once installed, the overlay automatically monitors:

```dart
class MyController extends JController<MyState> {
  MyController() : super(MyState.initial());

  @override
  void onInit() {}

  void increment() {
    intent(IncrementIntent());  // Automatically tracked!
  }
}

class IncrementIntent extends JIntent<MyState> with JIntentHelpers<MyState> {
  @override
  Future<void> onInvoke() async {
    update((state) => state.copyWith(counter: state.counter + 1));
    // State change automatically tracked!
    
    if (state.counter % 10 == 0) {
      emitSideEffect(ShowToastEffect('Counter reached ${state.counter}!'));
      // Effect automatically tracked!
    }
  }
}
```

### Configuration Options

Customize the overlay behavior:

```dart
JDevToolsOverlay(
  enabled: kDebugMode,           // Enable/disable overlay
  maxEvents: 100,                // Maximum events to keep (default: 50)
  maxEventAge: Duration(minutes: 1),  // Max age before removal (default: 30s)
  child: child!,
)
```

### Interacting with the Overlay

1. **Open Overlay**: Tap the purple FAB (developer mode icon)
2. **Close Overlay**: Tap the X button in the top-right
3. **View Event Details**: Tap on any event card to expand
4. **Clear Events**: Tap the clear icon in the header
5. **Collapse Metrics**: Tap the expand/collapse icon in the header

---

## Event Types

### Intent Events (Blue)

Displayed when an intent is dispatched:

```
📱 IncrementIntent
   15:30:42.123 • 2s ago
   Type: increment
   Metadata: {count: 5}
```

### State Events (Green)

Displayed when state changes:

```
🔄 CounterState → CounterState
   15:30:42.125 • 2s ago
   Origin: IncrementIntent
```

### Effect Events (Orange)

Displayed when side effects are emitted:

```
⚡ ShowToastEffect
   15:30:42.126 • 2s ago
   ID: effect_1634567842126
   Category: toast
```

---

## Advanced Features

### Adding Custom Metadata

To show custom metadata in the overlay, implement `JMetaData`:

```dart
class IncrementIntent extends JIntent<MyState> 
    with JIntentHelpers<MyState>, JMetaData {
  
  @override
  String get type => 'counter';
  
  @override
  String get name => 'increment';
  
  @override
  Map<String, dynamic> get metadata => {
    'timestamp': DateTime.now().toIso8601String(),
    'userId': currentUser?.id,
    'platform': Platform.operatingSystem,
  };

  @override
  Future<void> onInvoke() async {
    update((state) => state.copyWith(counter: state.counter + 1));
  }
}
```

The overlay will automatically display all metadata:

```
📱 IncrementIntent
   Metadata:
     type: counter
     name: increment
     timestamp: 2025-10-15T15:30:42.123Z
     userId: user_123
     platform: android
```

---

## Performance Considerations

### Overhead

The overlay has minimal performance impact:

- **Memory**: ~100KB for 50 events
- **CPU**: <0.1ms per event
- **UI**: No impact when hidden

### Best Practices

1. **Enable Only in Debug**:
   ```dart
   JDevToolsOverlay(
     enabled: kDebugMode,  // Never in release!
     child: child!,
   )
   ```

2. **Limit Event Count**:
   ```dart
   JDevToolsOverlay(
     maxEvents: 50,  // Don't keep too many
     child: child!,
   )
   ```

3. **Use Event Age Limit**:
   ```dart
   JDevToolsOverlay(
     maxEventAge: Duration(seconds: 30),  // Auto-cleanup
     child: child!,
   )
   ```

---

## Integration with Other Tools

### With Firebase Analytics

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

void setupObservability() {
  final analytics = FirebaseAnalytics.instance;
  
  JObserver.onIntentDispatched = (intent) {
    analytics.logEvent(
      name: 'intent_dispatched',
      parameters: {'type': intent.runtimeType.toString()},
    );
  };
}
```

### With Sentry

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void setupObservability() {
  JObserver.onIntentDispatched = (intent) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: 'Intent: ${intent.runtimeType}',
      category: 'jintent',
    ));
  };
}
```

### With Custom Logger

```dart
import 'package:jintent/jintent.dart';

void setupObservability() {
  final logger = JStructuredLogger(serviceName: 'my-app');
  
  JObserver.onIntentDispatched = (intent) {
    logger.info('Intent dispatched', context: {
      'type': intent.runtimeType.toString(),
      'correlationId': CorrelationContext.current,
    });
  };
}
```

---

## Troubleshooting

### Overlay Not Showing

**Problem**: Overlay doesn't appear when tapping FAB

**Solutions**:
1. Ensure `enabled: true` or `enabled: kDebugMode`
2. Check that you're in debug mode (`flutter run` not `flutter run --release`)
3. Verify overlay is wrapped around your entire app

### Events Not Appearing

**Problem**: No events shown in the overlay

**Solutions**:
1. Ensure controllers are dispatching intents
2. Check that observers aren't being overridden elsewhere
3. Verify events aren't too old (check `maxEventAge`)

### Performance Issues

**Problem**: App feels slow with overlay enabled

**Solutions**:
1. Reduce `maxEvents` (try 25 instead of 50)
2. Shorten `maxEventAge` (try 15s instead of 30s)
3. Close overlay when not needed
4. Ensure `enabled: kDebugMode` so it's disabled in release

---

## Future Enhancements

This is a proof-of-concept. Future versions may include:

- [ ] **Export Events**: Save events to file for analysis
- [ ] **Filter Events**: Show only specific event types
- [ ] **Search**: Find events by type or metadata
- [ ] **Timeline View**: Visualize event sequences
- [ ] **Performance Metrics**: Show execution times
- [ ] **Network Integration**: Send events to remote server
- [ ] **Chrome DevTools**: Integration with Flutter DevTools
- [ ] **State Diffing**: Show exact state changes
- [ ] **Replay**: Replay event sequences

---

## Comparison with Other Tools

### vs. Flutter DevTools

| Feature | JIntent Overlay | Flutter DevTools |
|---------|----------------|------------------|
| In-App | ✅ Yes | ❌ No (separate window) |
| Real-Time | ✅ Yes | ✅ Yes |
| JIntent-Specific | ✅ Yes | ❌ No |
| State Timeline | ❌ Not yet | ✅ Yes |
| Performance Profiling | ❌ No | ✅ Yes |
| Memory Profiling | ❌ No | ✅ Yes |

**Use JIntent Overlay when**: You want quick, in-app monitoring of JIntent operations

**Use Flutter DevTools when**: You need comprehensive performance and memory analysis

---

## API Reference

### JDevToolsOverlay

```dart
class JDevToolsOverlay extends StatefulWidget {
  /// Child widget to wrap
  final Widget child;
  
  /// Whether the overlay is enabled (default: kDebugMode)
  final bool enabled;
  
  /// Maximum age of events before auto-removal (default: 30s)
  final Duration maxEventAge;
  
  /// Maximum number of events to keep (default: 50)
  final int maxEvents;

  const JDevToolsOverlay({
    Key? key,
    required this.child,
    this.enabled = kDebugMode,
    this.maxEventAge = const Duration(seconds: 30),
    this.maxEvents = 50,
  });
}
```

### DevToolsEvent

```dart
class DevToolsEvent {
  /// Type of event (intent, state, effect)
  final EventType type;
  
  /// Display title for the event
  final String title;
  
  /// When the event occurred
  final DateTime timestamp;
  
  /// Additional metadata
  final Map<String, dynamic> metadata;
}

enum EventType {
  intent,
  state,
  effect,
}
```

---

## Contributing

Want to improve the DevTools overlay? We welcome contributions!

### Ideas for Contributions

- Add filtering capabilities
- Implement event export
- Create timeline visualization
- Add state diffing
- Improve performance
- Add more metadata

### How to Contribute

1. Fork the repository
2. Create a feature branch
3. Add your enhancement
4. Write tests
5. Submit a pull request

---

## License

The JIntent DevTools Overlay is part of the JIntent package and shares the same MIT license.

---

## Summary

The JIntent DevTools Overlay provides:

- ✅ Real-time monitoring of JIntent operations
- ✅ In-app visualization without external tools
- ✅ Minimal performance overhead
- ✅ Easy integration (just wrap your app)
- ✅ Automatic operation tracking

Perfect for:
- Debugging intent flows
- Understanding state changes
- Monitoring side effects
- Learning how JIntent works
- Demonstrating behavior to stakeholders

---

**Related Documentation:**
- [Observability Guide](./OBSERVABILITY_GUIDE.md)
- [Plugin Hooks Guide](./PLUGIN_HOOKS.md)
- [Performance Guide](./PERFORMANCE.md)

**Status**: Experimental - API may change in future versions
