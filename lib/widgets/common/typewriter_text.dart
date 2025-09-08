import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final bool showCursor;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 50),
    this.showCursor = true,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  String _displayedText = '';
  int _currentIndex = 0;
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      // If text changed, update displayed text
      if (widget.text.startsWith(_displayedText)) {
        // Text is being added, continue typing from where we left off
        _currentIndex = _displayedText.length;
        _continueTyping();
      } else {
        // Text completely changed, restart
        _displayedText = '';
        _currentIndex = 0;
        _startTyping();
      }
    }
  }

  void _startTyping() {
    if (_currentIndex < widget.text.length) {
      Future.delayed(widget.typingSpeed, () {
        if (mounted && _currentIndex < widget.text.length) {
          setState(() {
            _displayedText += widget.text[_currentIndex];
            _currentIndex++;
          });
          _startTyping();
        }
      });
    }
  }

  void _continueTyping() {
    if (_currentIndex < widget.text.length) {
      Future.delayed(widget.typingSpeed, () {
        if (mounted && _currentIndex < widget.text.length) {
          setState(() {
            _displayedText += widget.text[_currentIndex];
            _currentIndex++;
          });
          _continueTyping();
        }
      });
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(_displayedText, style: widget.style)),
        if (widget.showCursor && _currentIndex < widget.text.length)
          AnimatedBuilder(
            animation: _cursorController,
            builder: (context, child) {
              return Opacity(
                opacity: _cursorController.value,
                child: Text('|', style: widget.style),
              );
            },
          ),
      ],
    );
  }
}
