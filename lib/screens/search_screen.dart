import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/record_provider.dart';
import '../widgets/record_card.dart';
import '../widgets/empty_state.dart';
import 'record_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '테마명, 매장명, 내용 검색...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.outline,
            ),
          ),
          style: theme.textTheme.bodyLarge,
          onChanged: (value) {
            context.read<RecordProvider>().search(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                context.read<RecordProvider>().clearSearch();
              },
            ),
        ],
      ),
      body: Consumer<RecordProvider>(
        builder: (context, provider, child) {
          if (provider.searchQuery.isEmpty) {
            return EmptyState(
              icon: Icons.search,
              title: '검색어를 입력하세요',
              description: '테마명, 매장명, 메모 내용으로 검색할 수 있습니다',
            );
          }

          if (provider.searchResults.isEmpty) {
            return EmptyState(
              icon: Icons.search_off,
              title: '검색 결과가 없습니다',
              description: '"${provider.searchQuery}"에 대한 결과를 찾을 수 없습니다',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              final record = provider.searchResults[index];
              return RecordCard(
                record: record,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecordDetailScreen(record: record),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
