import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// High-level sections that can be shown inside the dashboard content area.
/// The sidebar updates `_activeSection` with one of these values.
enum DashboardSection {
  dashboard,
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
                      onBackToDashboard: () {
                        setState(() {
                          _activeSection = DashboardSection.dashboard;
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
  });

  final String userLabel;
  final VoidCallback onSignOut;
  final DashboardSection activeSection;
  final VoidCallback onBackToDashboard;

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
              ),
              const SizedBox(height: 20),
              if (activeSection == DashboardSection.dashboard) ...[
                const _HeroSection(),
                const SizedBox(height: 24),
                _MainGrid(isWide: isWide),
              ] else ...[
                _SectionContent(
                  section: activeSection,
                  isWide: isWide,
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
  });

  final String userLabel;
  final VoidCallback onSignOut;
  final DashboardSection activeSection;
  final VoidCallback onBackToDashboard;

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;

    switch (activeSection) {
      case DashboardSection.dashboard:
        title = 'Welcome back to AstroBot!';
        subtitle = 'Automate your tasks with intelligent AI workflows.';
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

    final bool isRoot = activeSection == DashboardSection.dashboard;

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
              onPressed: () {},
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

// ============= HERO SECTION =============

class _HeroSection extends StatelessWidget {
  const _HeroSection();

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
                children: const [
                  Text(
                    'Design your AI automations.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Build conversational workflows, connect your tools, and let AstroBot\n'
                    'handle repetitive tasks across your apps.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: _HeroVisual(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFF4CC9F0),
                  Color(0xFF4361EE),
                  Color(0xFF7209B7),
                  Color(0xFF4CC9F0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CC9F0).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
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
        Positioned(
          top: 12,
          right: 10,
          child: _FloatingNode(label: 'Workflow'),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: _FloatingNode(label: 'Triggers'),
        ),
        Positioned(
          bottom: 40,
          right: 40,
          child: _FloatingNode(label: 'Actions'),
        ),
      ],
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
  const _MainGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            flex: 3,
            child: _PrimaryPanels(),
          ),
          SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _SidePanels(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _PrimaryPanels(),
        SizedBox(height: 20),
        _SidePanels(),
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
        Row(
          children: const [
            Expanded(child: _ChatCard()),
            SizedBox(width: 16),
            Expanded(child: _RecentActivityCard()),
          ],
        ),
        const SizedBox(height: 16),
        const _WorkflowInsightsCard(),
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
  });

  final DashboardSection section;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    Widget main;

    switch (section) {
      case DashboardSection.dashboard:
        main = const _PrimaryPanels();
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

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: main),
          const SizedBox(width: 20),
          const Expanded(flex: 2, child: _SidePanels()),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        main,
        const SizedBox(height: 20),
        const _SidePanels(),
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
  const _SidePanels();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _AstroChatPanel(),
        SizedBox(height: 16),
        _ConnectedAppsPanel(),
        SizedBox(height: 16),
        _QuickSettingsPanel(),
      ],
    );
  }
}

// ============= LIVE CHAT PANEL =============

class _AstroChatPanel extends StatelessWidget {
  const _AstroChatPanel();

  @override
  Widget build(BuildContext context) {
    final messageStyle = TextStyle(
      fontSize: 12,
      color: Colors.white.withOpacity(0.85),
    );

    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.smart_toy_outlined,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'AstroBot Live Chat',
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
            'Ask quick questions while exploring your dashboard.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _GlassCard(
                  borderRadius: 14,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    'Hi, I\'m AstroBot. What would you like to automate today?',
                    style: messageStyle,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _GlassCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Text(
                      'Show me my recent automated tasks.',
                      style: messageStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                color: Colors.white.withOpacity(0.16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.keyboard,
                  size: 16,
                  color: Colors.white54,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: TextField(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message to AstroBot…',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    cursorColor: Color(0xFF4CC9F0),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Color(0xFF4CC9F0),
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
  const _ChatCard();

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
              onPressed: () {},
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

class _WorkflowHistoryTable extends StatelessWidget {
  const _WorkflowHistoryTable();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Send weekly report', 'Completed', 'Today • 09:00'),
      ('Create reminder', 'Completed', 'Today • 08:12'),
      ('Check weather', 'In Progress', 'Today • 07:58'),
      ('Draft email', 'Completed', 'Yesterday • 18:03'),
    ];

    return _GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.list_alt,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Workflow History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                      DataCell(Text(r.$1)),
                      DataCell(_StatusChip(status: r.$2)),
                      DataCell(Text(r.$3)),
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
              icon: app.$2 as IconData,
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

class _QuickSettingsPanel extends StatelessWidget {
  const _QuickSettingsPanel();

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
                Icons.tune,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Quick Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SettingTile(
            icon: Icons.mic_none,
            title: 'Enable Voice Input',
            subtitle: 'Talk to AstroBot using your microphone.',
          ),
          const _SettingTile(
            icon: Icons.notifications_none,
            title: 'Control Notifications',
            subtitle: 'Configure alerts for executions and failures.',
          ),
          const _SettingTile(
            icon: Icons.tune,
            title: 'Manage Preferences',
            subtitle: 'Customize AI behaviour and tone.',
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
            value: true,
            onChanged: (_) {},
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

