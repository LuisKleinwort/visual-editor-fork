import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../controller/controllers/editor-controller.dart';
import '../../../document/models/attributes/attribute.model.dart';
import '../../../document/models/attributes/attributes-aliases.model.dart';
import '../../../document/models/attributes/attributes.model.dart';
import '../../../document/services/nodes/attribute.utils.dart';
import '../../../editor/services/run-build.service.dart';
import '../../../shared/models/editor-icon-theme.model.dart';
import '../../../shared/state/editor-state-receiver.dart';
import '../../../shared/state/editor.state.dart';
import '../../../styles/services/styles.service.dart';
import '../toolbar.dart';

// Renders 3 buttons for the 3 potential alignments (left, center, right)
// TODO Split in methods
// ignore: must_be_immutable
class SelectAlignmentButtons extends StatefulWidget with EditorStateReceiver {
  final EditorController controller;
  final double iconSize;
  final EditorIconThemeM? iconTheme;
  final bool? showLeftAlignment;
  final bool? showCenterAlignment;
  final bool? showRightAlignment;
  final bool? showJustifyAlignment;
  final double buttonsSpacing;
  late EditorState _state;

  SelectAlignmentButtons({
    required this.controller,
    required this.buttonsSpacing,
    this.iconSize = defaultIconSize,
    this.iconTheme,
    this.showLeftAlignment,
    this.showCenterAlignment,
    this.showRightAlignment,
    this.showJustifyAlignment,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);
  }

  @override
  _SelectAlignmentButtonsState createState() => _SelectAlignmentButtonsState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class _SelectAlignmentButtonsState extends State<SelectAlignmentButtons> {
  late final RunBuildService _runBuildService;
  late final StylesService _stylesService;

  AttributeM? _value;
  StreamSubscription? _runBuild$L;

  @override
  void initState() {
    _runBuildService = RunBuildService(widget._state);
    _stylesService = StylesService(widget._state);

    super.initState();
    setState(() {
      _value = _attributes?[AttributesM.align.key] ??
          AttributesAliasesM.leftAlignment;
    });
    _subscribeToRunBuild();
  }

  @override
  Widget build(BuildContext context) {
    final _valueToText = <AttributeM, String>{
      if (widget.showLeftAlignment!)
        AttributesAliasesM.leftAlignment:
            AttributesAliasesM.leftAlignment.value!,
      if (widget.showCenterAlignment!)
        AttributesAliasesM.centerAlignment:
            AttributesAliasesM.centerAlignment.value!,
      if (widget.showRightAlignment!)
        AttributesAliasesM.rightAlignment:
            AttributesAliasesM.rightAlignment.value!,
      if (widget.showJustifyAlignment!)
        AttributesAliasesM.justifyAlignment:
            AttributesAliasesM.justifyAlignment.value!,
    };

    final _valueAttribute = <AttributeM>[
      if (widget.showLeftAlignment!) AttributesAliasesM.leftAlignment,
      if (widget.showCenterAlignment!) AttributesAliasesM.centerAlignment,
      if (widget.showRightAlignment!) AttributesAliasesM.rightAlignment,
      if (widget.showJustifyAlignment!) AttributesAliasesM.justifyAlignment
    ];
    final _valueString = <String>[
      if (widget.showLeftAlignment!) AttributesAliasesM.leftAlignment.value!,
      if (widget.showCenterAlignment!)
        AttributesAliasesM.centerAlignment.value!,
      if (widget.showRightAlignment!) AttributesAliasesM.rightAlignment.value!,
      if (widget.showJustifyAlignment!)
        AttributesAliasesM.justifyAlignment.value!,
    ];

    final theme = Theme.of(context);

    final buttonCount = ((widget.showLeftAlignment!) ? 1 : 0) +
        ((widget.showCenterAlignment!) ? 1 : 0) +
        ((widget.showRightAlignment!) ? 1 : 0) +
        ((widget.showJustifyAlignment!) ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(buttonCount, (index) {
        return Container(
          // ignore: prefer_const_constructors
          margin: EdgeInsets.symmetric(
            horizontal: !kIsWeb ? 1.0 : widget.buttonsSpacing,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: widget.iconSize * iconButtonFactor,
              height: widget.iconSize * iconButtonFactor,
            ),
            child: RawMaterialButton(
              hoverElevation: 0,
              highlightElevation: 0,
              elevation: 0,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(widget.iconTheme?.borderRadius ?? 2),
              ),
              fillColor: _valueToText[_value] == _valueString[index]
                  ? (widget.iconTheme?.iconSelectedFillColor ??
                      theme.toggleableActiveColor)
                  : (widget.iconTheme?.iconUnselectedFillColor ??
                      theme.canvasColor),
              // Export a nice and clean version of this method in the styles service. Similar to other buttons.
              onPressed: () =>
                  _valueAttribute[index] == AttributesAliasesM.leftAlignment
                      ? _stylesService.formatSelection(
                          AttributeUtils.clone(AttributesM.align, null),
                        )
                      : _stylesService.formatSelection(_valueAttribute[index]),
              child: Icon(
                _valueString[index] == AttributesAliasesM.leftAlignment.value
                    ? Icons.format_align_left
                    : _valueString[index] ==
                            AttributesAliasesM.centerAlignment.value
                        ? Icons.format_align_center
                        : _valueString[index] ==
                                AttributesAliasesM.rightAlignment.value
                            ? Icons.format_align_right
                            : Icons.format_align_justify,
                size: widget.iconSize,
                color: _valueToText[_value] == _valueString[index]
                    ? (widget.iconTheme?.iconSelectedColor ??
                        theme.primaryIconTheme.color)
                    : (widget.iconTheme?.iconUnselectedColor ??
                        theme.iconTheme.color),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  void didUpdateWidget(covariant SelectAlignmentButtons oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If a new controller was generated by setState() in the parent
    // we need to subscribe to the new state store.
    if (oldWidget.controller != widget.controller) {
      _runBuild$L?.cancel();
      widget.controller.setStateInEditorStateReceiver(widget);
      _subscribeToRunBuild();
      _value = _attributes?[AttributesM.align.key] ??
          AttributesAliasesM.leftAlignment;
    }
  }

  @override
  void dispose() {
    _runBuild$L?.cancel();
    super.dispose();
  }

  // === UTILS ===

  Map<String, AttributeM>? get _attributes =>
      _stylesService.getSelectionStyle().attributes;

  void _subscribeToRunBuild() {
    _runBuild$L = _runBuildService.runBuild$.listen(
      (_) => setState(() {
        _value = _attributes?[AttributesM.align.key] ??
            AttributesAliasesM.leftAlignment;
      }),
    );
  }
}
