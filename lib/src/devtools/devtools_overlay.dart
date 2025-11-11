import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';
import 'dart:collection';

/// DevTools overlay widget that visualizes JIntent operations in real-time.
///
/// This overlay displays:
/// - Recent intents dispatched with timestamps
/// - Current state changes
/// - Side effects emitted
/// - Performance metrics
///
/// Usage:
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return JDevToolsOverlay(
///       enabled: kDebugMode,
///       child: child!,
///     );
///   },
/// );
/// ```
class JDevToolsOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration maxEventAge;
  final int maxEvents;

  const JDevToolsOverlay({
    Key? key,
    required this.child,
    this.enabled = kDebugMode,
    this.maxEventAge = const Duration(seconds: 30),
    this.maxEvents = 50,
  }) : super(key: key);

  @override
  State<JDevToolsOverlay> createState() => _JDevToolsOverlayState();
}

class _JDevToolsOverlayState extends State<JDevToolsOverlay> {
  final _events = Queue<DevToolsEvent>();
  bool _isVisible = false;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _attachObservers();
    }
  }

  void _attachObservers() {
    JObserver.onIntentDispatched = (intent) {
      _addEvent(
        DevToolsEvent(
          type: EventType.intent,
          title: intent.runtimeType.toString(),
          timestamp: DateTime.now(),
          metadata: _extractMetadata(intent),
        ),
      );
    };

    JObserver.onStateChanged = (prev, next, origin) {
      _addEvent(
        DevToolsEvent(
          type: EventType.state,
          title: '${prev.runtimeType} → ${next.runtimeType}',
          timestamp: DateTime.now(),
          metadata: {'origin': origin?.runtimeType.toString() ?? 'unknown'},
        ),
      );
    };

    JObserver.onEffectEmitted = (effect) {
      _addEvent(
        DevToolsEvent(
          type: EventType.effect,
          title: effect.runtimeType.toString(),
          timestamp: DateTime.now(),
          metadata: {'id': effect.id, 'category': effect.resolvedCategory},
        ),
      );
    };
  }

  Map<String, dynamic> _extractMetadata(dynamic intent) {
    final metadata = <String, dynamic>{};

    if (intent is JMetaData) {
      metadata['type'] = intent.type;
      metadata['name'] = intent.name;
      metadata['metadata'] = intent.metadata;
    }

    return metadata;
  }

  void _addEvent(DevToolsEvent event) {
    if (!mounted) return;

    setState(() {
      _events.addFirst(event);

      // Remove old events
      _events.removeWhere(
        (e) => DateTime.now().difference(e.timestamp) > widget.maxEventAge,
      );

      // Limit total events
      while (_events.length > widget.maxEvents) {
        _events.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (_isVisible) _buildOverlay(context),
        _buildToggleButton(context),
      ],
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.deepPurple.withOpacity(0.9),
        onPressed: () {
          setState(() {
            _isVisible = !_isVisible;
          });
        },
        child: Icon(
          _isVisible ? Icons.close : Icons.developer_mode,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      bottom: 80,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.95),
        child: Column(
          children: [_buildHeader(context), Expanded(child: _buildEventList())],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final intentCount = _events.where((e) => e.type == EventType.intent).length;
    final stateCount = _events.where((e) => e.type == EventType.state).length;
    final effectCount = _events.where((e) => e.type == EventType.effect).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.developer_mode, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'JIntent DevTools',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _events.clear();
                  });
                },
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricChip('Intents', intentCount, Colors.blue),
                _buildMetricChip('States', stateCount, Colors.green),
                _buildMetricChip('Effects', effectCount, Colors.orange),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    if (_events.isEmpty) {
      return const Center(
        child: Text(
          'No events yet...\nInteract with your app to see JIntent operations',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events.elementAt(index);
        return _buildEventCard(event, index);
      },
    );
  }

  Widget _buildEventCard(DevToolsEvent event, int index) {
    final color = _getEventColor(event.type);
    final icon = _getEventIcon(event.type);
    final age = DateTime.now().difference(event.timestamp);
    final ageText = _formatAge(age);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          event.title,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        subtitle: Text(
          '${_formatTime(event.timestamp)} • $ageText ago',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            event.type.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          if (event.metadata.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black.withOpacity(0.3),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metadata:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...event.metadata.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.intent:
        return Colors.blue;
      case EventType.state:
        return Colors.green;
      case EventType.effect:
        return Colors.orange;
    }
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.intent:
        return Icons.flash_on;
      case EventType.state:
        return Icons.sync_alt;
      case EventType.effect:
        return Icons.widgets;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${(time.millisecond ~/ 10).toString().padLeft(2, '0')}';
  }

  String _formatAge(Duration age) {
    if (age.inSeconds < 1) {
      return '${age.inMilliseconds}ms';
    } else if (age.inSeconds < 60) {
      return '${age.inSeconds}s';
    } else {
      return '${age.inMinutes}m';
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      JObserver.onIntentDispatched = null;
      JObserver.onStateChanged = null;
      JObserver.onEffectEmitted = null;
    }
    super.dispose();
  }
}

enum EventType { intent, state, effect }

class DevToolsEvent {
  final EventType type;
  final String title;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  DevToolsEvent({
    required this.type,
    required this.title,
    required this.timestamp,
    this.metadata = const {},
  });
}
