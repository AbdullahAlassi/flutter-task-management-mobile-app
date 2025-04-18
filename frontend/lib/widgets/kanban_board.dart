import 'package:flutter/material.dart';
import 'package:frontend/core/models/board.dart';
import 'package:frontend/core/models/task.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/services/board_service.dart';
import 'package:frontend/core/services/task_service.dart';
import 'package:frontend/screens/tasks/create_task_screen.dart';
import 'package:frontend/screens/tasks/task_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KanbanBoard extends StatefulWidget {
  final List<Board> boards;
  final Map<String, List<Task>> boardTasks;
  final VoidCallback onRefresh;
  final String projectId;

  const KanbanBoard({
    super.key,
    required this.boards,
    required this.boardTasks,
    required this.onRefresh,
    required this.projectId,
  });

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  final TaskService _taskService = TaskService();
  final BoardService _boardService = BoardService();
  bool _isMovingTask = false;
  List<Board> _orderedBoards = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _orderedBoards = List.from(widget.boards);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KanbanBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boards != widget.boards) {
      _orderedBoards = List.from(widget.boards);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate column width based on screen width
        final columnWidth =
            constraints.maxWidth < (_orderedBoards.length * 280)
                ? 280.0
                : constraints.maxWidth / _orderedBoards.length;

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_orderedBoards.length, (index) {
              final board = _orderedBoards[index];
              final tasks = widget.boardTasks[board.id] ?? [];
              return SizedBox(
                width: columnWidth,
                child: _buildBoardColumn(board, tasks, columnWidth, index),
              );
            }),
          ),
        );
      },
    );
  }

  // Move a board left or right
  void _moveBoard(int currentIndex, int newIndex) async {
    if (newIndex < 0 || newIndex >= _orderedBoards.length) return;

    // Store original order in case we need to revert
    final originalOrder = List<Board>.from(_orderedBoards);

    setState(() {
      // Update the local order first for immediate feedback
      final movedBoard = _orderedBoards.removeAt(currentIndex);
      _orderedBoards.insert(newIndex, movedBoard);
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) return;

      // Prepare the board orders for the API
      final boardOrders =
          _orderedBoards.asMap().entries.map((entry) {
            return {'boardId': entry.value.id, 'order': entry.key};
          }).toList();

      // Call the API to update board orders
      await _boardService.reorderBoards(
        authProvider.token!,
        widget.projectId,
        boardOrders,
      );

      // Refresh the boards to get the updated order from the server
      widget.onRefresh();
    } catch (e) {
      // Show error and revert to original order
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reordering boards: $e')));

      setState(() {
        _orderedBoards = originalOrder;
      });
    }
  }

  Widget _buildBoardColumn(
    Board board,
    List<Task> tasks,
    double width,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        color: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildBoardHeader(board, tasks.length, index),
            SizedBox(
              height: MediaQuery.of(context).size.height - 360,
              child: DragTarget<Task>(
                builder: (context, candidateData, rejectedData) {
                  return tasks.isEmpty
                      ? _buildEmptyColumn()
                      : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: tasks.length,
                        itemBuilder: (context, taskIndex) {
                          return _buildDraggableTaskCard(
                            tasks[taskIndex],
                            board.id,
                          );
                        },
                      );
                },
                onWillAcceptWithDetails: (details) {
                  // Only accept if the task is from a different board
                  return details.data != null && details.data.board != board.id;
                },
                onAcceptWithDetails: (details) async {
                  if (_isMovingTask) return; // Prevent multiple moves

                  setState(() {
                    _isMovingTask = true;
                  });

                  try {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    if (authProvider.token == null) return;

                    await _taskService.moveTask(
                      authProvider.token!,
                      details.data.id,
                      board.id,
                    );

                    widget.onRefresh();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error moving task: $e')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isMovingTask = false;
                      });
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardHeader(Board board, int taskCount, int index) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildStatusChip(board.status),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$taskCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateTaskScreen(boardId: board.id),
                    ),
                  );
                  if (result == true) {
                    widget.onRefresh();
                  }
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Add reordering controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Move left button
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed:
                    index > 0 ? () => _moveBoard(index, index - 1) : null,
                color: index > 0 ? Colors.blue : Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              // Reorder icon
              const Icon(Icons.swap_horiz, color: Colors.grey, size: 20),
              const SizedBox(width: 16),
              // Move right button
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 20),
                onPressed:
                    index < _orderedBoards.length - 1
                        ? () => _moveBoard(index, index + 1)
                        : null,
                color:
                    index < _orderedBoards.length - 1
                        ? Colors.blue
                        : Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'todo':
        chipColor = Colors.blue;
        break;
      case 'in_progress':
        chipColor = Colors.orange;
        break;
      case 'review':
        chipColor = Colors.purple;
        break;
      case 'done':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyColumn() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const Text(
        'No tasks yet',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildDraggableTaskCard(Task task, String boardId) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildTaskCard(task, boardId),
      ),
      child: _buildTaskCard(task, boardId),
    );
  }

  Widget _buildTaskCard(Task task, String boardId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // Add darker background color for task cards
      color: Colors.grey[200],
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          );
          if (result == true) {
            widget.onRefresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (task.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(task.deadline!),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _isDeadlineSoon(task.deadline!)
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
              if (task.assignees.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...task.assignees
                        .take(3)
                        .map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    if (task.assignees.length > 3)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey[400],
                        child: Text(
                          '+${task.assignees.length - 3}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getPriorityColor(task.priority),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDeadlineSoon(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return difference <= 3 && difference >= 0;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
