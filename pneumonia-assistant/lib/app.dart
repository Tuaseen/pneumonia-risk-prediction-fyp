import 'package:flutter/material.dart';

import 'data/app_store.dart';
import 'ui/auth_screen.dart';
import 'ui/design.dart';
import 'ui/doctor_screen.dart';
import 'ui/patient_screens.dart';

class PneumoniaAssistantApp extends StatelessWidget {
  final AppStore store;
  final String? startupError;

  const PneumoniaAssistantApp({
    super.key,
    required this.store,
    this.startupError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pneumonia Assistant',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) => store.signedIn
            ? AppShell(store: store)
            : AuthScreen(store: store, startupError: startupError),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final AppStore store;
  const AppShell({super.key, required this.store});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _refreshing = false;
  final _scroll = ScrollController();

  static const _labels = [
    'Dashboard',
    'Assistant',
    'History & Reports',
    'Profile',
  ];

  static const _icons = [
    Icons.space_dashboard_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.assignment_outlined,
    Icons.person_outline_rounded,
  ];

  static const _selectedIcons = [
    Icons.space_dashboard_rounded,
    Icons.chat_bubble_rounded,
    Icons.assignment_rounded,
    Icons.person_rounded,
  ];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _navigate(int i) {
    setState(() => _index = i);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.store.refresh();
      if (mounted) {
        showSuccessSnackBar(context, 'Data updated successfully.');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 850;

    // DOCTOR PORTAL VIEW: Dedicated clinical care layout
    if (store.isDoctor) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 12,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pneumonia Assistant',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Clinical Care Portal · ${store.doctorName}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (width >= 440) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services_outlined, size: 13, color: Color(0xFF7C3AED)),
                    SizedBox(width: 5),
                    Text(
                      'DOCTOR PORTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: _refreshing ? null : _refresh,
              tooltip: 'Refresh roster',
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 22, color: textSecondary),
            ),
            IconButton(
              tooltip: 'Sign out of doctor portal',
              icon: const Icon(Icons.logout_rounded, size: 22, color: destructiveRed),
              onPressed: () => store.signOut(),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 32 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: DoctorScreen(store: store),
              ),
            ),
          ),
        ),
      );
    }

    // PATIENT COMPANION VIEW: Dedicated patient layout
    final Widget currentScreen = switch (_index) {
      0 => DashboardScreen(
          store: store,
          onAskAssistant: () => _navigate(1),
          onShowHistory: () => _navigate(2),
        ),
      1 => AssistantScreen(store: store),
      2 => HistoryScreen(store: store),
      _ => ProfileScreen(store: store),
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 28),
            SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pneumonia Assistant',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.3,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'Patient Health Companion',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Connection / Mode tag
          if (width >= 440) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: store.isCloudConnected
                    ? const Color(0xFFDCFCE7)
                    : (store.demo
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFEFF6FF)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: store.isCloudConnected
                          ? const Color(0xFF16A34A)
                          : (store.demo
                              ? const Color(0xFF64748B)
                              : const Color(0xFF2563EB)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    store.isCloudConnected
                        ? 'CLOUD SYNCED'
                        : (store.demo ? 'DEMO MODE' : 'LOCAL MODE'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: store.isCloudConnected
                          ? const Color(0xFF15803D)
                          : (store.demo
                              ? const Color(0xFF475569)
                              : const Color(0xFF1D4ED8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Refresh button
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            tooltip: 'Refresh data',
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 22, color: textSecondary),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: _navigate,
                backgroundColor: surfaceWhite,
                labelType: NavigationRailLabelType.all,
                indicatorColor: primaryBlueLight,
                minWidth: 84,
                destinations: List.generate(
                  _labels.length,
                  (i) => NavigationRailDestination(
                    icon: Icon(_icons[i]),
                    selectedIcon: Icon(_selectedIcons[i], color: primaryBlue),
                    label: Text(_labels[i]),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 32 : 16,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: currentScreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !wide
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _navigate,
              destinations: List.generate(
                _labels.length,
                (i) => NavigationDestination(
                  icon: Icon(_icons[i]),
                  selectedIcon: Icon(_selectedIcons[i]),
                  label: _labels[i],
                ),
              ),
            )
          : null,
    );
  }
}
