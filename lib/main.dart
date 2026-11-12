import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NoteApp());
}

class NoteApp extends StatefulWidget {
  const NoteApp({super.key});

  @override
  State<NoteApp> createState() => _NoteAppState();

  static _NoteAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_NoteAppState>();
}

class _NoteAppState extends State<NoteApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadGlobalTheme();
  }

  Future<void> _loadGlobalTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void updateTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData currentTheme = isDarkMode
        ? ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E), // Proper Dark Card Color
      colorSchemeSeed: const Color(0xFF6C63FF),
      brightness: Brightness.dark,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    )
        : ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      cardColor: Colors.white, // Proper Light Card Color
      colorSchemeSeed: const Color(0xFF6C63FF),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Notes',
      builder: (context, child) {
        return AnimatedTheme(
          data: currentTheme,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: child!,
        );
      },
      theme: currentTheme,
      home: const MainNavigationScreen(),
    );
  }
}

// Model Class
class Note {
  final int id;
  final String title;
  final String content;
  final String category;
  final bool isPinned;
  final bool isFavorite;
  final String date;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'Personal',
    this.isPinned = false,
    this.isFavorite = false,
    this.date = '',
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'Personal',
      isPinned: json['is_pinned'] == 1 || json['isPinned'] == true,
      isFavorite: json['is_favorite'] == 1 || json['isFavorite'] == true,
      date: json['created_at']?.toString() ?? json['date']?.toString() ?? '',
    );
  }
}

// Category color helper function
Color getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'work':
      return Colors.orange;
    case 'study':
      return Colors.blue;
    case 'ideas':
      return Colors.purple;
    case 'personal':
    default:
      return Colors.teal;
  }
}

