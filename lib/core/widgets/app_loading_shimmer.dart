import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppLoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppLoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E1430) : const Color(0xFFEADBFF).withOpacity(0.35);
    final highlightColor = isDark ? const Color(0xFF2E2048) : Colors.white.withOpacity(0.8);

    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1430) : Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }

  static Widget storyCardPlaceholder() {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLoadingShimmer(width: 170, height: 210, borderRadius: 20),
          SizedBox(height: 10),
          AppLoadingShimmer(width: 140, height: 16, borderRadius: 6),
          SizedBox(height: 6),
          AppLoadingShimmer(width: 90, height: 12, borderRadius: 4),
        ],
      ),
    );
  }

  static Widget episodeTilePlaceholder() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AppLoadingShimmer(width: 56, height: 56, borderRadius: 14),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLoadingShimmer(width: double.infinity, height: 16, borderRadius: 6),
                SizedBox(height: 8),
                AppLoadingShimmer(width: 140, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
