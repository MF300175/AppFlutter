import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/task.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  final Function(ThemeMode)? onChangeThemeMode;
  final ThemeMode? currentThemeMode;

  const TaskListScreen({
    super.key,
    this.onChangeThemeMode,
    this.currentThemeMode,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Category> _categories = [];
  String _filter = 'all'; // all, completed, pending
  String? _categoryFilter; // null = todas as categorias
  String _searchQuery = ''; // Busca de tarefas
  String _sortBy = 'date'; // date, priority, title
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseService.instance.readAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await DatabaseService.instance.readAll();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
    await _syncNotifications(tasks);
  }

  Future<void> _syncNotifications(List<Task> tasks) async {
    for (final task in tasks) {
      await _handleNotificationForTask(task);
    }
  }

  List<Task> get _filteredTasks {
    List<Task> filtered;

    // Filtro por status
    switch (_filter) {
      case 'completed':
        filtered = _tasks.where((t) => t.completed).toList();
        break;
      case 'pending':
        filtered = _tasks.where((t) => !t.completed).toList();
        break;
      default:
        filtered = _tasks;
    }

    // Filtro por categoria
    if (_categoryFilter != null) {
      filtered =
          filtered.where((t) => t.categoryId == _categoryFilter).toList();
    }

    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Ordenação
    switch (_sortBy) {
      case 'priority':
        final priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
        filtered.sort((a, b) {
          final orderA = priorityOrder[a.priority] ?? 2;
          final orderB = priorityOrder[b.priority] ?? 2;
          return orderA.compareTo(orderB);
        });
        break;
      case 'title':
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'date':
      default:
        // Ordenar por data de vencimento (tarefas vencidas primeiro)
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) {
            // Se nenhuma tem data de vencimento, ordenar por data de criação
            return b.createdAt.compareTo(a.createdAt);
          }
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final aDue =
              DateTime(a.dueDate!.year, a.dueDate!.month, a.dueDate!.day);
          final bDue =
              DateTime(b.dueDate!.year, b.dueDate!.month, b.dueDate!.day);

          final aOverdue = !a.completed && aDue.isBefore(today);
          final bOverdue = !b.completed && bDue.isBefore(today);

          if (aOverdue && !bOverdue) return -1;
          if (!aOverdue && bOverdue) return 1;

          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
    }

    return filtered;
  }

  int get _overdueCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.dueDate == null || t.completed) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isBefore(today);
    }).length;
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    await _handleNotificationForTask(updated);
    await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    // Confirmar exclusão
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.delete(task.id);
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa excluída'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openTaskForm([Task? task]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result == true) {
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Menu de Tema
          if (widget.onChangeThemeMode != null)
            PopupMenuButton<ThemeMode>(
              icon: Icon(
                widget.currentThemeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : widget.currentThemeMode == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.brightness_auto,
              ),
              tooltip: 'Alternar tema',
              onSelected: (mode) {
                widget.onChangeThemeMode!(mode);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      const Icon(Icons.light_mode),
                      const SizedBox(width: 8),
                      const Text('Tema Claro'),
                      if (widget.currentThemeMode == ThemeMode.light)
                        const SizedBox(width: 8),
                      if (widget.currentThemeMode == ThemeMode.light)
                        const Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      const Icon(Icons.dark_mode),
                      const SizedBox(width: 8),
                      const Text('Tema Escuro'),
                      if (widget.currentThemeMode == ThemeMode.dark)
                        const SizedBox(width: 8),
                      if (widget.currentThemeMode == ThemeMode.dark)
                        const Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_auto),
                      const SizedBox(width: 8),
                      const Text('Seguir Sistema'),
                      if (widget.currentThemeMode == ThemeMode.system)
                        const SizedBox(width: 8),
                      if (widget.currentThemeMode == ThemeMode.system)
                        const Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          // Menu de Ordenação
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Ordenar por Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.flag),
                    SizedBox(width: 8),
                    Text('Ordenar por Prioridade'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Ordenar por Título'),
                  ],
                ),
              ),
            ],
          ),
          // Filtro por Categoria
          PopupMenuButton<String?>(
            icon: const Icon(Icons.category),
            onSelected: (value) => setState(() => _categoryFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Todas as Categorias'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ..._categories.map((category) {
                return PopupMenuItem<String?>(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(category.icon, color: category.color),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }),
            ],
          ),
          // Filtro por Status
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Todas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending_actions),
                    SizedBox(width: 8),
                    Text('Pendentes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Concluídas'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData();
                  break;
                case 'import':
                  _importData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Exportar tarefas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Importar tarefas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar tarefas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Alerta de Tarefas Vencidas
          if (_overdueCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Você tem $_overdueCount tarefa${_overdueCount > 1 ? 's' : ''} vencida${_overdueCount > 1 ? 's' : ''}!',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Card de Estatísticas
          if (_tasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.list,
                    'Total',
                    stats['total'].toString(),
                  ),
                  _buildStatItem(
                    Icons.pending_actions,
                    'Pendentes',
                    stats['pending'].toString(),
                  ),
                  _buildStatItem(
                    Icons.check_circle,
                    'Concluídas',
                    stats['completed'].toString(),
                  ),
                ],
              ),
            ),

          // Lista de Tarefas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            Category? category;
                            if (task.categoryId != null &&
                                _categories.isNotEmpty) {
                              try {
                                category = _categories.firstWhere(
                                  (c) => c.id == task.categoryId,
                                );
                              } catch (e) {
                                category = null;
                              }
                            }
                            return TaskCard(
                              task: task,
                              category: category,
                              onTap: () => _openTaskForm(task),
                              onToggle: () => _toggleTask(task),
                              onDelete: () => _deleteTask(task),
                              onShare: () => _shareTask(task),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_filter) {
      case 'completed':
        message = 'Nenhuma tarefa concluída ainda';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        message = 'Nenhuma tarefa pendente';
        icon = Icons.pending_actions;
        break;
      default:
        message = 'Nenhuma tarefa cadastrada';
        icon = Icons.task_alt;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openTaskForm(),
            icon: const Icon(Icons.add),
            label: const Text('Criar primeira tarefa'),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats() {
    return {
      'total': _tasks.length,
      'completed': _tasks.where((t) => t.completed).length,
      'pending': _tasks.where((t) => !t.completed).length,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _handleNotificationForTask(Task task) async {
    if (task.reminderDateTime != null && !task.completed) {
      if (task.reminderDateTime!.isAfter(DateTime.now())) {
        final body = task.dueDate != null
            ? 'Vencimento em ${_formatDate(task.dueDate!)}'
            : 'Não esqueça desta tarefa!';
        await NotificationService.scheduleTaskReminder(
          taskId: task.id,
          title: 'Lembrete: ${task.title}',
          body: body,
          scheduledAt: task.reminderDateTime!,
        );
        return;
      }
    }
    await NotificationService.cancelTaskReminder(task.id);
  }

  Future<void> _shareTask(Task task) async {
    final buffer = StringBuffer()
      ..writeln('Tarefa: ${task.title}')
      ..writeln('Prioridade: ${task.priority.toUpperCase()}')
      ..writeln('Status: ${task.completed ? 'Concluída' : 'Pendente'}');

    if (task.description.isNotEmpty) {
      buffer.writeln('Descrição: ${task.description}');
    }
    if (task.dueDate != null) {
      buffer.writeln('Vencimento: ${_formatDate(task.dueDate!)}');
    }
    if (task.reminderDateTime != null) {
      buffer.writeln(
          'Lembrete: ${_formatDate(task.reminderDateTime!)} ${task.reminderDateTime!.hour.toString().padLeft(2, '0')}:${task.reminderDateTime!.minute.toString().padLeft(2, '0')}');
    }

    await Share.share(
      buffer.toString(),
      subject: 'Tarefa: ${task.title}',
    );
  }

  Future<File> _getBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = p.join(directory.path, 'tasks_backup.json');
    return File(filePath);
  }

  Future<void> _exportData() async {
    try {
      final file = await _getBackupFile();
      final categories = await DatabaseService.instance.readAllCategories();
      final data = {
        'generatedAt': DateTime.now().toIso8601String(),
        'tasks': _tasks.map((task) => task.toMap()).toList(),
        'categories': categories.map((category) => category.toMap()).toList(),
      };
      await file.writeAsString(jsonEncode(data));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup salvo em ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importData() async {
    try {
      final file = await _getBackupFile();
      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Nenhum backup encontrado. Exporte antes de importar.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final content = await file.readAsString();
      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Estrutura de backup inválida.');
      }

      final tasksJson = decoded['tasks'];
      final categoriesJson = decoded['categories'];

      if (tasksJson is! List || categoriesJson is! List) {
        throw const FormatException(
            'Dados de tarefas ou categorias inválidos.');
      }

      final categories = categoriesJson
          .map((item) => Category.fromMap(Map<String, dynamic>.from(item)))
          .toList()
          .cast<Category>();
      final tasks = tasksJson
          .map((item) => Task.fromMap(Map<String, dynamic>.from(item)))
          .toList()
          .cast<Task>();

      await DatabaseService.instance.replaceAllCategories(categories);
      await DatabaseService.instance.replaceAllTasks(tasks);
      await _loadTasks();
      await _loadCategories();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados importados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
