import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/category.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  const TaskCard({
    super.key,
    required this.task,
    this.category,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.onShare,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.flag;
    }
  }

  String _getPriorityLabel() {
    switch (task.priority) {
      case 'low':
        return 'Baixa';
      case 'medium':
        return 'Média';
      case 'high':
        return 'Alta';
      case 'urgent':
        return 'Urgente';
      default:
        return 'Média';
    }
  }

  bool _isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today) && !task.completed;
  }

  Widget _buildCategoryChip() {
    if (category == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category!.color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category!.icon,
            size: 14,
            color: category!.color,
          ),
          const SizedBox(width: 4),
          Text(
            category!.name,
            style: TextStyle(
              fontSize: 12,
              color: category!.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: task.completed ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.completed ? Colors.grey.shade300 : _getPriorityColor(),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: task.completed,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(width: 12),

              // Conteúdo Principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                        color: task.completed ? Colors.grey : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: task.completed
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Metadata Row
                    Row(
                      children: [
                        // Prioridade
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getPriorityColor(),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPriorityIcon(),
                                size: 14,
                                color: _getPriorityColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getPriorityLabel(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getPriorityColor(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Categoria
                        _buildCategoryChip(),

                        // Data de Vencimento
                        if (task.dueDate != null) ...[
                          Icon(
                            Icons.event,
                            size: 14,
                            color: _isOverdue(task.dueDate!)
                                ? Colors.red
                                : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isOverdue(task.dueDate!)
                                  ? Colors.red
                                  : Colors.blue,
                              fontWeight: _isOverdue(task.dueDate!)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        if (task.reminderDateTime != null) ...[
                          const Icon(
                            Icons.alarm,
                            size: 14,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.reminderDateTime!.hour.toString().padLeft(2, '0')}:${task.reminderDateTime!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Data de Criação
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(task.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Ações laterais
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onShare != null)
                    IconButton(
                      onPressed: onShare,
                      icon: const Icon(Icons.share),
                      tooltip: 'Compartilhar tarefa',
                    ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Deletar tarefa',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
