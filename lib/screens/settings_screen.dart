import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // 테마 설정
          _buildSectionHeader(context, '화면'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('테마'),
            subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, themeProvider),
          ),

          const Divider(),

          // 앱 정보
          _buildSectionHeader(context, '정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('앱 버전'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('데이터 저장'),
            subtitle: Text('모든 데이터는 기기에만 저장됩니다'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '시스템 설정';
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('테마 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                  Navigator.pop(dialogContext);
                },
              ),
              title: const Text('시스템 설정'),
              subtitle: const Text('기기 설정을 따릅니다'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                  Navigator.pop(dialogContext);
                },
              ),
              title: const Text('라이트 모드'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                  Navigator.pop(dialogContext);
                },
              ),
              title: const Text('다크 모드'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}
