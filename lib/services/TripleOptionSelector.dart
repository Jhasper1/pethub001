import 'package:flutter/material.dart';

class TripleOptionSelector extends StatelessWidget {
  final String? selectedOption;
  final String question;
  final List<String> options;
  final void Function(String) onChanged;

  const TripleOptionSelector({
    super.key,
    required this.selectedOption,
    required this.question,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: options.map((option) {
            final isSelected = selectedOption == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: isSelected ? Colors.blue : Colors.grey),
                  color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(option),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
