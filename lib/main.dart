import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui'; // Import for ImageFilter

// 1. Data Model for an Institution
class Institution {
  final String name;
  final String type;
  final String?
  website; // Nullable as some institutions might not have a website listed

  Institution({required this.name, required this.type, this.website});

  // Factory constructor to create an Institution from a JSON map
  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      name: json['name'] as String,
      type: json['type'] as String,
      website: json['website'] as String?,
    );
  }
}

// Custom widget for text with a gradient
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: (style ?? Theme.of(context).textTheme.titleLarge)?.copyWith(
          color: Colors.white,
        ), // Ensures text color is white for gradient mask
        textAlign: textAlign,
      ),
    );
  }
}

// 2. Main Application Widget
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SA Educational Institutions',
      theme: ThemeData(
        // Using a light overall background from the palette for a clean minimalistic look
        scaffoldBackgroundColor: Colors.grey[100], // A very light grey
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor:
              Colors.grey[100], // Solid background from the palette
          foregroundColor: Colors.black, // Default text color for AppBar
          centerTitle: true,
          elevation: 0.0, // Flat AppBar for minimalistic design
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.grey[800], // Darker color for selected tab text
          unselectedLabelColor: Colors.grey[600], // Lighter for unselected
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: Colors.grey[800]!,
              width: 3.0,
            ), // Indicator color
          ),
        ),
        // No CardTheme needed as we're using custom liquid glass containers
      ),
      home: const InstitutionHomePage(),
    );
  }
}

// 3. Home Page Widget to Load and Display Data
class InstitutionHomePage extends StatefulWidget {
  const InstitutionHomePage({super.key});

  @override
  State<InstitutionHomePage> createState() => _InstitutionHomePageState();
}

class _InstitutionHomePageState extends State<InstitutionHomePage> {
  // Maps to store categorized institutions
  Map<String, List<Institution>> _categorizedInstitutions = {};
  bool _isLoading = true;
  String _errorMessage = '';

