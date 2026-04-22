import 'package:flutter/material.dart';
import 'package:project_kim/features/inventory/data/models/tag_model.dart';

class TagInputWidget extends StatefulWidget {
  final List<TagModel> existingTags;
  final List<TagModel> selectedTags;
  final Function(TagModel tag) onAddTag;
  final Function(TagModel tag) onRemoveTag;

  const TagInputWidget({
    super.key,
    required this.existingTags,
    required this.selectedTags,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  List<TagModel> _getSuggestions(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) return [];

    return widget.existingTags
        .where((t) => t.name.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  bool _alreadySelected(TagModel tag) {
    return widget.selectedTags.any(
      (t) => t.name.toLowerCase() == tag.name.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Etiquetas",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Autocomplete<TagModel>(
          displayStringForOption: (tag) => tag.name,

          optionsBuilder: (TextEditingValue value) {
            return _getSuggestions(value.text);
          },

          onSelected: (TagModel tag) {
            if (_alreadySelected(tag)) return;

            widget.onAddTag(tag);
          },

          fieldViewBuilder: (
            context,
            textController,
            focusNode,
            onFieldSubmitted,
          ) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "Escriba una etiqueta...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: "Agregar etiqueta",
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;

                    final alreadyExists = widget.selectedTags.any(
                      (t) => t.name.toLowerCase() == text.toLowerCase(),
                    );

                    if (alreadyExists) {
                      textController.clear();
                      return;
                    }

                    final newTag = TagModel(
                      id: null,
                      name: text,
                      createdAt: DateTime.now(),
                    );

                    widget.onAddTag(newTag);
                    textController.clear();
                  },
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.selectedTags.map((tag) {
            return Chip(
              label: Text(tag.name),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () => widget.onRemoveTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}