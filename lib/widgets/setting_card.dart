import 'package:flutter/material.dart';

// Generic setting card with icon, title, subtitle and optional trailing widget
class SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDarkFog;

  const SettingCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.trailing,
    this.onTap,
    required this.isDarkFog,
  });

  Color get _cardColor => isDarkFog ? Colors.grey[850]! : Colors.white;
  Color get _textColor => isDarkFog ? Colors.white : Colors.black87;
  Color get _textColorSecondary => isDarkFog ? Colors.white70 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _cardColor,
      elevation: isDarkFog ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.blueAccent, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? _textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: _textColorSecondary, fontSize: 13),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
