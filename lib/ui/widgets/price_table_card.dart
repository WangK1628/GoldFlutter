import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/market_models.dart';

class PriceTableCard extends StatelessWidget {
  const PriceTableCard({super.key, required this.title, required this.items});

  final String title;
  final List<ShopGoldItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          ...items.take(6).map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.name, style: const TextStyle(fontSize: 12))),
                      Text(e.price, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
