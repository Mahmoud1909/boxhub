// lib/widgets/custom_bottom_nav.dart
import 'package:flutter/material.dart';

const Color brandColor = Color(0xFFF47622);

class CustomBottomNav extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNav({this.initialIndex = 0, this.onTap, Key? key}) : super(key: key);

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  late int _currentIndex;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
  ];

  @override
  void initState() {
    super.initState();
    final len = _items.length;
    _currentIndex = widget.initialIndex.clamp(0, len - 1).toInt();
  }

  void _onItemTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    // Use SafeArea to respect system bottom inset (gesture nav / notch)
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        // don't force an exact height — use minHeight so it can shrink if needed
        constraints: BoxConstraints(minHeight: 60, maxHeight: 90),
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            )
          ],
          border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == _currentIndex;
            final color = selected ? brandColor : Colors.grey.shade600;

            return Expanded(
              child: InkWell(
                onTap: () => _onItemTap(i),
                splashColor: brandColor.withOpacity(0.12),
                highlightColor: Colors.transparent,
                child: Padding(
                  // reduced vertical padding to avoid overflow
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon wrapper — constrained so it can't grow beyond available space
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 44,
                          maxWidth: 44,
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                          width: selected ? 40 : 32,
                          height: selected ? 40 : 32,
                          padding: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: selected ? brandColor.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon,
                            size: selected ? 24 : 20,
                            color: color,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Label text — use Flexible + FittedBox so it scales if vertical space is tight
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            fontSize: selected ? 12 : 11,
                            color: color,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Indicator Bar — smaller widths so it fits smaller heights
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: selected ? 18 : 6,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: selected ? brandColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
