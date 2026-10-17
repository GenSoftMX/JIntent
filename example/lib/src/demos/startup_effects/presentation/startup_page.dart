import 'dart:async';

import 'package:counter/src/demos/startup_effects/controller/startup_controller.dart';
import 'package:counter/src/demos/startup_effects/presentation/startup_effect_handler.dart';
import 'package:counter/src/demos/startup_effects/state/startup_state.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/widgets.dart';

class StartupEffectsPage extends StatefulWidget {
  const StartupEffectsPage({super.key});

  @override
  State<StartupEffectsPage> createState() => _StartupEffectsPageState();
}

class _StartupEffectsPageState extends State<StartupEffectsPage> {
  bool _buffered = true;
  late StartupController _controller;
  late StartupEffectHandler _handler;
  final _nameField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _create();
  }

  // The controller is created here, before the JEffectListener below exists,
  // so the welcome effect is emitted while nobody listens.
  void _create() {
    _controller = StartupController(buffered: _buffered);
    _handler = StartupEffectHandler(_controller);
  }

  void _toggleBuffering(bool value) {
    final previous = _controller;
    setState(() {
      _buffered = value;
      _create();
    });
    previous.dispose();
  }

  void _run(Future<void> operation) {
    // The intents translate their own failures into state; anything else is a
    // lifecycle error, for example a dispatch after disposal.
    unawaited(operation.catchError((_) {}));
  }

  @override
  void dispose() {
    _nameField.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return JEffectListener<StartupState>(
      controller: _controller,
      handler: _handler,
      child: Scaffold(
        appBar: AppBar(title: const Text('Startup & Effects')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'The controller emits a welcome effect in onInit, before this '
              'page can listen. With buffering the effect waits for the '
              'listener; without it the effect is lost. Toggle the switch to '
              'recreate the controller and compare.',
              style: theme.textTheme.bodyMedium,
            ),
            SwitchListTile(
              key: const Key('buffer-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Buffer effects (effectBufferSize: 8)'),
              value: _buffered,
              onChanged: _toggleBuffering,
            ),
            const Divider(),
            TextField(
              key: const Key('name-field'),
              controller: _nameField,
              decoration: const InputDecoration(
                labelText: 'Name (3 to 12 characters)',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run(_controller.saveName(_nameField.text)),
                  child: const Text('Save name'),
                ),
                OutlinedButton(
                  onPressed: () => _run(_controller.askConfirmation()),
                  child: const Text('Ask confirmation'),
                ),
                OutlinedButton(
                  onPressed: () => _run(_controller.triggerUnhandled()),
                  child: const Text('Trigger unhandled effect'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            JControllerBuilder<StartupState>(
              controller: _controller,
              builder:
                  (context, state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${state.status}',
                        key: const Key('startup-status'),
                      ),
                      Text('Saved name: ${state.name ?? '-'}'),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