  // Controller for the search text field
  final TextEditingController _searchController = TextEditingController();
  // Current search query
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
    // Add listener to the search controller to update search query
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Method to update the search query
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Function to load JSON data from assets
  Future<void> _loadInstitutions() async {
    try {
      final String response = await rootBundle.loadString('assets/list.json');
      final data = json.decode(response) as Map<String, dynamic>;

      setState(() {
        _categorizedInstitutions = data.map((key, value) {
          return MapEntry(
            key,
            (value as List)
                .map(
                  (item) => Institution.fromJson(item as Map<String, dynamic>),
                )
                .toList(),
          );
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load institutions: $e';
        _isLoading = false;
      });
      print('Error loading institutions: $e'); // For debugging
    }
  }

  // Method to filter institutions based on the current search query
  List<Institution> _getFilteredInstitutions(List<Institution> institutions) {
    if (_searchQuery.isEmpty) {
      return institutions;
    } else {
      return institutions.where((institution) {
        return institution.name.toLowerCase().contains(_searchQuery) ||
            institution.type.toLowerCase().contains(_searchQuery) ||
            (institution.website?.toLowerCase().contains(_searchQuery) ??
                false);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Data...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Define the tabs and their corresponding institution lists
    final List<String> tabTitles = [
      'Public Uni',
      'Private HE',
      'Public TVET',
      'Private Coll',
    ];

    // Map the JSON keys to the display tab titles
    final Map<String, String> categoryMap = {
      'public_universities': 'Public Uni',
      'private_higher_education_institutions': 'Private HE',
      'public_tvet_colleges': 'Public TVET',
      'private_colleges': 'Private Coll',
    };

    return DefaultTabController(
      length: tabTitles.length,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight:
              100, // Increase toolbar height to accommodate search bar
          title: Column(
            // Use a Column to stack title and search bar
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GradientText(
                // App title with gradient for minimalistic touch
                'University Hub',
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 65, 15, 56)!,
                    const Color.fromARGB(255, 194, 28, 166)!,
                  ], // Subtle grey gradient
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8), // Spacing between title and search bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController, // Assign the controller
                  decoration: InputDecoration(
                    hintText: 'Search institutions...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors
                        .grey[200], // Light grey background for search bar
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        25.0,
                      ), // Rounded edges for search bar
                      borderSide: BorderSide.none, // No border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(
                        color: Colors.blueGrey[400]!,
                        width: 1.0,
                      ), // Subtle border on focus
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.grey[900]),
                  cursorColor: Colors.grey[800],
                ),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true, // Allow tabs to scroll if many
            tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          ),
        ),
        body: Container(
          // Using a solid color background from the palette
          color: Colors
              .grey[100], // Matches scaffoldBackgroundColor for a clean base
          child: TabBarView(
            children: tabTitles.map((title) {
              // Find the corresponding JSON key for the tab title
              String? jsonKey;
              categoryMap.forEach((key, value) {
                if (value == title) {
                  jsonKey = key;
                }
              });

              final List<Institution> institutions =
                  _categorizedInstitutions[jsonKey] ?? [];
              // Pass the filtered list to InstitutionList
              return InstitutionList(
                institutions: _getFilteredInstitutions(institutions),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// 4. Widget to display a list of Institutions
class InstitutionList extends StatelessWidget {
  final List<Institution> institutions;

  const InstitutionList({super.key, required this.institutions});

  // Function to launch URL
  Future<void> _launchURL(BuildContext context, String? url) async {
    if (url != null) {
      final Uri uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar(context, 'Could not launch $url');
        }
      } catch (e) {
        _showErrorSnackBar(
          context,
          'An error occurred while launching the URL: $e',
        );
      }
    } else {
      _showErrorSnackBar(context, 'No website link available.');
    }
  }

  // Helper to show a SnackBar for errors/messages
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (institutions.isEmpty) {
      return const Center(
        child: Text('No institutions found for this search in this category.'),
      );
    }

    return ListView.builder(
      // Reverted to ListView.builder
      padding: const EdgeInsets.all(12.0),
      itemCount: institutions.length,
      itemBuilder: (context, index) {
        final institution = institutions[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: ClipRRect(
            // Ensures content is clipped to rounded corners
            borderRadius: BorderRadius.circular(
              12.0,
            ), // Rounded corners for cards
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 8.0,
                sigmaY: 8.0,
              ), // Blur intensity for liquid glass
              child: InkWell(
                onTap: () => _launchURL(context, institution.website),
                borderRadius: BorderRadius.circular(
                  12.0,
                ), // Match InkWell ripple to card shape
                child: Container(
                  decoration: BoxDecoration(
                    // Applied a subtle linear gradient to the card backgrounds
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(
                          0.3,
                        ), // Start with a lighter, more transparent white
                        Colors.white.withOpacity(
                          0.1,
                        ), // End with a slightly more transparent white
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ), // Rounded corners for container
                    border: Border.all(
                      color: Colors.grey.withOpacity(
                        0.3,
                      ), // Light border for definition
                      width: 1.0,
                    ),
                    boxShadow: [
                      // Subtle shadow for a lifted effect on the glass
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2), // Lighter shadow
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(
                    16.0,
                  ), // Reverted internal padding
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Centered text horizontally
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        institution.name,
                        textAlign:
                            TextAlign.center, // Ensure text itself is centered
                        maxLines: 3, // Allow text to wrap, but limit lines
                        overflow: TextOverflow
                            .ellipsis, // Add ellipsis if text overflows
                        style: TextStyle(
                          fontSize: 18, // Reverted font size
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .grey[900], // Dark text for contrast on light background
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        institution.type,
                        textAlign:
                            TextAlign.center, // Ensure text itself is centered
                        maxLines: 2, // Limit lines for type
                        overflow: TextOverflow
                            .ellipsis, // Add ellipsis if text overflows
                        style: TextStyle(
                          fontSize: 14, // Reverted font size
                          color: Colors
                              .grey[700], // Slightly lighter grey for type
                        ),
                      ),
                      // Removed the website Text widget to no longer display the link on the card
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
