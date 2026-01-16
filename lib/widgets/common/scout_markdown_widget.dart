import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// A reusable markdown widget for displaying Scout AI responses.
/// Handles text transformation (converting literal \n to actual newlines)
/// and provides consistent styling across the app.
class ScoutMarkdownWidget extends StatelessWidget {
  final String data;
  final double fontSize;
  final Color? textColor;
  final double lineHeight;

  const ScoutMarkdownWidget({
    super.key,
    required this.data,
    this.fontSize = 14,
    this.textColor,
    this.lineHeight = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    // Transform the text: convert literal \n to actual newlines
    final transformedData = data.replaceAll('\\n', '\n');
    final color = textColor ?? Colors.grey[800]!;

    return MarkdownBlock(
      data: transformedData,
      config: MarkdownConfig(
        configs: [
          HrConfig(height: 0, color: Colors.transparent),
          PConfig(
            textStyle: TextStyle(
              fontSize: fontSize,
              color: color,
              height: lineHeight,
            ),
          ),
          H1Config(
            style: TextStyle(
              fontSize: fontSize + 4,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: lineHeight,
            ),
          ),
          H2Config(
            style: TextStyle(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: lineHeight,
            ),
          ),
          H3Config(
            style: TextStyle(
              fontSize: fontSize + 1,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: lineHeight,
            ),
          ),
          ListConfig(
            marker: (isOrdered, depth, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Text(
                  isOrdered ? '${index + 1}.' : '•',
                  style: TextStyle(fontSize: fontSize, color: color),
                ),
              );
            },
          ),
          BlockquoteConfig(
            sideColor: Colors.orange.shade300,
            textColor: Colors.grey[600]!,
          ),
          CodeConfig(
            style: TextStyle(
              fontSize: fontSize - 1,
              backgroundColor: Colors.grey[200],
              color: color,
            ),
          ),
          PreConfig(decoration: const BoxDecoration(color: Colors.transparent)),
        ],
      ),
    );
  }
}
