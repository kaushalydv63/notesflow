import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:notesflow/constants/colour.dart';
import 'package:notesflow/models/note_model.dart';
import 'package:notesflow/screen/add_note_screen.dart';
import 'package:notesflow/screen/edit.dart';
import 'package:notesflow/screen/profile_screen.dart';
import 'package:notesflow/services/note_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteService _noteService = NoteService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<NoteModel> _allNotes = [];
  List<NoteModel> _filteredNotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_applySearch);
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);
    final items = await _noteService.getNotes();
    if (!mounted) return;
    setState(() {
      _allNotes = items;
      _loading = false;
    });
    _applySearch();
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = List<NoteModel>.from(_allNotes);
      } else {
        _filteredNotes = _allNotes.where((note) {
          return note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  /// Extracts category from "[Category] Title" format, defaulting to "Personal".
  ({String category, String cleanTitle}) _parseNoteTitle(String rawTitle) {
    final match = RegExp(
      r'^\[(Personal|Study|Work|Ideas)\]\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(rawTitle.trim());

    if (match != null) {
      final rawCat = (match.group(1) ?? 'Personal').toLowerCase();
      final titlePart = (match.group(2) ?? '').trim();
      final normalizedCat = switch (rawCat) {
        'study' => 'Study',
        'work' => 'Work',
        'ideas' => 'Ideas',
        _ => 'Personal',
      };
      return (
      category: normalizedCat,
      cleanTitle: titlePart.isEmpty ? 'Untitled' : titlePart,
      );
    }

    return (
    category: 'Personal',
    cleanTitle: rawTitle.trim().isEmpty ? 'Untitled' : rawTitle.trim(),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Study':
        return const Color(0xFF2563EB);
      case 'Work':
        return const Color(0xFFD97706);
      case 'Ideas':
        return const Color(0xFF0D9488);
      case 'Personal':
      default:
        return const Color(0xFF6C63FF);
    }
  }

  Future<void> _confirmAndDeleteNote(NoteModel note, String displayTitle) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: Text('Are you sure you want to delete "$displayTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _noteService.deleteNote(note.id);
      if (!mounted) return;
      _loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted.')),
      );
    }
  }

  Future<void> _shareNote(NoteModel note) async {
    await Share.share('${note.title}\n\n${note.content}');
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y • $h:$min';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppColors.logoAsset,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('NoteFlow'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes by title or content...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 56,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _allNotes.isEmpty
                        ? 'No notes yet. Tap + to create your first note.'
                        : 'No matching notes found.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                final parsed = _parseNoteTitle(note.title);
                final catColor = _categoryColor(parsed.category);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: catColor.withValues(
                      alpha: isDark ? 0.14 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.45),
                      width: 1.3,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditNoteScreen(note: note),
                        ),
                      );
                      if (updated == true) _loadNotes();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 64,
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        parsed.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Share',
                                      visualDensity:
                                      VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints:
                                      const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.share_outlined,
                                        size: 19,
                                      ),
                                      onPressed: () =>
                                          _shareNote(note),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      tooltip: 'Delete',
                                      visualDensity:
                                      VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints:
                                      const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () =>
                                          _confirmAndDeleteNote(
                                            note,
                                            parsed.cleanTitle,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  parsed.cleanTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (note.content.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    note.content,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  _formatDate(note.updatedAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen()),
          );
          if (created == true) _loadNotes();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }
}