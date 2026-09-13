import 'package:flutter/material.dart';

class HoverBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool isHovered) builder;
  final VoidCallback? onHover;
  final VoidCallback? onExit;

  const HoverBuilder({
    super.key,
    required this.builder,
    this.onHover,
    this.onExit,
  });

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover?.call();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onExit?.call();
      },
      child: widget.builder(context, _isHovered),
    );
  }
}
