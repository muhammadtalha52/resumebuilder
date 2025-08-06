import 'package:flutter/material.dart';

class TagList extends StatelessWidget {
  final List<String> tags;
  final List<Color>? colors;

  const TagList({super.key, required this.tags, this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(tags.length, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEBEEFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tags[index],
            style: const TextStyle(
              color: Color(0xFF0A33FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }),
    );
  }
}
