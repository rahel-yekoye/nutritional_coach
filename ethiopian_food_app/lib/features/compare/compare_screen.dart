import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';

class CompareScreen extends ConsumerStatefulWidget {
  final String foodCode1;
  final String foodCode2;

  const CompareScreen({
    super.key,
    required this.foodCode1,
    required this.foodCode2,
  });

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final List<String?> _selectedCodes = [null, null];
  List<FoodModel>? _comparisonResults;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.foodCode1.isNotEmpty) _selectedCodes[0] = widget.foodCode1;
    if (widget.foodCode2.isNotEmpty) _selectedCodes[1] = widget.foodCode2;
    
    if (_selectedCodes[0] != null && _selectedCodes[1] != null) {
      _loadComparison();
    }
  }

  Future<void> _loadComparison() async {
    final validCodes = _selectedCodes.whereType<String>().toList();
    if (validCodes.length < 2) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final foodService = ref.read(foodServiceProvider);
      final results = await foodService.compareFoods(validCodes);
      setState(() {
        _comparisonResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _isLoading = false;
      });
    }
  }

  void _selectFood(int index) async {
    final result = await context.push('/search?picker=true');
    if (result != null && result is FoodModel) {
      setState(() {
        if (index < _selectedCodes.length) {
          _selectedCodes[index] = result.foodCode;
        } else {
          _selectedCodes.add(result.foodCode);
        }
      });
      if (_selectedCodes.whereType<String>().length >= 2) {
        _loadComparison();
      }
    }
  }

  void _addFoodSlot() {
    setState(() {
      _selectedCodes.add(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Foods'),
        elevation: 0,
        actions: [
          if (_selectedCodes.length < 4)
            IconButton(
              icon: const Icon(Icons.add_chart),
              tooltip: 'Add food to compare',
              onPressed: _addFoodSlot,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _comparisonResults == null || _comparisonResults!.isEmpty
                  ? _buildSelectionState()
                  : _buildComparisonView(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadComparison,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _error = null;
                _comparisonResults = null;
              }),
              child: const Text('Back to Selection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(Icons.compare_arrows, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Select 2 to 4 foods to compare their nutritional values side-by-side.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ...List.generate(_selectedCodes.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildSelectButton(index, _selectedCodes[index]),
            );
          }),
          const SizedBox(height: 24),
          if (_selectedCodes.whereType<String>().length >= 2)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadComparison,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Comparison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectButton(int index, String? code) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _selectFood(index),
        icon: Icon(code == null ? Icons.add_circle_outline : Icons.check_circle, color: code == null ? Colors.grey : Colors.green),
        label: Text(
          code == null ? 'Select Food ${index + 1}' : 'Food ${index + 1} Selected ($code)',
          style: TextStyle(color: code == null ? Colors.black87 : Colors.green),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: code == null ? Colors.grey[300]! : Colors.green),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 120), // Label column
                  ..._comparisonResults!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final food = entry.value;
                    return SizedBox(
                      width: 160,
                      child: _FoodHeader(
                        food: food,
                        color: _getColors()[index % _getColors().length],
                        onTap: () => _selectFood(index),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
              _buildMetricRow('Energy (kcal)', (f) => f.nutrition?.energyKcal, false),
              _buildMetricRow('Protein (g)', (f) => f.nutrition?.proteinG, true),
              _buildMetricRow('Fat (g)', (f) => f.nutrition?.fatG, false),
              _buildMetricRow('Carbs (g)', (f) => f.nutrition?.carbsG, false),
              _buildMetricRow('Fiber (g)', (f) => f.nutrition?.fiberG, true),
              const SizedBox(height: 32),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _comparisonResults = null),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modify Comparison'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, double? Function(FoodModel) getValue, bool higherIsBetter) {
    final values = _comparisonResults!.map((f) => getValue(f) ?? 0.0).toList();
    final bestValue = higherIsBetter 
        ? values.reduce((a, b) => a > b ? a : b)
        : values.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          ...values.map((v) {
            final isBest = v == bestValue && v > 0;
            return SizedBox(
              width: 160,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isBest ? Colors.green[50] : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    v.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                      color: isBest ? Colors.green[700] : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Color> _getColors() => [Colors.blue, Colors.orange, Colors.purple, Colors.teal];
}

class _FoodHeader extends StatelessWidget {
  final FoodModel food;
  final Color color;
  final VoidCallback onTap;

  const _FoodHeader({required this.food, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.05),
          ),
          child: Column(
            children: [
              Icon(Icons.restaurant, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                food.foodName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                food.category,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double? value1;
  final double? value2;
  final String unit;
  final bool higherIsBetter;

  const _ComparisonRow({
    required this.label,
    required this.value1,
    required this.value2,
    required this.unit,
    required this.higherIsBetter,
  });

  @override
  Widget build(BuildContext context) {
    final v1 = value1 ?? 0;
    final v2 = value2 ?? 0;
    final winner = _determineWinner(v1, v2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ValueDisplay(
                    value: v1,
                    unit: unit,
                    isWinner: winner == 1,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Icon(
                      _getComparisonIcon(v1, v2),
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Expanded(
                  child: _ValueDisplay(
                    value: v2,
                    unit: unit,
                    isWinner: winner == 2,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _determineWinner(double v1, double v2) {
    if (v1 == v2) return 0;
    if (higherIsBetter) {
      return v1 > v2 ? 1 : 2;
    } else {
      return v1 < v2 ? 1 : 2;
    }
  }

  IconData _getComparisonIcon(double v1, double v2) {
    if (v1 == v2) return Icons.drag_handle;
    return v1 > v2 ? Icons.arrow_forward : Icons.arrow_back;
  }
}

class _ValueDisplay extends StatelessWidget {
  final double value;
  final String unit;
  final bool isWinner;
  final Color color;

  const _ValueDisplay({
    required this.value,
    required this.unit,
    required this.isWinner,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner ? color : Colors.grey[300]!,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? color : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (isWinner) ...[
            const SizedBox(height: 4),
            Icon(Icons.emoji_events, size: 16, color: color),
          ],
        ],
      ),
    );
  }
}
