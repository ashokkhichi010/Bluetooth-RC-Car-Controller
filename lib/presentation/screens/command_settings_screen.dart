import 'package:bluetooth_rc_car/domain/models/command_settings.dart';
import 'package:bluetooth_rc_car/presentation/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommandSettingsScreen extends ConsumerStatefulWidget {
  const CommandSettingsScreen({
    required this.initialSettings,
    super.key,
  });

  final CommandSettings initialSettings;

  @override
  ConsumerState<CommandSettingsScreen> createState() =>
      _CommandSettingsScreenState();
}

class _CommandSettingsScreenState extends ConsumerState<CommandSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _lineFollowerController;
  late final TextEditingController _obstacleAvoidanceController;
  late final TextEditingController _followMeController;
  late final TextEditingController _manualModeController;
  late final TextEditingController _forwardController;
  late final TextEditingController _backwardController;
  late final TextEditingController _leftController;
  late final TextEditingController _rightController;
  late final TextEditingController _stopController;
  late final TextEditingController _forwardLeftController;
  late final TextEditingController _forwardRightController;
  late final TextEditingController _backwardLeftController;
  late final TextEditingController _backwardRightController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _lineFollowerController = TextEditingController(
      text: widget.initialSettings.lineFollowerMode,
    );
    _obstacleAvoidanceController = TextEditingController(
      text: widget.initialSettings.obstacleAvoidanceMode,
    );
    _followMeController = TextEditingController(
      text: widget.initialSettings.followMeMode,
    );
    _manualModeController = TextEditingController(
      text: widget.initialSettings.manualMode,
    );
    _forwardController = TextEditingController(
      text: widget.initialSettings.forward,
    );
    _backwardController = TextEditingController(
      text: widget.initialSettings.backward,
    );
    _leftController = TextEditingController(text: widget.initialSettings.left);
    _rightController = TextEditingController(text: widget.initialSettings.right);
    _stopController = TextEditingController(text: widget.initialSettings.stop);
    _forwardLeftController = TextEditingController(
      text: widget.initialSettings.forwardLeft,
    );
    _forwardRightController = TextEditingController(
      text: widget.initialSettings.forwardRight,
    );
    _backwardLeftController = TextEditingController(
      text: widget.initialSettings.backwardLeft,
    );
    _backwardRightController = TextEditingController(
      text: widget.initialSettings.backwardRight,
    );
  }

  @override
  void dispose() {
    _lineFollowerController.dispose();
    _obstacleAvoidanceController.dispose();
    _followMeController.dispose();
    _manualModeController.dispose();
    _forwardController.dispose();
    _backwardController.dispose();
    _leftController.dispose();
    _rightController.dispose();
    _stopController.dispose();
    _forwardLeftController.dispose();
    _forwardRightController.dispose();
    _backwardLeftController.dispose();
    _backwardRightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Settings'),
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Customize the Bluetooth command sent for each RC car action. Speed commands stay fixed as single digits from 0 to 9.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _CommandSection(
                title: 'Drive Modes',
                children: [
                  _CommandField(
                    label: 'Manual Mode',
                    controller: _manualModeController,
                  ),
                  _CommandField(
                    label: 'Follow Line',
                    controller: _lineFollowerController,
                  ),
                  _CommandField(
                    label: 'Auto Mode',
                    controller: _obstacleAvoidanceController,
                  ),
                  _CommandField(
                    label: 'Follow Me',
                    controller: _followMeController,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CommandSection(
                title: 'Basic Movement',
                children: [
                  _CommandField(
                    label: 'Stop',
                    controller: _stopController,
                  ),
                  _CommandField(
                    label: 'Forward',
                    controller: _forwardController,
                  ),
                  _CommandField(
                    label: 'Backward',
                    controller: _backwardController,
                  ),
                  _CommandField(
                    label: 'Left',
                    controller: _leftController,
                  ),
                  _CommandField(
                    label: 'Right',
                    controller: _rightController,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CommandSection(
                title: 'Diagonal Movement',
                children: [
                  _CommandField(
                    label: 'Forward Left',
                    controller: _forwardLeftController,
                  ),
                  _CommandField(
                    label: 'Forward Right',
                    controller: _forwardRightController,
                  ),
                  _CommandField(
                    label: 'Backward Left',
                    controller: _backwardLeftController,
                  ),
                  _CommandField(
                    label: 'Backward Right',
                    controller: _backwardRightController,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Save Commands'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetToDefaults() {
    final defaults = CommandSettings.defaults();
    _lineFollowerController.text = defaults.lineFollowerMode;
    _obstacleAvoidanceController.text = defaults.obstacleAvoidanceMode;
    _followMeController.text = defaults.followMeMode;
    _manualModeController.text = defaults.manualMode;
    _forwardController.text = defaults.forward;
    _backwardController.text = defaults.backward;
    _leftController.text = defaults.left;
    _rightController.text = defaults.right;
    _stopController.text = defaults.stop;
    _forwardLeftController.text = defaults.forwardLeft;
    _forwardRightController.text = defaults.forwardRight;
    _backwardLeftController.text = defaults.backwardLeft;
    _backwardRightController.text = defaults.backwardRight;
    setState(() {});
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final settings = CommandSettings(
      lineFollowerMode: _lineFollowerController.text,
      obstacleAvoidanceMode: _obstacleAvoidanceController.text,
      followMeMode: _followMeController.text,
      manualMode: _manualModeController.text,
      forward: _forwardController.text,
      backward: _backwardController.text,
      left: _leftController.text,
      right: _rightController.text,
      stop: _stopController.text,
      forwardLeft: _forwardLeftController.text,
      forwardRight: _forwardRightController.text,
      backwardLeft: _backwardLeftController.text,
      backwardRight: _backwardRightController.text,
    );

    await ref.read(appControllerProvider.notifier).saveCommandSettings(settings);
    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }
}

class _CommandSection extends StatelessWidget {
  const _CommandSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121A24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _CommandField extends StatelessWidget {
  const _CommandField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter command',
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Command required';
          }
          return null;
        },
      ),
    );
  }
}
