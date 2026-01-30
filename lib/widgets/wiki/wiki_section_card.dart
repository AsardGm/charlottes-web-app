import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Typ obsahu sekce
enum WikiSectionType { text, tags, list, keyValue }

/// Znovupouzitelna sekce pro wiki detail
class WikiSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final WikiSectionType type;
  final String? textContent;
  final List<String>? tags;
  final List<String>? listItems;
  final Map<String, String>? kvData;
  final Color? tagColor;

  const WikiSectionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.type,
    this.textContent,
    this.tags,
    this.listItems,
    this.kvData,
    this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withAlpha(35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Content based on type
          switch (type) {
            WikiSectionType.text => _buildText(),
            WikiSectionType.tags => _buildTags(),
            WikiSectionType.list => _buildList(),
            WikiSectionType.keyValue => _buildKeyValue(),
          },
        ],
      ),
    );
  }

  Widget _buildText() {
    return Text(
      textContent ?? '',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.6,
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: (tags ?? []).map((tag) {
        final color = tagColor ?? iconColor;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withAlpha(50),
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: (listItems ?? []).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(180),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyValue() {
    return Column(
      children: (kvData ?? {}).entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
