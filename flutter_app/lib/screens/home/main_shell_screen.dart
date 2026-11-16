import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../services/session_controller.dart';
import 'notifications_tab.dart';
import 'profile_tab.dart';
import 'tasks_tab.dart';

/// الهيكل التفاعلي الرئيسي: NavigationBar على الجوال و NavigationRail على التابلت والويب
class MainShellScreen extends StatefulWidget {
  final SessionController session;

  const MainShellScreen({super.key, required this.session});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      widget.session.refreshUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = widget.session.unreadNotifications;
    final useRail = !Responsive.isMobile(context);
    final extendedRail = Responsive.isDesktop(context);

    final pages = [
      TasksTab(session: widget.session),
      NotificationsTab(session: widget.session),
      ProfileTab(session: widget.session),
    ];

    Widget notifIcon({required bool selected}) => Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 99 ? '99+' : '$unread'),
          child: Icon(selected ? Icons.notifications : Icons.notifications_outlined),
        );

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              extended: extendedRail,
              onDestinationSelected: _onTabSelected,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.check_box_outlined),
                  selectedIcon: Icon(Icons.check_box),
                  label: Text('المهام'),
                ),
                NavigationRailDestination(
                  icon: notifIcon(selected: false),
                  selectedIcon: notifIcon(selected: true),
                  label: const Text('الإشعارات'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('الحساب'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: pages),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: 'المهام',
          ),
          NavigationDestination(
            icon: notifIcon(selected: false),
            selectedIcon: notifIcon(selected: true),
            label: 'الإشعارات',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'الحساب',
          ),
        ],
      ),
    );
  }
}
