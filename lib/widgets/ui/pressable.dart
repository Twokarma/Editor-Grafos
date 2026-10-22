import 'package:flutter/material.dart';

class Pressable extends StatefulWidget{
  final VoidCallback? onTap;
  final Widget? child;
  final Widget Function(BuildContext context, bool hovered)? builder;
  final double hoverLift;
  final double pressScale;

  const Pressable({super.key, this.onTap, this.child, this.builder, this.hoverLift = 3, this.pressScale = 0.96}) : assert(child != null || builder != null);

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>{
  bool _hovered = false;
  bool _pressed = false;
  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context){
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);
    final content = widget.builder?.call(context, _hovered) ?? widget.child!;
    final lift = (!disableAnimations && _hovered && _enabled) ? -widget.hoverLift : 0.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) { if (mounted) setState(() => _hovered = false);},

        cursor: _enabled? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTapDown: _enabled? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled? () => setState(() => _pressed = false) : null,

          onTap: widget.onTap,

          behavior: HitTestBehavior.opaque,

          child: AnimatedContainer(
            transform: Matrix4.translationValues(0, lift, 0),
            duration: !disableAnimations? Duration(milliseconds: 250) : Duration.zero,
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
                scale: _pressed && !disableAnimations? widget.pressScale : 1,
                duration: !disableAnimations? Duration(milliseconds: 150) : Duration.zero,
                child: content,
            ),
          ),
        ),
      ),
    );
  }
}