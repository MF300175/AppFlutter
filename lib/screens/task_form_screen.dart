import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = criar novo, não-null = editar

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _priority = 'medium';
  bool _completed = false;
  bool _isLoading = false;
  DateTime? _dueDate;
  String? _selectedCategoryId;
  List<Category> _categories = [];
  DateTime? _reminderDateTime;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // Se estiver editando, preencher campos
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _completed = widget.task!.completed;
      _dueDate = widget.task!.dueDate;
      _selectedCategoryId = widget.task!.categoryId;
      _reminderDateTime = widget.task!.reminderDateTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseService.instance.readAllCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.task == null) {
        // Criar nova tarefa
        final newTask = Task(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          completed: _completed,
          dueDate: _dueDate,
          categoryId: _selectedCategoryId,
          reminderDateTime: _completed ? null : _reminderDateTime,
        );
        await DatabaseService.instance.create(newTask);
        await _handleNotification(newTask);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Tarefa criada com sucesso'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Atualizar tarefa existente
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          completed: _completed,
          dueDate: _dueDate,
          categoryId: _selectedCategoryId,
          reminderDateTime: _completed ? null : _reminderDateTime,
        );
        await DatabaseService.instance.update(updatedTask);
        await _handleNotification(updatedTask);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Tarefa atualizada com sucesso'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Retorna true = sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleNotification(Task task) async {
    if (task.reminderDateTime != null && !task.completed) {
      final body = task.dueDate != null
          ? 'Vencimento em ${task.dueDate!.day.toString().padLeft(2, '0')}/${task.dueDate!.month.toString().padLeft(2, '0')}'
          : 'Não esqueça desta tarefa!';
      await NotificationService.scheduleTaskReminder(
        taskId: task.id,
        title: 'Lembrete: ${task.title}',
        body: body,
        scheduledAt: task.reminderDateTime!,
      );
    } else {
      await NotificationService.cancelTaskReminder(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo de Título
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        hintText: 'Ex: Estudar Flutter',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, digite um título';
                        }
                        if (value.trim().length < 3) {
                          return 'Título deve ter pelo menos 3 caracteres';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),

                    const SizedBox(height: 16),

                    // Campo de Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Adicione mais detalhes...',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 5,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 16),

                    // Dropdown de Prioridade
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Baixa'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Média'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Alta'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Urgente'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Data de Vencimento
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dueDate = picked;
                            if (_reminderDateTime != null) {
                              _reminderDateTime = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                _reminderDateTime!.hour,
                                _reminderDateTime!.minute,
                              );
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de Vencimento (Opcional)',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dueDate != null
                                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                  : 'Selecione a data',
                              style: TextStyle(
                                fontSize: 16,
                                color: _dueDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                            if (_dueDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _dueDate = null;
                                    _reminderDateTime = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Horário de Lembrete
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.alarm),
                        title: const Text('Lembrete'),
                        subtitle: Text(
                          _reminderDateTime != null
                              ? 'Será lembrado em ${_reminderDateTime!.day.toString().padLeft(2, '0')}/${_reminderDateTime!.month.toString().padLeft(2, '0')} às ${_reminderDateTime!.hour.toString().padLeft(2, '0')}:${_reminderDateTime!.minute.toString().padLeft(2, '0')}'
                              : 'Nenhum lembrete configurado',
                        ),
                        trailing: _reminderDateTime != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _reminderDateTime = null;
                                  });
                                },
                              )
                            : null,
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          if (_dueDate == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Defina uma data de vencimento antes do lembrete.'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          final initialTime = _reminderDateTime != null
                              ? TimeOfDay.fromDateTime(_reminderDateTime!)
                              : TimeOfDay.now();

                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: initialTime,
                          );

                          if (!mounted || pickedTime == null) {
                            return;
                          }

                          final scheduledDate = DateTime(
                            _dueDate!.year,
                            _dueDate!.month,
                            _dueDate!.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );

                          if (scheduledDate.isBefore(DateTime.now())) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'O horário do lembrete deve ser no futuro.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _reminderDateTime = scheduledDate;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dropdown de Categoria
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria (Opcional)',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Nenhuma categoria'),
                        ),
                        ..._categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(category.icon,
                                    color: category.color, size: 20),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Switch de Completo
                    Card(
                      child: SwitchListTile(
                        title: const Text('Tarefa Completa'),
                        subtitle: Text(
                          _completed
                              ? 'Esta tarefa está marcada como concluída'
                              : 'Esta tarefa ainda não foi concluída',
                        ),
                        value: _completed,
                        onChanged: (value) {
                          setState(() {
                            _completed = value;
                            if (value) {
                              _reminderDateTime = null;
                            }
                          });
                        },
                        secondary: Icon(
                          _completed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _completed ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão Salvar
                    ElevatedButton.icon(
                      onPressed: _saveTask,
                      icon: const Icon(Icons.save),
                      label:
                          Text(isEditing ? 'Atualizar Tarefa' : 'Criar Tarefa'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Botão Cancelar
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
