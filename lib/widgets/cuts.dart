import 'package:flutter/material.dart';

/// Hard cut route: zero-duration transition. Anime editing grammar — hero
/// moments never crossfade.
Route<T> hardCut<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => page,
    );

/// Wrap a hard-cut destination in this to get the smash-cut white flash:
/// a near-1-frame full-screen white overlay that snaps away.
class SmashCutFlash extends StatefulWidget {
  const SmashCutFlash({super.key, required this.child});

  final Widget child;

  @override
  State<SmashCutFlash> createState() => _SmashCutFlashState();
}

class _SmashCutFlashState extends State<SmashCutFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  )..forward();

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: FadeTransition(
            opacity: ReverseAnimation(_flash),
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Types text on character by character, once. Used for the night-state
/// "NEXT EPISODE..." teaser line.
class TypeOnText extends StatefulWidget {
  const TypeOnText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<TypeOnText> createState() => _TypeOnTextState();
}

class _TypeOnTextState extends State<TypeOnText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 30 * widget.text.length),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final count = (_controller.value * widget.text.length).round();
        return Text(widget.text.substring(0, count), style: widget.style);
      },
    );
  }
}
