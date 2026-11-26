import 'package:flutter/material.dart';
import 'package:notesflow/services/note_service.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  String selectedCategory = 'Personal';
  int isPinned = 0;
  int isFavorite = 0;
  bool isSaving = false;

  final List<String> categories = ['Personal', 'Study', 'Work', 'Ideas'];

  Color _categoryColor(String category) {
    switch (category) {
      case 'Study':
        return const Color(0xFF2563EB); // Royal Blue
      case 'Work':
        return const Color(0xFFD97706); // Warm Amber
      case 'Ideas':
        return const Color(0xFF0D9488); // Emerald Teal
      case 'Personal':
      default:
        return const Color(0xFF6C63FF); // Signature Indigo
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Study':
        return Icons.menu_book_rounded;
      case 'Work':
        return Icons.work_outline_rounded;
      case 'Ideas':
        return Icons.lightbulb_outline_rounded;
      case 'Personal':
      default:
        return Icons.person_outline_rounded;
    }
  }

  Future<void> saveNote() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title or note details.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Prefix category tag cleanly while keeping NoteService compatible
      final formattedTitle =
          '[$selectedCategory] ${title.isEmpty ? 'Untitled' : title}';

      await NoteService.instance.addNote(
        formattedTitle,
        content,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $selectedCategory!'),
          backgroundColor: _categoryColor(selectedCategory),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save note. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _categoryColor(selectedCategory);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: isPinned == 1 ? 'Unpin Note' : 'Pin Note',
            icon: Icon(
              isPinned == 1 ? Icons.push_pin : Icons.push_pin_outlined,
              color: isPinned == 1 ? activeColor : null,
            ),
            onPressed: () {
              setState(() => isPinned = isPinned == 1 ? 0 : 1);
            },
          ),
          IconButton(
            tooltip: isFavorite == 1 ? 'Remove Favorite' : 'Mark Favorite',
            icon: Icon(
              isFavorite == 1 ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFavorite == 1 ? Colors.amber.shade600 : null,
            ),
            onPressed: () {
              setState(() => isFavorite = isFavorite == 1 ? 0 : 1);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final catColor = _categoryColor(cat);
                    final isSelected = selectedCategory == cat;

                    return ChoiceChip(
                      avatar: Icon(
                        _categoryIcon(cat),
                        size: 18,
                        color: isSelected ? Colors.white : catColor,
                      ),
                      label: Text(cat),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: catColor,
                      backgroundColor: catColor.withValues(alpha: isDark ? 0.16 : 0.10),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : catColor,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? catColor
                            : catColor.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      onSelected: (_) {
                        setState(() => selectedCategory = cat);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.35),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 28,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: titleController,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Note title',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      Expanded(
                        child: TextField(
                          controller: contentController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                          decoration: const InputDecoration(
                            hintText: 'Write your thoughts',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : saveNote,
                  style: FilledButton.styleFrom(
                    backgroundColor: activeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save Note',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}