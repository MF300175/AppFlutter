import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';

enum TaskFilter { all, completed, pending }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final _titleController = TextEditingController();
  String _selectedPriority = 'medium';
  TaskFilter _currentFilter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseService.instance.readAll();
    setState(() {
      _tasks = tasks;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      switch (_currentFilter) {
        case TaskFilter.all:
          _filteredTasks = _tasks;
          break;
        case TaskFilter.completed:
          _filteredTasks = _tasks.where((task) => task.completed).toList();
          break;
        case TaskFilter.pending:
          _filteredTasks = _tasks.where((task) => !task.completed).toList();
          break;
      }
    });
  }

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) return;

    final task = Task(
      title: _titleController.text.trim(),
      priority: _selectedPriority,
    );
    await DatabaseService.instance.create(task);
    _titleController.clear();
    _loadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    _loadTasks();
  }

  Future<void> _deleteTask(String id) async {
    await DatabaseService.instance.delete(id);
    _loadTasks();
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return '🟢 Baixa';
      case 'medium':
        return '🟡 Média';
      case 'high':
        return '🔴 Alta';
      default:
        return 'Média';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  int _getTotalTasks() => _tasks.length;
  int _getCompletedTasks() => _tasks.where((task) => task.completed).length;
  int _getPendingTasks() => _tasks.where((task) => !task.completed).length;

  Widget _buildCounterChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResponsiveCounters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se a largura disponível for menor que 300px, usar layout vertical
        if (constraints.maxWidth < 300) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCounterChip('Total', _getTotalTasks(), Colors.blue),
                  const SizedBox(width: 4),
                  _buildCounterChip('Completas', _getCompletedTasks(), Colors.green),
                ],
              ),
              const SizedBox(height: 2),
              _buildCounterChip('Pendentes', _getPendingTasks(), Colors.orange),
            ],
          );
        } else {
          // Layout horizontal para telas maiores
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCounterChip('Total', _getTotalTasks(), Colors.blue),
              const SizedBox(width: 4),
              _buildCounterChip('Completas', _getCompletedTasks(), Colors.green),
              const SizedBox(width: 4),
              _buildCounterChip('Pendentes', _getPendingTasks(), Colors.orange),
            ],
          );
        }
      },
    );
  }

  Widget _buildResponsiveFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se a largura for muito pequena, usar layout vertical
        if (constraints.maxWidth < 350) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtrar: '),
              const SizedBox(height: 8),
              SegmentedButton<TaskFilter>(
                segments: const [
                  ButtonSegment<TaskFilter>(
                    value: TaskFilter.all,
                    label: Text('Todas', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<TaskFilter>(
                    value: TaskFilter.pending,
                    label: Text('Pendentes', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<TaskFilter>(
                    value: TaskFilter.completed,
                    label: Text('Completas', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_currentFilter},
                onSelectionChanged: (Set<TaskFilter> selection) {
                  setState(() {
                    _currentFilter = selection.first;
                    _applyFilter();
                  });
                },
              ),
            ],
          );
        } else {
          // Layout horizontal para telas maiores
          return Row(
            children: [
              const Text('Filtrar: '),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<TaskFilter>(
                  segments: const [
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.all,
                      label: Text('Todas', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.pending,
                      label: Text('Pendentes', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment<TaskFilter>(
                      value: TaskFilter.completed,
                      label: Text('Completas', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_currentFilter},
                  onSelectionChanged: (Set<TaskFilter> selection) {
                    setState(() {
                      _currentFilter = selection.first;
                      _applyFilter();
                    });
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _buildResponsiveCounters(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Nova tarefa...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTask,
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Prioridade: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedPriority,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPriority = newValue!;
                          });
                        },
                        items: <String>['low', 'medium', 'high']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              _getPriorityLabel(value),
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildResponsiveFilters(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.completed,
                      onChanged: (_) => _toggleTask(task),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      _getPriorityLabel(task.priority),
                      style: TextStyle(
                        color: _getPriorityColor(task.priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteTask(task.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}







