import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_language.dart';
import '../widgets/feature_card.dart';
import 'comparator_screen.dart';
import 'item_dex_screen.dart';
import 'nature_dex_screen.dart';
import 'team_builder_screen.dart';
import 'type_dex_screen.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF111827),
      title: Text(
        appText(context, 'tools_title'),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: appText(context, 'language'),
          icon: const Icon(Icons.language_rounded),
          onSelected: AppLanguageController.instance.setLanguage,
          itemBuilder: (context) => [
            for (final language in supportedAppLanguages)
              PopupMenuItem(
                value: language.$1,
                child: Row(
                  children: [
                    if (language.$1 == AppLanguageController.instance.code)
                      const Icon(Icons.check_rounded, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(language.$2),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1000 ? 3 : 2;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF342D70), Color(0xFF1C3452)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appText(context, 'tools_intro'),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          appText(context, 'tools_subtitle'),
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: Color(0xFFC1ACFF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              appText(context, 'strategy'),
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 9),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: constraints.maxWidth < 380 ? 1.06 : 1.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                FeatureCard(
                  icon: Icons.groups_2_outlined,
                  title: appText(context, 'team_title'),
                  description: appText(context, 'team_desc'),
                  accent: const Color(0xFFAA91FF),
                  onTap: () => _open(context, const TeamBuilderScreen()),
                ),
                FeatureCard(
                  icon: Icons.compare_arrows_rounded,
                  title: appText(context, 'compare_title'),
                  description: appText(context, 'compare_desc'),
                  accent: const Color(0xFF73CCF4),
                  onTap: () => _open(context, const ComparatorScreen()),
                ),
                FeatureCard(
                  icon: Icons.grid_view_rounded,
                  title: appText(context, 'type_title'),
                  description: appText(context, 'type_desc'),
                  accent: const Color(0xFFFFB370),
                  onTap: () => _open(context, const TypeDexScreen()),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              appText(context, 'collection_data'),
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 9),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: constraints.maxWidth < 380 ? 1.06 : 1.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                FeatureCard(
                  icon: Icons.spa_outlined,
                  title: appText(context, 'nature_title'),
                  description: appText(context, 'nature_desc'),
                  accent: const Color(0xFF70D6A9),
                  onTap: () => _open(context, const NatureDexScreen()),
                ),
                FeatureCard(
                  icon: Icons.inventory_2_outlined,
                  title: appText(context, 'item_title'),
                  description: appText(context, 'item_desc'),
                  accent: const Color(0xFFFFD166),
                  onTap: () => _open(context, const ItemDexScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.045),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.offline_bolt_outlined,
                    color: Color(0xFF78D6A5),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appText(context, 'offline_text'),
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
