import 'dart:convert';
import 'package:cbsee_frontend/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/discovery_item.dart';

const Color primaryGreen = Color(0xFF1E5631);
const Color lightBackground = Color(0xFFF9F9F7);

class DiscoveriesScreen extends StatefulWidget {
  const DiscoveriesScreen({super.key});

  @override
  State<DiscoveriesScreen> createState() => _DiscoveriesScreenState();
}

class _DiscoveriesScreenState extends State<DiscoveriesScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<DiscoveryItem> _allDiscoveries = [];
  List<DiscoveryItem> _filteredDiscoveries = [];
  List<String> _categories = ['All'];

  // Using the global config for URL
  final String _apiUrl = "$BaseApiUrl/discoveries/";
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _searchController.addListener(_filterDiscoveries);
    // Fetch immediately
    _fetchDiscoveries();
  }

  Future<void> _fetchDiscoveries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");
      
      final token = await user.getIdToken();
      
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<DiscoveryItem> items = data.map((json) => DiscoveryItem.fromJson(json)).toList();
        
        final Set<String> uniqueCategories = {'All', ...items.map((item) => item.category)};
        final List<String> newCategories = uniqueCategories.toList();
        
        if (!mounted) return;
        
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
      setState(() => _errorMessage = "Could not load data: ${e.toString()}");
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
        title: const Text('My Collection', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryGreen),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text('Oops!', style: Theme.of(context).textTheme.headlineSmall),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchDiscoveries,
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: const Text('Try Again'),
            ),
          ],
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
        Text('Everything you have found so far.', style: TextStyle(fontSize: 16, color: Colors.black54)),
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
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    if (_tabController == null) return const SizedBox.shrink();
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
    if (_tabController == null) return const SizedBox.shrink();
    return TabBarView(
      controller: _tabController,
      children: _categories.map((_) {
        if (_filteredDiscoveries.isEmpty) {
          return const Center(
            child: Text('No matches.', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
          Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50));
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                item.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    );
  }
}