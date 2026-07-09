import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/providers/auth_provider.dart';
import 'package:ethiopian_food_app/core/providers/profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  int _currentPage = 0;
  int _age = 25;
  Gender _gender = Gender.male;
  double _height = 170;
  double _weight = 70;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  NutritionGoal _goal = NutritionGoal.maintain;
  BloodGroup _bloodGroup = BloodGroup.oPositive;
  bool _fastingMode = false;
  bool _isSubmitting = false;

  void _nextPage() {
    if (_currentPage < 4) { // Changed from 3 to 4 for 5 pages total
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      // Complete setup using the API
      await ref.read(authStateProvider.notifier).completeSetup(
        age: _age,
        sex: _gender.name,
        height: _height,
        weight: _weight,
        activityLevel: _activityLevel.name.replaceAll('_', '-'),
        goal: _goal.name.replaceAll('_', '-'),
        fastingMode: _fastingMode,
      );
      
      // Also create the local profile for the dashboard
      final profile = UserProfile(
        age: _age,
        gender: _gender,
        height: _height,
        weight: _weight,
        activityLevel: _activityLevel,
        goal: _goal,
        bloodGroup: _bloodGroup, // Use selected blood group
        fastingMode: _fastingMode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await ref.read(profileProvider.notifier).saveProfile(profile);
      
      // Navigate to dashboard after successful setup
      if (!mounted) return;
      
      print('Setup completed, navigating to dashboard');
      context.go('/dashboard');
      
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setup failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 5, // Changed from 4 to 5
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),

            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildBasicInfoPage(),
                    _buildBodyMetricsPage(),
                    _buildActivityGoalPage(),
                    _buildBloodGroupPage(), // New page
                    _buildFastingPage(),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _isSubmitting ? null : _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentPage < 4 ? 'Next' : 'Complete Setup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize your nutrition plan',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          
          // Age
          Text('Age', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Slider(
            value: _age.toDouble(),
            min: 18,
            max: 80,
            divisions: 62,
            label: '$_age years',
            onChanged: (value) {
              setState(() {
                _age = value.toInt();
              });
            },
          ),
          Text('$_age years', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),

          // Gender
          Text('Gender', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<Gender>(
            segments: Gender.values
                .map((g) => ButtonSegment(
                      value: g,
                      label: Text(g.displayName),
                    ))
                .toList(),
            selected: {_gender},
            onSelectionChanged: (Set<Gender> selected) {
              setState(() {
                _gender = selected.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetricsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.monitor_weight, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Your body metrics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use this to calculate your daily nutrition needs',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),

          // Height
          Text('Height (cm)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Slider(
            value: _height,
            min: 140,
            max: 220,
            divisions: 80,
            label: '${_height.toInt()} cm',
            onChanged: (value) {
              setState(() {
                _height = value;
              });
            },
          ),
          Text('${_height.toInt()} cm',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),

          // Weight
          Text('Weight (kg)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Slider(
            value: _weight,
            min: 40,
            max: 150,
            divisions: 110,
            label: '${_weight.toInt()} kg',
            onChanged: (value) {
              setState(() {
                _weight = value;
              });
            },
          ),
          Text('${_weight.toInt()} kg',
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildActivityGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Activity & Goals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),

          // Activity Level
          Text('Activity Level', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...ActivityLevel.values.map((level) => RadioListTile<ActivityLevel>(
                title: Text(level.displayName),
                subtitle: Text(level.description),
                value: level,
                groupValue: _activityLevel,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _activityLevel = value;
                    });
                  }
                },
              )),
          const SizedBox(height: 24),

          // Goal
          Text('Nutrition Goal', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...NutritionGoal.values.map((goal) => RadioListTile<NutritionGoal>(
                title: Text(goal.displayName),
                subtitle: Text(goal.description),
                value: goal,
                groupValue: _goal,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _goal = value;
                    });
                  }
                },
              )),
        ],
      ),
    );
  }

  Widget _buildBloodGroupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bloodtype, size: 64, color: Colors.red),
          const SizedBox(height: 24),
          Text(
            'Blood Group',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us recommend foods that work best with your blood type',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),

          // Blood Group Selection
          Text('Select your blood group', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: BloodGroup.values.map((bloodGroup) {
              final isSelected = _bloodGroup == bloodGroup;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _bloodGroup = bloodGroup;
                  });
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bloodGroup.displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        bloodGroup.type,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.restaurant, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Fasting Preference',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Are you following Ethiopian Orthodox fasting?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),

          Card(
            child: SwitchListTile(
              title: const Text('Ethiopian Orthodox Fasting'),
              subtitle: const Text(
                'Excludes meat, poultry, fish, dairy, and eggs',
              ),
              value: _fastingMode,
              onChanged: (value) {
                setState(() {
                  _fastingMode = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          if (_fastingMode)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We will only recommend fasting-friendly foods',
                      style: TextStyle(color: Colors.green[900]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
