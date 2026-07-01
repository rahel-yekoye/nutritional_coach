import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'food_model.g.dart';

@HiveType(typeId: 5)
class FoodModel extends Equatable {
  @HiveField(0)
  final String foodCode;

  @HiveField(1)
  final String foodName;

  @HiveField(2)
  final String? foodNameAmharic;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final List<String>? keywords;

  @HiveField(5)
  final NutritionModel? nutrition;

  @HiveField(6)
  final double? score;

  @HiveField(7)
  final String? matchType;

  const FoodModel({
    required this.foodCode,
    required this.foodName,
    this.foodNameAmharic,
    required this.category,
    this.keywords,
    this.nutrition,
    this.score,
    this.matchType,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      foodCode: json['food_code'] as String,
      foodName: json['food_name'] as String,
      foodNameAmharic: json['food_name_amharic'] as String?,
      category: json['category'] as String,
      keywords: (json['keywords'] as List?)?.map((e) => e as String).toList(),
      nutrition: json['nutrition'] != null
          ? NutritionModel.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
      score: (json['score'] as num?)?.toDouble(),
      matchType: json['matchType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_code': foodCode,
      'food_name': foodName,
      'food_name_amharic': foodNameAmharic,
      'category': category,
      'keywords': keywords,
      'nutrition': nutrition?.toJson(),
      'score': score,
      'matchType': matchType,
    };
  }

  @override
  List<Object?> get props => [
        foodCode,
        foodName,
        foodNameAmharic,
        category,
        keywords,
        nutrition,
        score,
        matchType,
      ];
}

@HiveType(typeId: 6)
class NutritionModel extends Equatable {
  @HiveField(0)
  final double? energyKcal;

  @HiveField(1)
  final double? proteinG;

  @HiveField(2)
  final double? fatG;

  @HiveField(3)
  final double? carbsG;

  @HiveField(4)
  final double? fiberG;

  @HiveField(5)
  final double? waterG;

  @HiveField(6)
  final double? ashG;

  const NutritionModel({
    this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbsG,
    this.fiberG,
    this.waterG,
    this.ashG,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    return NutritionModel(
      energyKcal: (json['energy_kcal'] as num?)?.toDouble(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      waterG: (json['water_g'] as num?)?.toDouble(),
      ashG: (json['ash_g'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'energy_kcal': energyKcal,
      'protein_g': proteinG,
      'fat_g': fatG,
      'carbs_g': carbsG,
      'fiber_g': fiberG,
      'water_g': waterG,
      'ash_g': ashG,
    };
  }

  @override
  List<Object?> get props => [
        energyKcal,
        proteinG,
        fatG,
        carbsG,
        fiberG,
        waterG,
        ashG,
      ];
}

class SearchResponse extends Equatable {
  final String query;
  final int resultCount;
  final int limit;
  final List<FoodModel> results;
  final bool? cached;

  const SearchResponse({
    required this.query,
    required this.resultCount,
    required this.limit,
    required this.results,
    this.cached,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query'] as String,
      resultCount: json['result_count'] as int,
      limit: json['limit'] as int,
      results: (json['results'] as List)
          .map((e) => FoodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      cached: json['cached'] as bool?,
    );
  }

  @override
  List<Object?> get props => [query, resultCount, limit, results, cached];
}

class SuggestionModel extends Equatable {
  final String text;
  final String type;

  const SuggestionModel({
    required this.text,
    required this.type,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      text: json['text'] as String,
      type: json['type'] as String,
    );
  }

  @override
  List<Object?> get props => [text, type];
}

class SuggestResponse extends Equatable {
  final String query;
  final List<SuggestionModel> suggestions;
  final int suggestionCount;

  const SuggestResponse({
    required this.query,
    required this.suggestions,
    required this.suggestionCount,
  });

  factory SuggestResponse.fromJson(Map<String, dynamic> json) {
    return SuggestResponse(
      query: json['query'] as String,
      suggestions: (json['suggestions'] as List)
          .map((e) => SuggestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestionCount: json['suggestion_count'] as int,
    );
  }

  @override
  List<Object?> get props => [query, suggestions, suggestionCount];
}

class CategoryModel extends Equatable {
  final String name;
  final int foodCount;

  const CategoryModel({
    required this.name,
    required this.foodCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'] as String,
      foodCount: json['food_count'] as int,
    );
  }

  @override
  List<Object?> get props => [name, foodCount];
}

class CategoryResponse extends Equatable {
  final List<CategoryModel> categories;
  final int totalCategories;

  const CategoryResponse({
    required this.categories,
    required this.totalCategories,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categories: (json['categories'] as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCategories: json['total_categories'] as int,
    );
  }

  @override
  List<Object?> get props => [categories, totalCategories];
}
