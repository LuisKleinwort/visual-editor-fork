import 'dart:async';

import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../editor/services/run-build.service.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../styles/services/styles.service.dart';
import '../toolbar.dart';
import 'shared/toggle-button.dart';

// Toggles on or off various styles in the document (bold, italic, underline, etc)
// ignore: must_be_immutable
class ToggleStyleButton extends StatefulWidget with EditorStateReceiver {
  // Used internally to retrieve the state from the EditorController instance to which this button is linked to.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  final AttributeM attribute;
  final IconData icon;
  final double iconSize;
  final Color? fillColor;
  final double buttonsSpacing;
  final EditorController controller;
  final EditorIconThemeM? iconTheme;
  late EditorState _state;

  ToggleStyleButton({
    required this.attribute,
    required this.icon,
    required this.buttonsSpacing,
    required this.controller,
    this.iconSize = defaultIconSize,
    this.fillColor,
    this.iconTheme,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  _ToggleStyleButtonState createState() => _ToggleStyleButtonState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _ToggleStyleButtonState extends State<ToggleStyleButton> {
  late final RunBuildService _runBuildService;
  late final StylesService _stylesService;

  bool? _isToggled;
  StreamSubscription? _runBuild$L;

  @override
  void initState() {
    _runBuildService = RunBuildService(widget._state);
    _stylesService = StylesService(widget._state);

    super.initState();
    _cacheIsToggled();
    _subscribeToRunBuild();
  }

  @override
  Widget build(BuildContext context) => ToggleButton(
        context: context,
        icon: widget.icon,
        buttonsSpacing: widget.buttonsSpacing,
        fillColor: widget.fillColor,
        isToggled: _isToggled,
        onPressed: () => _stylesService.toggleAttributeInSelection(
          widget.attribute,
        ),
        iconSize: widget.iconSize,
        iconTheme: widget.iconTheme,
      );

  @override
  void didUpdateWidget(covariant ToggleStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If a new controller was generated by setState() in the parent
    // we need to subscribe to the new state store.
    if (oldWidget.controller != widget.controller) {
      _runBuild$L?.cancel();
      widget.controller.setStateInEditorStateReceiver(widget);
      _subscribeToRunBuild();
      _cacheIsToggled();
    }
  }

  @override
  void dispose() {
    _runBuild$L?.cancel();
    super.dispose();
  }

  // === UTILS ===

  void _subscribeToRunBuild() {
    _runBuild$L = _runBuildService.runBuild$.listen(
      (_) => setState(_cacheIsToggled),
    );
  }

  bool _cacheIsToggled() {
    if (!_documentControllerInitialised) {
      return false;
    }

    return _isToggled =
        _stylesService.isAttributeToggledInSelection(widget.attribute);
  }

  bool get _documentControllerInitialised {
    return widget._state.refs.documentControllerInitialised == true;
  }
}
