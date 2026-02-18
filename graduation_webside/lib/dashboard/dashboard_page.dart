import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/chat_repository.dart';
import '../data/user_settings_repository.dart';
import '../data/workflow_repository.dart';

/// High-level sections that can be shown inside the dashboard content area.
/// The sidebar updates `_activeSection` with one of these values.
enum DashboardSection {
  dashboard,
  chat,
  history,
  integrations,
  settings,
}

/// Futuristic AstroBot dashboard UI for web & desktop.
class DashboardPage extends StatefulWidget {
  /// When [session] is null, the dashboard runs in "preview" mode"
  /// so you can build the frontend without real authentication.
  const DashboardPage({super.key, this.session});

  final Session? session;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Currently selected section from the left sidebar.
  DashboardSection _activeSection = DashboardSection.dashboard;

  // Shared Supabase client used for sign-out.
  SupabaseClient get _client => Supabase.instance.client;

  /// Signs the user out (only meaningful when a real `Session` is provided).
  Future<void> _signOut(BuildContext context) async {
    await _client.auth.signOut();
  }

  Future<void> _runDemoAutomation() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to run the backend demo.')),
      );
      return;
    }

    try {
      final res = await _client.functions.invoke(
        'send-reminder',
        body: const {'intent': 'Demo reminder from dashboard'},
      );

      final msg = (res.data is Map && (res.data as Map)['message'] is String)
          ? (res.data as Map)['message'] as String
          : 'Demo executed.';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      try {
        await WorkflowRepository(client: _client).insertRun(
          userId: user.id,
          intent: 'Demo reminder (fallback)',
          status: 'Completed',
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Edge Function not deployed yet. Saved a fallback history item instead. ($e)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the authenticated user's email when available, otherwise show "Guest user"
    // in the top-right profile chip.
    final userEmail = widget.session?.user.email ?? 'Guest user';

    return Scaffold(
      backgroundColor: const Color(0xFF050818),
      body: SafeArea(
        child: Stack(
          children: [
            const _SpaceBackground(),
            Row(
              children: [
                _AstroSidebar(
                  active: _activeSection,
                  onSectionSelected: (section) {
                    setState(() {
                      _activeSection = section;
                    });
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _DashboardContent(
                      userLabel: userEmail,
                      activeSection: _activeSection,
                      onSignOut: () => _signOut(context),
                      onRunDemo: _runDemoAutomation,
                      onBackToDashboard: () {
                        setState(() {
                          _activeSection = DashboardSection.dashboard;
                        });
                      },
                      onOpenChat: () {
                        setState(() {
                          _activeSection = DashboardSection.chat;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============= BACKGROUND =============

class _SpaceBackground extends StatelessWidget {
  const _SpaceBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF080B1F),
            Color(0xFF101733),
            Color(0xFF141A3F),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Soft radial glows
          Positioned(
            top: -120,
            right: -40,
            child: _GlowCircle(
              size: 260,
              color: Colors.blueAccent.withOpacity(0.35),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: _GlowCircle(
              size: 280,
              color: Colors.purpleAccent.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

// ============= SIDEBAR =============

class _AstroSidebar extends StatelessWidget {
  const _AstroSidebar({
    required this.active,
    required this.onSectionSelected,
  });

  final DashboardSection active;
  final ValueChanged<DashboardSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: _GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'image/asset/image/image2.jpeg',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CC9F0), Color(0xFF4361EE)],
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AstroBot',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SidebarItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                isActive: active == DashboardSection.dashboard,
                onTap: () => onSectionSelected(DashboardSection.dashboard),
              ),
              _SidebarItem(
                icon: Icons.chat_bubble_outline,
                label: 'Live Chat',
                isActive: active == DashboardSection.chat,
                onTap: () => onSectionSelected(DashboardSection.chat),
              ),
              _SidebarItem(
                icon: Icons.history,
                label: 'History',
                isActive: active == DashboardSection.history,
                onTap: () => onSectionSelected(DashboardSection.history),
              ),
              _SidebarItem(
                icon: Icons.extension,
                label: 'Integrations',
                isActive: active == DashboardSection.integrations,
                onTap: () => onSectionSelected(DashboardSection.integrations),
              ),
              _SidebarItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isActive: active == DashboardSection.settings,
                onTap: () => onSectionSelected(DashboardSection.settings),
              ),
              const Spacer(),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              const Text(
                'AI Workspace',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Designing intelligent workflows.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.isActive;
    final Color baseColor = Colors.white.withOpacity(isActive ? 0.95 : 0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isActive || _hovering
                ? Colors.white.withOpacity(0.12)
                : Colors.transparent,
            boxShadow: (isActive || _hovering)
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CC9F0).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: baseColor,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: baseColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= MAIN CONTENT =============

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.userLabel,
    required this.onSignOut,
    required this.activeSection,
    required this.onBackToDashboard,
    required this.onRunDemo,
    required this.onOpenChat,
  });

  final String userLabel;
  final VoidCallback onSignOut;
  final DashboardSection activeSection;
  final VoidCallback onBackToDashboard;
  final VoidCallback onRunDemo;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1100;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                userLabel: userLabel,
                onSignOut: onSignOut,
                activeSection: activeSection,
                onBackToDashboard: onBackToDashboard,
                onRunDemo: onRunDemo,
              ),
              const SizedBox(height: 20),
              if (activeSection == DashboardSection.dashboard) ...[
                const _HeroSection(),
                const SizedBox(height: 24),
                _MainGrid(isWide: isWide, onOpenChat: onOpenChat),
              ] else ...[
                _SectionContent(
                  section: activeSection,
                  isWide: isWide,
                  onOpenChat: onOpenChat,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ============= TOP BAR =============

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.userLabel,
    required this.onSignOut,
    required this.activeSection,
    required this.onBackToDashboard,
    required this.onRunDemo,
  });

  final String userLabel;
  final VoidCallback onSignOut;
  final DashboardSection activeSection;
  final VoidCallback onBackToDashboard;
  final VoidCallback onRunDemo;

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;

    switch (activeSection) {
      case DashboardSection.dashboard:
        title = 'Welcome back to AstroBot!';
        subtitle = 'Automate your tasks with intelligent AI workflows.';
        break;
      case DashboardSection.chat:
        title = 'Live Chat';
        subtitle = 'Chat with AstroBot—ask questions and automate tasks.';
        break;
      case DashboardSection.history:
        title = 'History';
        subtitle = 'Review recent workflows and executions.';
        break;
      case DashboardSection.integrations:
        title = 'Integrations';
        subtitle = 'Connect AstroBot to your favorite tools.';
        break;
      case DashboardSection.settings:
        title = 'Settings';
        subtitle = 'Adjust quick preferences for your workspace.';
        break;
    }

    final bool isRoot = activeSection == DashboardSection.dashboard ||
        activeSection == DashboardSection.chat;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isRoot)
          IconButton(
            onPressed: onBackToDashboard,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.white70,
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.5),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {},
              child: const Text('Learn More'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CC9F0),
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                shadowColor: const Color(0xFF4CC9F0).withOpacity(0.6),
              ),
              onPressed: onRunDemo,
              child: const Text('Get Started'),
            ),
            const SizedBox(width: 16),
            _GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: 32,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blueGrey.shade900,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    userLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: onSignOut,
                    icon: const Icon(
                      Icons.logout,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============= HERO SECTION (animated one-by-one) =============

class _HeroSection extends StatefulWidget {
  const _HeroSection();

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _animations = [
      _stagger(0.0, 0.18),
      _stagger(0.15, 0.33),
      _stagger(0.30, 0.48),
      _stagger(0.42, 0.58),
      _stagger(0.52, 0.68),
      _stagger(0.62, 0.78),
    ];
    _controller.forward();
  }

  Animation<double> _stagger(double start, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _animations[0],
                    child: const Text(
                      'Design your AI automations.',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _animations[1],
                    child: const Text(
                      'Build conversational workflows, connect your tools, and let AstroBot\n'
                      'handle repetitive tasks across your apps.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  FadeTransition(
                    opacity: _animations[2],
                    child: _HeroVisual(),
                  ),
                  Positioned(
                    top: 12,
                    right: 10,
                    child: FadeTransition(
                      opacity: _animations[3],
                      child: _FloatingNode(label: 'Workflow'),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: FadeTransition(
                      opacity: _animations[4],
                      child: _FloatingNode(label: 'Triggers'),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    right: 40,
                    child: FadeTransition(
                      opacity: _animations[5],
                      child: _FloatingNode(label: 'Actions'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  static const String _heroImageAsset = 'image/asset/image/image1.jpeg';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        _heroImageAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF00D2FF),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.smart_toy_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNode extends StatelessWidget {
  const _FloatingNode({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFF4CC9F0),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ============= MAIN GRID (CARDS + PANELS) =============

class _MainGrid extends StatelessWidget {
  const _MainGrid({required this.isWide, required this.onOpenChat});

  final bool isWide;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 3,
            child: _PrimaryPanels(),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _SidePanels(onOpenChat: onOpenChat),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PrimaryPanels(),
        const SizedBox(height: 20),
        _SidePanels(onOpenChat: onOpenChat),
      ],
    );
  }
}

class _PrimaryPanels extends StatelessWidget {
  const _PrimaryPanels();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AstroChatPanel(expanded: true),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: _WorkflowInsightsCard()),
            SizedBox(width: 16),
            Expanded(child: _RecentActivityCard()),
          ],
        ),
        const SizedBox(height: 16),
        const _WorkflowHistoryTable(),
      ],
    );
  }
}

/// Content shown in the main area when a non-dashboard section is active.
class _SectionContent extends StatelessWidget {
  const _SectionContent({
    required this.section,
    required this.isWide,
    required this.onOpenChat,
  });

  final DashboardSection section;
  final bool isWide;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    Widget main;

    switch (section) {
      case DashboardSection.dashboard:
        main = const _PrimaryPanels();
        break;
      case DashboardSection.chat:
        main = const _AstroChatPanel(expanded: true, fullPage: true);
        break;
      case DashboardSection.history:
        main = const _HistorySection();
        break;
      case DashboardSection.integrations:
        main = const _IntegrationsSection();
        break;
      case DashboardSection.settings:
        main = const _SettingsSection();
        break;
    }

    if (section == DashboardSection.chat) {
      return main;
    }

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: main),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _SidePanels(onOpenChat: onOpenChat)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        main,
        const SizedBox(height: 20),
        _SidePanels(onOpenChat: onOpenChat),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _WorkflowHistoryTable(),
      ],
    );
  }
}

class _IntegrationsSection extends StatelessWidget {
  const _IntegrationsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _ConnectedAppsPanel(),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _QuickSettingsPanel(),
      ],
    );
  }
}

class _SidePanels extends StatelessWidget {
  const _SidePanels({required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChatCard(onStartChat: onOpenChat),
        const SizedBox(height: 16),
        const _ConnectedAppsPanel(),
        const SizedBox(height: 16),
        const _QuickSettingsPanel(),
      ],
    );
  }
}

// ============= LIVE CHAT PANEL =============

class _AstroChatPanel extends StatefulWidget {
  const _AstroChatPanel({this.expanded = false, this.fullPage = false});

  final bool expanded;
  /// When true (e.g. on the dedicated Live Chat page), use max height for messages.
  final bool fullPage;

  @override
  State<_AstroChatPanel> createState() => _AstroChatPanelState();
}

class _AstroChatPanelState extends State<_AstroChatPanel> {
  final _repo = ChatRepository();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = false;
  List<ChatMessage> _messages = const [];

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;
  bool get _isGuest => _userId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ChatMessage> _demoMessages() {
    return [
      ChatMessage(
        role: ChatRole.bot,
        content: 'Hi, I\'m AstroBot. What would you like to automate today?',
        createdAt: null,
      ),
      ChatMessage(
        role: ChatRole.user,
        content: 'Show me my recent automated tasks.',
        createdAt: null,
      ),
    ];
  }

  Future<void> _load() async {
    if (_isGuest) {
      setState(() => _messages = _demoMessages());
      return;
    }

    setState(() => _isLoading = true);
    try {
      final msgs = await _repo.fetchRecentMessages(userId: _userId!, limit: 30);
      if (!mounted) return;
      setState(() => _messages = msgs);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chat: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  String _demoBotReply(String userText) {
    final t = userText.trim();
    if (t.isEmpty) return 'Tell me what you want to automate.';
    return 'Got it. I saved that request and added it to your history (demo).';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save chat history.')),
      );
      return;
    }

    _controller.clear();
    final now = DateTime.now();
    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(role: ChatRole.user, content: text, createdAt: now),
      ];
    });
    _scrollToBottom();

    try {
      final userId = _userId!;
      await _repo.addMessage(userId: userId, role: ChatRole.user, content: text);

      final botText = _demoBotReply(text);
      setState(() {
        _messages = [
          ..._messages,
          ChatMessage(role: ChatRole.bot, content: botText, createdAt: now),
        ];
      });
      _scrollToBottom();

      await _repo.addMessage(userId: userId, role: ChatRole.bot, content: botText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save chat: $e')),
      );
    }
  }

  Widget _bubble(ChatMessage msg, TextStyle messageStyle) {
    final isUser = msg.role == ChatRole.user;
    final bubble = _GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(msg.content, style: messageStyle),
    );
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.expanded;
    final isFullPage = widget.fullPage;
    final messageFontSize = isExpanded ? 14.0 : 12.0;
    final messageAreaHeight = isFullPage ? 420.0 : (isExpanded ? 320.0 : 200.0);
    final messageStyle = TextStyle(
      fontSize: messageFontSize,
      color: Colors.white.withOpacity(0.9),
      height: 1.35,
    );

    return _GlassCard(
      borderRadius: 24,
      padding: EdgeInsets.all(isExpanded ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CC9F0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Color(0xFF4CC9F0),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AstroBot Live Chat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _isGuest || _isLoading ? null : _load,
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isGuest
                ? 'Preview mode (sign in to save messages).'
                : 'Ask questions and automate tasks—your messages are saved.',
            style: TextStyle(
              fontSize: isExpanded ? 13 : 11,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          SizedBox(height: isExpanded ? 20 : 12),
          SizedBox(
            height: messageAreaHeight,
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4CC9F0),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) =>
                        _bubble(_messages[i], messageStyle),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _messages.length,
                  ),
          ),
          SizedBox(height: isExpanded ? 16 : 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 12,
              vertical: isExpanded ? 8 : 4,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard,
                  size: isExpanded ? 20 : 16,
                  color: Colors.white54,
                ),
                SizedBox(width: isExpanded ? 12 : 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isGuest,
                    onSubmitted: (_) => _send(),
                    style: TextStyle(
                      fontSize: isExpanded ? 15 : 13,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message to AstroBot…',
                      hintStyle: TextStyle(
                        fontSize: isExpanded ? 14 : 12,
                        color: Colors.white54,
                      ),
                      border: InputBorder.none,
                      isDense: !isExpanded,
                      contentPadding: isExpanded
                          ? const EdgeInsets.symmetric(vertical: 12)
                          : null,
                    ),
                    cursorColor: const Color(0xFF4CC9F0),
                  ),
                ),
                IconButton(
                  onPressed: _isGuest ? null : _send,
                  icon: Icon(
                    Icons.send_rounded,
                    size: isExpanded ? 24 : 20,
                    color: const Color(0xFF4CC9F0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============= DASHBOARD CARDS =============

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.onStartChat});

  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF4CC9F0),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.black,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Chat with AstroBot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PromptChip(text: '“Send email with report”'),
          const SizedBox(height: 8),
          _PromptChip(text: '“What’s the weather?”'),
          const SizedBox(height: 8),
          _PromptChip(text: '“Summarize today’s tasks”'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CC9F0),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onStartChat,
              child: const Text('Start Chat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 16,
      child: Row(
        children: [
          const Icon(
            Icons.bolt,
            size: 16,
            color: Color(0xFF4CC9F0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    final activities = [
      ('Sent weekly report', '2 min ago'),
      ('Created reminder', '15 min ago'),
      ('Checked weather', '1 hour ago'),
      ('Drafted status email', 'Yesterday'),
    ];

    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.schedule,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in activities) ...[
            _ActivityRow(title: entry.$1, timeLabel: entry.$2),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.title, required this.timeLabel});

  final String title;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4CC9F0),
                Color(0xFF7209B7),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkflowInsightsCard extends StatelessWidget {
  const _WorkflowInsightsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.show_chart,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Workflow Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '86% success rate this week',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: _MiniLineChart(),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'View Reports',
                style: TextStyle(color: Color(0xFF4CC9F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Lightweight, chart-like visualization without extra dependencies.
    final data = [0.4, 0.6, 0.55, 0.7, 0.9, 0.86, 0.92];

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _LineChartPainter(
            data: data,
            strokeColor: const Color(0xFF4CC9F0),
          ),
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.strokeColor,
  });

  final List<double> data;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final path = Path();
    final shadowPath = Path();

    final double dx = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = dx * i;
      final double y = size.height - (data[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        shadowPath.moveTo(x, size.height);
        shadowPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        shadowPath.lineTo(x, y);
      }
    }
    shadowPath.lineTo(size.width, size.height);
    shadowPath.close();

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          strokeColor.withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(shadowPath, shadowPaint);

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============= WORKFLOW HISTORY TABLE =============

class _WorkflowHistoryTable extends StatefulWidget {
  const _WorkflowHistoryTable();

  @override
  State<_WorkflowHistoryTable> createState() => _WorkflowHistoryTableState();
}

class _WorkflowHistoryTableState extends State<_WorkflowHistoryTable> {
  final _repo = WorkflowRepository();

  bool _isLoading = false;
  List<WorkflowRun> _runs = const [];

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;
  bool get _isGuest => _userId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<WorkflowRun> _demoRuns() {
    final now = DateTime.now();
    return [
      WorkflowRun(
        intent: 'Send weekly report',
        status: 'Completed',
        executedAt: now.subtract(const Duration(minutes: 10)),
      ),
      WorkflowRun(
        intent: 'Create reminder',
        status: 'Completed',
        executedAt: now.subtract(const Duration(minutes: 48)),
      ),
      WorkflowRun(
        intent: 'Check weather',
        status: 'In Progress',
        executedAt: now.subtract(const Duration(hours: 1, minutes: 5)),
      ),
      WorkflowRun(
        intent: 'Draft email',
        status: 'Completed',
        executedAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ];
  }

  Future<void> _load() async {
    if (_isGuest) {
      setState(() => _runs = _demoRuns());
      return;
    }

    setState(() => _isLoading = true);
    try {
      final runs = await _repo.fetchRecentRuns(userId: _userId!, limit: 12);
      if (!mounted) return;
      setState(() => _runs = runs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load workflow history: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createDemoRun() async {
    if (_isGuest) return;
    try {
      final userId = _userId!;
      await _repo.insertRun(
        userId: userId,
        intent: 'Demo run from dashboard',
        status: 'Completed',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create demo run: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _runs;

    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.list_alt,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Workflow History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_isGuest)
                const Text(
                  'Preview',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _isGuest || _isLoading ? null : _load,
                icon: const Icon(Icons.refresh, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4CC9F0),
                ),
              ),
            )
          else if (!_isGuest && rows.isEmpty)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'No workflow runs yet. Create a demo run to verify the backend.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _createDemoRun,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CC9F0),
                    side: const BorderSide(color: Color(0xFF4CC9F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Create demo run'),
                ),
              ],
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 32,
                horizontalMargin: 8,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                columns: const [
                  DataColumn(label: Text('Intent')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Executed Time')),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        DataCell(Text(r.intent)),
                        DataCell(_StatusChip(status: r.status)),
                        DataCell(Text(formatExecutedLabel(r.executedAt))),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = status.toLowerCase().contains('completed');
    final Color color = isCompleted ? const Color(0xFF4CC9F0) : Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_outline : Icons.timelapse,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============= CONNECTED APPS PANEL =============

class _ConnectedAppsPanel extends StatelessWidget {
  const _ConnectedAppsPanel();

  @override
  Widget build(BuildContext context) {
    final apps = [
      ('Gmail', Icons.email_outlined, true),
      ('Notion', Icons.notes_outlined, true),
      ('Telegram', Icons.send_outlined, true),
    ];

    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.hub_outlined,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Connected Apps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final app in apps) ...[
            _ConnectedAppTile(
              name: app.$1,
              icon: app.$2,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4CC9F0),
                side: const BorderSide(color: Color(0xFF4CC9F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {},
              child: const Text('Integrate More'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedAppTile extends StatelessWidget {
  const _ConnectedAppTile({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white.withOpacity(0.08),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ),
        const _StatusDot(),
        const SizedBox(width: 4),
        const Text(
          'Connected',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF4CC9F0),
      ),
    );
  }
}

// ============= QUICK SETTINGS PANEL =============

class _QuickSettingsPanel extends StatefulWidget {
  const _QuickSettingsPanel();

  @override
  State<_QuickSettingsPanel> createState() => _QuickSettingsPanelState();
}

class _QuickSettingsPanelState extends State<_QuickSettingsPanel> {
  final _repo = UserSettingsRepository();

  bool _isLoading = false;
  bool _voiceInput = false;
  bool _notifications = true;
  bool _preferences = true;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;
  bool get _isGuest => _userId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isGuest) return;

    setState(() => _isLoading = true);
    try {
      final map = await _repo.fetchSettings(
        userId: _userId!,
        keys: const ['voice_input', 'notifications', 'preferences'],
      );

      if (!mounted) return;
      setState(() {
        _voiceInput = parseBoolSetting(map['voice_input'], defaultValue: false);
        _notifications =
            parseBoolSetting(map['notifications'], defaultValue: true);
        _preferences = parseBoolSetting(map['preferences'], defaultValue: true);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setSetting(String key, bool value) async {
    if (_isGuest) return;

    final beforeVoice = _voiceInput;
    final beforeNotif = _notifications;
    final beforePref = _preferences;

    setState(() {
      switch (key) {
        case 'voice_input':
          _voiceInput = value;
          break;
        case 'notifications':
          _notifications = value;
          break;
        case 'preferences':
          _preferences = value;
          break;
      }
    });

    try {
      await _repo.setSetting(
        userId: _userId!,
        key: key,
        value: value ? 'true' : 'false',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voiceInput = beforeVoice;
        _notifications = beforeNotif;
        _preferences = beforePref;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save setting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _isGuest || _isLoading ? null : _load,
                icon: const Icon(Icons.refresh, color: Colors.white54, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_isGuest)
            const Text(
              'Preview mode (sign in to persist settings).',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            )
          else if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.white12,
                color: Color(0xFF4CC9F0),
              ),
            ),
          const SizedBox(height: 12),
          _SettingTile(
            icon: Icons.mic_none,
            title: 'Enable Voice Input',
            subtitle: 'Talk to AstroBot using your microphone.',
            value: _voiceInput,
            enabled: !_isGuest,
            onChanged: (v) => _setSetting('voice_input', v),
          ),
          _SettingTile(
            icon: Icons.notifications_none,
            title: 'Control Notifications',
            subtitle: 'Configure alerts for executions and failures.',
            value: _notifications,
            enabled: !_isGuest,
            onChanged: (v) => _setSetting('notifications', v),
          ),
          _SettingTile(
            icon: Icons.tune,
            title: 'Manage Preferences',
            subtitle: 'Customize AI behaviour and tone.',
            value: _preferences,
            enabled: !_isGuest,
            onChanged: (v) => _setSetting('preferences', v),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.06),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: const Color(0xFF4CC9F0),
          ),
        ],
      ),
    );
  }
}

// ============= GLASS CARD REUSABLE =============

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding,
    this.borderRadius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

