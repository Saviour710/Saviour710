import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const NotebookApp());
}

class NotebookApp extends StatelessWidget {
  const NotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notebook App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  NotesScreenState createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Load notes from SharedPreferences
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesString = prefs.getString('notes');
    if (notesString != null) {
      final List<dynamic> notesJson = jsonDecode(notesString);
      setState(() {
        notes = notesJson.map((json) => Note.fromJson(json)).toList();
      });
    }
  }

  // Save notes to SharedPreferences
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String notesJson = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString('notes', notesJson);
  }

  // Add or update a note
  void _addOrUpdateNote({Note? existingNote}) {
    showDialog(
      context: context,
      builder: (context) {
        if (existingNote != null) {
          _titleController.text = existingNote.title;
          _contentController.text = existingNote.content;
        } else {
          _titleController.clear();
          _contentController.clear();
        }

        return AlertDialog(
          title: Text(existingNote == null ? 'New Note' : 'Edit Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  setState(() {
                    if (existingNote == null) {
                      // Add new note
                      notes.add(Note(
                        id: DateTime.now().millisecondsSinceEpoch,
                        title: _titleController.text,
                        content: _contentController.text,
                        timestamp: DateTime.now(),
                      ));
                    } else {
                      // Update existing note
                      final index = notes.indexOf(existingNote);
                      notes[index] = Note(
                        id: existingNote.id,
                        title: _titleController.text,
                        content: _contentController.text,
                        timestamp: DateTime.now(),
                      );
                    }
                  });
                  _saveNotes();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Delete a note
  void _deleteNote(int id) {
    setState(() {
      notes.removeWhere((note) => note.id == id);
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notebook'),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('No notes yet. Add one!'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteNote(note.id),
                  ),
                  onTap: () => _addOrUpdateNote(existingNote: note),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateNote(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Note model class
class Note {
  final int id;
  final String title;
  final String content;
  final DateTime timestamp;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}
