// lib/widgets/profile_app_bar.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color brandColor = Color(0xFFF3692F); // main accent (used for borders/shadows/badges)

class ProfileAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;

  const ProfileAppBar({
    required this.userData,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onSettingsTap,
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileAppBar> createState() => _ProfileAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(88);
}

class _ProfileAppBarState extends State<ProfileAppBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getInitials(String first, String display) {
    final source = first.isNotEmpty ? first : (display.isNotEmpty ? display : '');
    if (source.isEmpty) return 'U';
    final len = math.min(2, source.trim().length);
    return source.trim().substring(0, len).toUpperCase();
  }

  String _getFullName(String first, String last, String display, String email) {
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    if (display.isNotEmpty) return display;
    if (email.isNotEmpty) return email;
    return 'No name';
  }

  @override
  Widget build(BuildContext context) {
    final first = (widget.userData['first_name'] ?? '').toString();
    final last = (widget.userData['last_name'] ?? '').toString();
    final email = (widget.userData['email'] ?? '').toString();
    final photo = (widget.userData['photo_url'] ?? '').toString();
    final display = (widget.userData['displayName'] ?? '').toString();

    final fullName = _getFullName(first, last, display, email);
    final initials = _getInitials(first, display);

    Widget buildAvatar(double radius) {
      const fallbackAvatar = 'https://img.icons8.com/color/1200/person-male.jpg';
      if (photo.isEmpty) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: brandColor,
          child: Text(initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.45,
              )),
        );
      }

      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.network(
            photo,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Image.network(
              fallbackAvatar,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (c2, e2, s2) => Container(
                width: radius * 2,
                height: radius * 2,
                color: brandColor,
                alignment: Alignment.center,
                child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.45)),
              ),
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: brandColor.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
              border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onProfileTap ??
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open profile (placeholder)')));
                      },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: brandColor, width: 2.4),
                      boxShadow: [BoxShadow(color: brandColor.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 6))],
                    ),
                    child: buildAvatar(28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: widget.onNotificationsTap ??
                              () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications pressed (placeholder)')));
                          },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none, size: 26, color: Colors.black87),
                          // subtle brand-accent badge
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: brandColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [BoxShadow(color: brandColor.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: widget.onSettingsTap ??
                              () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings pressed (placeholder)')));
                          },
                      icon: const Icon(Icons.settings_outlined, size: 26, color: Colors.black87),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
