import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/discovery_item.dart';

// --- Constants ---
const Color primaryGreen = Color(0xFF1E5631);
const Color lightBackground = Color(0xFFF9F9F7);

class DiscoveriesScreen extends StatefulWidget {
  const DiscoveriesScreen({super.key});

  @override
  State<DiscoveriesScreen> createState() => _DiscoveriesScreenState();
}

class _DiscoveriesScreenState extends State<DiscoveriesScreen> with TickerProviderStateMixin {
  // --- UI Controllers ---
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();

  // --- State Management ---
  bool _isLoading = true;
  String? _errorMessage;
  List<DiscoveryItem> _allDiscoveries = [];
  List<DiscoveryItem> _filteredDiscoveries = [];
  List<String> _categories = ['All'];

  // --- API Configuration ---
  User? _user;
  String? _authToken;
  final String _apiUrl = Platform.isAndroid 
    ? "http://192.168.100.9:8000/api/v1/discoveries/" 
    : "http://localhost:8000/api/v1/discoveries/";
    
  bool _initializedFromArgs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _searchController.addListener(_filterDiscoveries);
    _tabController?.addListener(_filterDiscoveries);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromArgs) return;
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final userArg = args?['user'];
    if (userArg is User) {
      _user = userArg;
      _initializedFromArgs = true;
      _initializeTokenAndFetch();
    }
  }

  Future<void> _initializeTokenAndFetch() async {
    try {
      final token = await _user?.getIdToken();
      if (!mounted) return;
      setState(() {
        _authToken = token;
      });
      await _fetchDiscoveries();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to acquire auth token: $e';
      });
    }
  }

  Future<void> _fetchDiscoveries() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final authToken = _authToken;
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<DiscoveryItem> items = data.map((json) => DiscoveryItem.fromJson(json)).toList();
        
        // Generate categories dynamically from the fetched items
        final Set<String> uniqueCategories = {'All', ...items.map((item) => item.category)};
        final List<String> newCategories = uniqueCategories.toList();
        
        if (!mounted) return;
        
        // Dispose old controller and create new one
        _tabController?.dispose();
        _tabController = TabController(length: newCategories.length, vsync: this);
        _tabController?.addListener(_filterDiscoveries);
        
        setState(() {
          _allDiscoveries = items;
          _filteredDiscoveries = items;
          _categories = newCategories;
        });
      } else {
        throw Exception('Failed to load discoveries (Status code: ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "An error occurred: ${e.toString()}");
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filterDiscoveries() {
    final searchQuery = _searchController.text.toLowerCase();
    
    if (_tabController == null || _tabController!.index >= _categories.length) return;
    final selectedCategory = _categories[_tabController!.index];

    setState(() {
      _filteredDiscoveries = _allDiscoveries.where((item) {
        final matchesCategory = selectedCategory == 'All' || item.category == selectedCategory;
        final matchesSearch = item.name.toLowerCase().contains(searchQuery);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('CBSee', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchAndFilter(),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text('Failed to load discoveries', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchDiscoveries,
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_allDiscoveries.isEmpty) {
      return const Center(
        child: Text(
          'No discoveries yet. Start scanning!',
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      );
    }
    return Column(
      children: [
        _buildTabBar(),
        Expanded(child: _buildTabBarView()),
      ],
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Discoveries', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 4),
        Text('View your past discoveries and progress.', style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search your discoveries...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () { /* TODO: Implement sort/filter logic */ },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: const Icon(Icons.filter_list, color: primaryGreen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }
    return TabBar(
      controller: _tabController,
      tabs: _categories.map((category) => Tab(text: category)).toList(),
      labelColor: primaryGreen,
      unselectedLabelColor: Colors.grey,
      indicatorColor: primaryGreen,
      indicatorWeight: 3.0,
      isScrollable: true,
    );
  }

  Widget _buildTabBarView() {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }
    return TabBarView(
      controller: _tabController,
      children: _categories.map((_) {
        if (_filteredDiscoveries.isEmpty) {
          return const Center(
            child: Text('No discoveries match your search.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          );
        }
        return DiscoveryGrid(items: _filteredDiscoveries);
      }).toList(),
    );
  }
}

class DiscoveryGrid extends StatelessWidget {
  final List<DiscoveryItem> items;
  const DiscoveryGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return DiscoveryCard(item: items[index]);
      },
    );
  }
}

class DiscoveryCard extends StatelessWidget {
  final DiscoveryItem item;
  const DiscoveryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.imageUrl.isNotEmpty)
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                return progress == null ? child : const Center(child: CircularProgressIndicator(color: primaryGreen));
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
              },
            )
          else
            Container(color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Text(
                item.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        ],
      ),
    );
  }
}








