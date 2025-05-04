import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/models/project.dart';
import 'package:frontend/core/models/task.dart';
import 'package:frontend/core/services/project_service.dart';
import 'package:frontend/core/services/task_service.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/screens/projects/create_project_screen.dart';
import 'package:frontend/screens/projects/project_detail_screen.dart';
import 'package:frontend/screens/tasks/today_tasks_screen.dart';
import 'package:frontend/screens/tasks/task_detail_screen.dart';
import 'package:frontend/widgets/empty_state.dart';
import 'package:frontend/widgets/error_state.dart';
import 'package:frontend/widgets/recent_project_card.dart';
import 'package:frontend/widgets/task_item.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/home/projects_screen.dart';
import 'package:frontend/screens/home/notifications_screen.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/core/services/search_service.dart';
import 'package:frontend/screens/boards/board_detail_screen.dart';
import 'package:frontend/screens/search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isMenuOpen = false;
  final GlobalKey _fabKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Function(PointerEvent)? _pointerRouteCallback;

  final List<Widget> _screens = [
    const HomeContent(),
    const ProjectsScreen(),
    const SizedBox(), // Placeholder for the create button
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _removeOverlay();
    _removeGlobalRoute();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _removeGlobalRoute() {
    if (_pointerRouteCallback != null) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(
        _pointerRouteCallback!,
      );
      _pointerRouteCallback = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If auth is still initializing, show loading
    if (!authProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If user is not authenticated, redirect to login
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () {
          setState(() {
            _isMenuOpen = !_isMenuOpen;
          });
          if (_isMenuOpen) {
            _showPopupMenu();
          } else {
            _removeOverlay();
            _removeGlobalRoute();
          }
        },
        backgroundColor: AppColors.primary,
        child: Icon(_isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.folder_outlined, Icons.folder, 'Project'),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(
                3,
                Icons.chat_bubble_outline,
                Icons.chat_bubble,
                'Inbox',
              ),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  void _showPopupMenu() {
    _removeOverlay();
    _removeGlobalRoute();

    // Get the render box from the FAB's global key
    final RenderBox? renderBox =
        _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    // Calculate position for the popup menu (above the FAB)
    final double menuWidth = 200.0;
    final double menuHeight = 120.0; // Approximate height of the menu

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left:
                position.dx +
                (size.width / 2) -
                (menuWidth / 2), // Center horizontally over FAB
            top:
                position.dy -
                menuHeight -
                16, // Position above FAB with some padding
            width: menuWidth,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuOption(
                      icon: Icons.folder_open,
                      label: 'Create Project',
                      onTap: () {
                        _removeOverlay();
                        _removeGlobalRoute();
                        setState(() {
                          _isMenuOpen = false;
                        });
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateProjectScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuOption(
                      icon: Icons.group_add,
                      label: 'Create Group',
                      onTap: () {
                        _removeOverlay();
                        _removeGlobalRoute();
                        setState(() {
                          _isMenuOpen = false;
                        });
                        // Group creation functionality will be added later
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Group creation coming soon!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Define the callback function
    _pointerRouteCallback = (PointerEvent event) {
      if (event is PointerDownEvent && _isMenuOpen) {
        // Check if the tap is outside the menu area
        final Rect menuRect = Rect.fromLTWH(
          position.dx + (size.width / 2) - (menuWidth / 2),
          position.dy - menuHeight - 16,
          menuWidth,
          menuHeight,
        );

        // Check if the tap is outside the menu and outside the FAB
        final Rect fabRect = Rect.fromLTWH(
          position.dx,
          position.dy,
          size.width,
          size.height,
        );

        if (!menuRect.contains(event.position) &&
            !fabRect.contains(event.position)) {
          _removeOverlay();
          _removeGlobalRoute();
          setState(() {
            _isMenuOpen = false;
          });
        }
      }
    };

    // Add the callback to the global route
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _pointerRouteCallback!,
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 1) {
          // Navigate to ProjectsScreen instead of switching tabs
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProjectsScreen()));
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primary : Colors.grey,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<Project>> _projectsFuture;
  late Future<List<Task>> _tasksFuture;
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();
  final SearchService _searchService = SearchService();
  bool _isLoading = false;
  bool _isSearching = false;
  Map<String, dynamic>? _searchResults;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Authentication token is missing');
      }

      final results = await _searchService.search(authProvider.token!, query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching: $e')));
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        _projectsFuture = _projectService.getAllProjects(authProvider.token);
        _tasksFuture = _taskService.getTodayTasks(authProvider.token!);

        // Wait for both futures to complete
        await Future.wait([_projectsFuture, _tasksFuture]);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Task Management', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Search tasks, boards, and projects',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Search Results
                      if (_searchResults != null) ...[
                        if (_searchResults!['tasks'].isNotEmpty) ...[
                          const Text(
                            'Tasks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchResults!['tasks'].length,
                            itemBuilder: (context, index) {
                              final task = _searchResults!['tasks'][index];
                              return TaskItem(
                                title: task.title,
                                time:
                                    task.deadline != null
                                        ? '${task.deadline!.hour.toString().padLeft(2, '0')}:${task.deadline!.minute.toString().padLeft(2, '0')}'
                                        : 'No deadline',
                                isCompleted: task.status == 'Done',
                                task: task,
                                onStatusChanged: (completed) {
                                  _loadData();
                                },
                                onTap: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  TaskDetailScreen(task: task),
                                        ),
                                      )
                                      .then((result) {
                                        if (result == true) {
                                          _loadData();
                                        }
                                      });
                                },
                              );
                            },
                          ),
                        ],

                        if (_searchResults!['boards'].isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Boards',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchResults!['boards'].length,
                            itemBuilder: (context, index) {
                              final board = _searchResults!['boards'][index];
                              return ListTile(
                                title: Text(board.title),
                                subtitle: Text(
                                  'Project ID: ${board.projectId}',
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              BoardDetailScreen(board: board),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],

                        if (_searchResults!['projects'].isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Projects',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchResults!['projects'].length,
                            itemBuilder: (context, index) {
                              final project =
                                  _searchResults!['projects'][index];
                              return RecentProjectCard(
                                project: project,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ProjectDetailScreen(
                                            project: project,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],

                        if (_searchResults!['tasks'].isEmpty &&
                            _searchResults!['boards'].isEmpty &&
                            _searchResults!['projects'].isEmpty) ...[
                          const SizedBox(height: 16),
                          const Center(child: Text('No results found')),
                        ],
                      ] else ...[
                        // Recent Projects
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Project',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProjectsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Recent Projects List
                        SizedBox(
                          height: 300,
                          child: FutureBuilder<List<Project>>(
                            future: _projectsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return ErrorState(
                                  message: 'Failed to load projects',
                                  onRetry: () {
                                    _loadData();
                                  },
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const EmptyState(
                                  icon: Icons.folder_outlined,
                                  title: 'No Projects Yet',
                                  message:
                                      'Create your first project to get started',
                                );
                              } else {
                                final projects = snapshot.data!;
                                projects.sort(
                                  (a, b) => b.createdAt.compareTo(a.createdAt),
                                );
                                final recentProjects =
                                    projects.take(3).toList();

                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: recentProjects.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width -
                                            64,
                                        child: RecentProjectCard(
                                          project: recentProjects[index],
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => ProjectDetailScreen(
                                                      project:
                                                          recentProjects[index],
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Today's Tasks
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Today Task',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const TodayTasksScreen(),
                                      ),
                                    )
                                    .then((_) {
                                      _loadData();
                                    });
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Task List
                        FutureBuilder<List<Task>>(
                          future: _tasksFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return ErrorState(
                                message: 'Failed to load tasks',
                                onRetry: () {
                                  _loadData();
                                },
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const EmptyState(
                                icon: Icons.task_outlined,
                                title: 'No Tasks Today',
                                message:
                                    'You have no tasks scheduled for today',
                              );
                            } else {
                              final tasks = snapshot.data!;
                              tasks.sort((a, b) {
                                if (a.deadline == null) return 1;
                                if (b.deadline == null) return -1;
                                return a.deadline!.compareTo(b.deadline!);
                              });

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: tasks.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  final timeString =
                                      task.deadline != null
                                          ? 'Today - ${task.deadline!.hour.toString().padLeft(2, '0')}:${task.deadline!.minute.toString().padLeft(2, '0')}'
                                          : 'Today';

                                  return TaskItem(
                                    title: task.title,
                                    time: timeString,
                                    isCompleted: task.status == 'Done',
                                    task: task,
                                    onStatusChanged: (completed) {
                                      _loadData();
                                    },
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => TaskDetailScreen(
                                                    task: task,
                                                  ),
                                            ),
                                          )
                                          .then((result) {
                                            if (result == true) {
                                              _loadData();
                                            }
                                          });
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