// Main Navigation Shell containing Bottom Nav
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Note> notes = [];
  List<Note> trashNotes = [];
  bool isLoading = true;
   static const String baseUrl = "http://10.158.19.32:3002/api/notes";

  @override
  void initState() {
    super.initState();
    fetchNotes();
    fetchTrashNotes();
  }

  Future<void> fetchNotes() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(baseUrl));
      print("fetchNotes called");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final decodedData = jsonDecode(response.body);

      print("Decoded Data: $decodedData");

      List<dynamic> data = [];

      if (decodedData is List) {
        data = decodedData;
      } else if (decodedData is Map<String, dynamic> &&
          decodedData.containsKey("data")) {
        data = decodedData["data"];
      }

      print("Data Length: ${data.length}");

      setState(() {
        notes = data.map((e) => Note.fromJson(e)).toList();
        isLoading = false;
      });

      print("Notes Length: ${notes.length}");
      print(notes);

      print("Notes Length: ${notes.length}");
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching: $e");
    }
  }

  Future<void> fetchTrashNotes() async {
    try {
      final response = await http.get(Uri.parse("http://10.158.19.32:3002/api/trash"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          trashNotes = data.map((e) => Note.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching trash: $e");
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        fetchNotes();
        fetchTrashNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note moved to Trash'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  Future<void> restoreNote(int id) async {
    try {
      final response = await http.put(Uri.parse('http://10.158.19.32:3002/api/notes/restore/$id'));
      if (response.statusCode == 200) {
        fetchNotes();
        fetchTrashNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note restored successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      debugPrint("Error restoring note: $e");
    }
  }

  Future<void> toggleFavorite(Note note) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${note.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': note.title,
          'content': note.content,
          'category': note.category,
          'is_pinned': note.isPinned ? 1 : 0,
          'is_favorite': note.isFavorite ? 0 : 1,
        }),
      );
      if (response.statusCode == 200) {
        fetchNotes();
      }
    } catch (e) {
      debugPrint("Error updating favorite: $e");
    }
  }

  Future<void> togglePin(Note note) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${note.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': note.title,
          'content': note.content,
          'category': note.category,
          'is_pinned': note.isPinned ? 0 : 1,
          'is_favorite': note.isFavorite ? 1 : 0,
        }),
      );
      if (response.statusCode == 200) {
        fetchNotes();
      }
    } catch (e) {
      debugPrint("Error updating pin: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        notes: notes,
        isLoading: isLoading,
        onRefresh: () async {
          await fetchNotes();
          await fetchTrashNotes();
        },
        onDelete: deleteNote,
        onToggleFavorite: toggleFavorite,
        onTogglePin: togglePin,
        trashNotes: trashNotes,
      ),
      FavoritesScreen(
        notes: notes,
        isLoading: isLoading,
        onDelete: deleteNote,
        onToggleFavorite: toggleFavorite,
        onRefresh: fetchNotes,
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.note_alt_outlined), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

// 1. HomeScreen
class HomeScreen extends StatefulWidget {
  final List<Note> notes;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int) onDelete;
  final Future<void> Function(Note) onToggleFavorite;
  final Future<void> Function(Note) onTogglePin;
  final List<Note> trashNotes;

  const HomeScreen({
    super.key,
    required this.notes,
    required this.isLoading,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onTogglePin,
    required this.trashNotes,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final List<String> categories = ['All', 'Personal', 'Study', 'Work', 'Ideas'];

  // Delete Confirmation Dialog
  void _showDeleteDialog(int noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Note', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to move this note to trash?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete(noteId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Note> sortedNotes = List.from(widget.notes);
    sortedNotes.sort((a, b) => (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0));

    List<Note> filteredNotes = sortedNotes.where((note) {
      bool matchesCategory = selectedCategory == 'All' ||
          note.category.trim().toLowerCase() == selectedCategory.trim().toLowerCase();
      bool matchesSearch = note.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    int totalCount = widget.notes.length;
    int favoriteCount = widget.notes.where((n) => n.isFavorite).length;
    int pinnedCount = widget.notes.where((n) => n.isPinned).length;

    String todayString = DateTime.now().toIso8601String().substring(0, 10);
    int todayCount = widget.notes.where((n) {
      return n.date.startsWith(todayString);
    }).length;

    final cardBgColor = Theme.of(context).cardColor;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Notes',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrashScreen(
                            trashNotes: widget.trashNotes,
                            onRestore: (id) async {
                              final parentState = context.findAncestorStateOfType<_MainNavigationScreenState>();
                              if (parentState != null) {
                                await parentState.restoreNote(id);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDashboardCard('Total', '$totalCount', Icons.menu_rounded, Colors.blue.shade100, Colors.blue, cardBgColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDashboardCard('Favorites', '$favoriteCount', Icons.favorite, Colors.red.shade100, Colors.red, cardBgColor)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDashboardCard('Pinned', '$pinnedCount', Icons.push_pin, Colors.amber.shade100, Colors.amber.shade800, cardBgColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDashboardCard('Today', '$todayCount', Icons.calendar_today, Colors.green.shade100, Colors.green, cardBgColor)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    bool isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFFDCD6F7),
                        backgroundColor: cardBgColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.deepPurple.shade800 : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (selected) {
                          setState(() => selectedCategory = cat);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              widget.isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : filteredNotes.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No notes found', style: TextStyle(color: Colors.grey))))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];
                  final catColor = getCategoryColor(note.category);

                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditNoteScreen(note: note)),
                      );
                      widget.onRefresh();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(note.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                              IconButton(
                                icon: Icon(
                                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                  size: 20,
                                  color: note.isPinned ? Colors.amber : Colors.grey,
                                ),
                                onPressed: () => widget.onTogglePin(note),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(right: 8),
                              ),
                              IconButton(
                                icon: Icon(
                                  note.isFavorite ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => widget.onToggleFavorite(note),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(note.content, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              note.category,
                              style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(note.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
                                    onPressed: () => Share.share('${note.title}\n\n${note.content}'),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    onPressed: () => _showDeleteDialog(note.id),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen()),
          );
          widget.onRefresh();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count, IconData icon, Color bgColor, Color iconColor, Color cardBgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. FavoritesScreen
class FavoritesScreen extends StatelessWidget {
  final List<Note> notes;
  final bool isLoading;
  final Future<void> Function(int) onDelete;
  final Future<void> Function(Note) onToggleFavorite;
  final Future<void> Function() onRefresh;

  const FavoritesScreen({
    super.key,
    required this.notes,
    required this.isLoading,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteNotes = notes.where((n) => n.isFavorite).toList();
    final cardBgColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteNotes.isEmpty
          ? const Center(child: Text('No favorite notes yet', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoriteNotes.length,
        itemBuilder: (context, index) {
          final note = favoriteNotes[index];
          final catColor = getCategoryColor(note.category);

          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditNoteScreen(note: note)),
              );
              onRefresh();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(note.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(
                        icon: const Icon(Icons.favorite, size: 20, color: Colors.red),
                        onPressed: () => onToggleFavorite(note),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(note.content, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.category,
                      style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(note.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
                        onPressed: () => Share.share('${note.title}\n\n${note.content}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 3. SettingsScreen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeSetting();
  }

  Future<void> _loadThemeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemeSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    NoteApp.of(context)?.updateTheme(value);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.note_alt_rounded, color: Color(0xFF6C63FF)),
            SizedBox(width: 10),
            Text('My Notes', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Version 1.0.0\n\nA fast, clean, and full-stack personal notes app powered by Flutter, Node.js, and MySQL.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBgColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF6C63FF)),
                ),
                title: const Text('Dark Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: const Text('Enable Dark Theme', style: TextStyle(fontSize: 13, color: Colors.grey)),
                trailing: Switch(
                  activeColor: const Color(0xFF6C63FF),
                  value: isDarkMode,
                  onChanged: (val) {
                    setState(() => isDarkMode = val);
                    _saveThemeSetting(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Colors.blue),
                ),
                title: const Text('About This App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: const Text('Version 1.0.0 • App Details', style: TextStyle(fontSize: 13, color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                onTap: _showAboutDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. TrashScreen
class TrashScreen extends StatelessWidget {
  final List<Note> trashNotes;
  final Function(int) onRestore;

  const TrashScreen({super.key, required this.trashNotes, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final cardBgColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: trashNotes.isEmpty
          ? const Center(child: Text('Trash is Empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trashNotes.length,
        itemBuilder: (context, index) {
          final note = trashNotes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough)),
                      const SizedBox(height: 8),
                      Text(note.content, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  onPressed: () => onRestore(note.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 5. AddNoteScreen
class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  String selectedCategory = 'Personal';
  final List<String> categories = ['Personal', 'Study', 'Work', 'Ideas'];

  Future<void> saveNote() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse("http://10.158.19.32:3002/api/notes"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': titleController.text,
          'content': contentController.text,
          'category': selectedCategory,
          'is_pinned': 0,
          'is_favorite': 0,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note saved successfully!'),
              backgroundColor: Color(0xFF6C63FF),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving note: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Note', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  bool isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFFDCD6F7),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.deepPurple.shade800 : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        setState(() => selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('Title', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Write your note title',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Add details',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: saveNote,
                child: const Text('Save Note', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. EditNoteScreen
class EditNoteScreen extends StatefulWidget {
  final Note note;

  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late String selectedCategory;
  final List<String> categories = ['Personal', 'Study', 'Work', 'Ideas'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
    selectedCategory = categories.contains(widget.note.category) ? widget.note.category : 'Personal';
  }

  Future<void> updateNote() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) return;
    try {
      final response = await http.put(
        Uri.parse('http://10.158.19.32:3002/api/notes/${widget.note.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': titleController.text,
          'content': contentController.text,
          'category': selectedCategory,
          'is_pinned': widget.note.isPinned ? 1 : 0,
          'is_favorite': widget.note.isFavorite ? 1 : 0,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note updated successfully!'),
              backgroundColor: Color(0xFF6C63FF),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating note: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  bool isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFFDCD6F7),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.deepPurple.shade800 : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        setState(() => selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('Title', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Write your note title',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Add details',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: updateNote,
                child: const Text('Update Note', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}