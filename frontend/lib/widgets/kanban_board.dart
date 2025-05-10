import 'package:flutter/material.dart';
import 'package:frontend/core/models/board.dart';
import 'package:frontend/core/models/task.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/models/project.dart';
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
  final List<User> projectMembers;
  final Project project;

  const KanbanBoard({
    super.key,
    required this.boards,
    required this.boardTasks,
    required this.onRefresh,
    required this.projectId,
    required this.projectMembers,
    required this.project,
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
        final columnWidth = constraints.maxWidth < (_orderedBoards.length * 280)
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isOwner = widget.project.manager == currentUserId;
    final isAdmin = authProvider.user?.role.toLowerCase() == 'admin';
    final isManager = authProvider.user?.role.toLowerCase() == 'manager';

    // Debug prints
    debugPrint('Current User ID: $currentUserId');
    debugPrint('Project Manager ID: ${widget.project.manager}');
    debugPrint('Is Owner: $isOwner');
    debugPrint('Is Admin: $isAdmin');
    debugPrint('Is Manager: $isManager');

    if (!isOwner && !isAdmin && !isManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Only project owners, admins, and managers can reorder boards'),
        ),
      );
      return;
    }

    // Store original order in case we need to revert
    final originalOrder = List<Board>.from(_orderedBoards);

    setState(() {
      // Update the local order first for immediate feedback
      final movedBoard = _orderedBoards.removeAt(currentIndex);
      _orderedBoards.insert(newIndex, movedBoard);
    });

    try {
      if (authProvider.token == null) return;

      // Prepare the board orders for the API
      final boardOrders = _orderedBoards.asMap().entries.map((entry) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reordering boards: $e')),
      );

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
                  if (details.data == null || details.data.board == board.id) {
                    return false;
                  }

                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final currentUserId = authProvider.user?.id;
                  final isTaskLeader = details.data.leader.id == currentUserId;
                  final isAdmin =
                      authProvider.user?.role.toLowerCase() == 'admin';
                  final isManager =
                      authProvider.user?.role.toLowerCase() == 'manager';
                  final isOwner = widget.project.manager == currentUserId;

                  // Debug prints
                  debugPrint('Current User ID: $currentUserId');
                  debugPrint('Task Leader ID: ${details.data.leader.id}');
                  debugPrint('Project Manager ID: ${widget.project.manager}');
                  debugPrint('Is Task Leader: $isTaskLeader');
                  debugPrint('Is Admin: $isAdmin');
                  debugPrint('Is Manager: $isManager');
                  debugPrint('Is Owner: $isOwner');

                  return isTaskLeader || isAdmin || isManager || isOwner;
                },
                onAcceptWithDetails: (details) async {
                  if (_isMovingTask) return;

                  setState(() {
                    _isMovingTask = true;
                  });

                  try {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
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
                onPressed: () {
                  _showCreateTaskDialog(context, board.id);
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
                onPressed: index < _orderedBoards.length - 1
                    ? () => _moveBoard(index, index + 1)
                    : null,
                color: index < _orderedBoards.length - 1
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isTaskLeader = task.leader.id == currentUserId;
    final isAdmin = authProvider.user?.role.toLowerCase() == 'admin';

    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(task.title),
        ),
      ),
      childWhenDragging: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isTaskLeader)
                      const Tooltip(
                        message: 'Task Leader',
                        child: Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d')
                          .format(task.deadline ?? DateTime.now()),
                      style: TextStyle(
                        color: task.deadline?.isBefore(DateTime.now()) ?? false
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      task.priority,
                      style: TextStyle(
                        color: _getPriorityColor(task.priority),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showCreateTaskDialog(BuildContext context, String boardId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(
          boardId: boardId,
          projectMembers: widget.projectMembers,
          projectId: widget.projectId,
        ),
      ),
    );
    if (result == true) {
      widget.onRefresh();
    }
  }
}
