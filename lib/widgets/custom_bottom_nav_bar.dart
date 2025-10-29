import 'package:flutter/material.dart';
import 'package:password_manager/screens/main_screens/overview.dart';
import 'package:password_manager/screens/settings/settings.dart';
import '../screens/main_screens/home.dart';
import '../screens/main_screens/password_generator.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavBarItem(Icons.home, 'Home', 0, context),
                _buildNavBarItem(Icons.data_usage_rounded, 'Overview', 1, context),
                const SizedBox(width: 0),
                _buildNavBarItem(Icons.key, 'Generator', 3, context),
                _buildNavBarItem(Icons.settings, 'Settings', 4, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index, BuildContext context) {
    final isSelected = selectedIndex == index;
    final textColor = isSelected ? Colors.white : Colors.grey[400];
    final backgroundColor = isSelected ? Color(0xFF328E6E) : Colors.transparent;

    return InkWell(
      onTap: () {
        onItemTapped(index);
        _handleNavBarAction(index, context);
      },
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: textColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Icon(
                  icon,
                  color: textColor,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleNavBarAction(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordGeneratorWidget()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
        break;
    }
  }
}