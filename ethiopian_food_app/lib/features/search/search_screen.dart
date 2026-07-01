import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/widgets/food_card.dart';
import 'package:ethiopian_food_app/widgets/loading_skeleton.dart';
import 'package:ethiopian_food_app/features/search/search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final bool isPicker;

  const SearchScreen({
    super.key,
    this.isPicker = false,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final suggestionState = ref.watch(suggestionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ethiopian Food Database'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Categories',
            onPressed: () => context.push('/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Random Food',
            onPressed: _getRandomFood,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search Ethiopian foods...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchControllerProvider.notifier).clear();
                              ref.read(suggestionControllerProvider.notifier).clear();
                              setState(() => _showSuggestions = false);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onChanged: (value) {
                    setState(() => _showSuggestions = value.isNotEmpty);
                    ref.read(searchControllerProvider.notifier).search(value);
                    ref.read(suggestionControllerProvider.notifier).getSuggestions(value);
                  },
                  onTap: () {
                    if (_searchController.text.isNotEmpty) {
                      setState(() => _showSuggestions = true);
                    }
                  },
                ),

                // Suggestions dropdown
                if (_showSuggestions && suggestionState.suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suggestionState.suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = suggestionState.suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            suggestion.type == 'keyword'
                                ? Icons.label
                                : Icons.restaurant,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          title: Text(suggestion.text),
                          trailing: Icon(
                            Icons.north_west,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          onTap: () {
                            _searchController.text = suggestion.text;
                            ref.read(searchControllerProvider.notifier).search(suggestion.text);
                            setState(() => _showSuggestions = false);
                            _focusNode.unfocus();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchState state) {
    if (state.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for Ethiopian foods',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try "injera", "teff", or "barley"',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    if (state.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const FoodCardSkeleton(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(fontSize: 18, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(searchControllerProvider.notifier).search(state.query);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final food = state.results[index];
        return FoodCard(
          food: food,
          onTap: () {
            if (widget.isPicker) {
              context.pop(food);
            } else {
              context.push('/food/${food.foodCode}');
            }
          },
        );
      },
    );
  }

  void _getRandomFood() {
    final state = ref.read(searchControllerProvider);
    if (state.results.isNotEmpty) {
      final random = (state.results..shuffle()).first;
      context.push('/food/${random.foodCode}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search for foods first!')),
      );
    }
  }
}
