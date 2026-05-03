

























import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/widgets/common_widgets.dart';

import '../models/search_result_model.dart';
import '../models/search_suggestion_model.dart';
import '../models/search_history_item_model.dart';
import '../services/feed_search_api_service.dart';
import '../widgets/feed_search_bar.dart';
import '../widgets/vibes_grid.dart';
import '../widgets/search_result_tile.dart';
import '../widgets/search_history_tile.dart';

import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/core/navigation/profile_navigator.dart';

enum _SearchState { idle, typing, results }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;
  final FeedSearchApiService _service = FeedSearchApiService();

  
  _SearchState _state = _SearchState.idle;

  
  List<SearchSuggestionModel> _suggestions = [];
  bool _suggestionsLoading = false;
  String? _suggestionsError;

  
  List<SearchHistoryItemModel> _history = [];
  Map<String, String?> _historyImages = {};

  
  SearchResultModel? _searchResult;
  Map<String, Map<String, dynamic>> _enrichedResults = {};
  bool _resultsLoading = false;
  String? _resultsError;
  String _activeQuery = '';

  
  bool _isPermalinkResult = false;
  Map<String, dynamic>? _permalinkTrackData;

  
  static const List<String> _resultTabs = [
    'All',
    'Tracks',
    'Profiles',
    'Playlists',
    'Albums',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _resultTabs.length, vsync: this);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  

  void _onFocusChange() {
    if (_focusNode.hasFocus && _state == _SearchState.idle) {
      setState(() => _state = _SearchState.typing);
      _loadHistory();
    }
  }

  void _onSearchBarTap() {
    if (_state == _SearchState.idle) {
      setState(() => _state = _SearchState.typing);
      _loadHistory();
    }
  }

  void _onCancel() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _state = _SearchState.idle;
      _suggestions = [];
      _history = [];
      _searchResult = null;
      _enrichedResults = {};
      _resultsError = null;
      _isPermalinkResult = false;
      _permalinkTrackData = null;
    });
  }

  

  void _onQueryChanged(String query) {
    if (_state != _SearchState.typing) {
      setState(() => _state = _SearchState.typing);
    }

    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    _loadSuggestions(query.trim());
  }

  Future<void> _loadSuggestions(String query) async {
    setState(() {
      _suggestionsLoading = true;
      _suggestionsError = null;
    });
    final (code, data) = await _service.getSearchSuggestions(query);
    if (!mounted) return;
    if (code == 200 && data is List) {
      setState(() {
        _suggestions = SearchSuggestionModel.listFromJson(data);
        _suggestionsLoading = false;
        _suggestionsError = null;
      });
    } else {
      setState(() {
        _suggestionsLoading = false;
        _suggestionsError = 'HTTP $code — $data';
      });
    }
  }

  

  Future<void> _loadHistory() async {
    final (code, data) = await _service.getSearchHistory();
    if (!mounted) return;
    if (code == 200 && data is List) {
      final items = SearchHistoryItemModel.listFromJson(data);

      
      final images = <String, String?>{};
      await Future.wait(
        items.map((item) async {
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
            images[item.id] = item.imageUrl;
            return;
          }
          if (item.type == 'track') {
            final (c, trackData) = await _service.getTrackById(item.id);
            if (c == 200 && trackData is Map<String, dynamic>) {
              final img = trackData['image'] as Map<String, dynamic>? ?? {};
              images[item.id] = img['imgLink']?.toString();
            }
          } else if (item.type == 'user') {
            final (c, userData) = await _service.getUserById(item.id);
            if (c == 200 && userData is Map<String, dynamic>) {
              images[item.id] = userData['profileImgLink']?.toString();
            }
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        _history = items;
        _historyImages = images;
      });
    }
  }

  Future<void> _deleteHistoryItem(String historyId) async {
    setState(() {
      _history.removeWhere((item) => item.id == historyId);
    });
    
    await _service.deleteSearchHistoryItem(historyId);
  }

  

  
  
  
  (String, String)? _extractPermalink(String query) {
    final q = query.trim();

    
    if (q.contains('://')) {
      try {
        final uri = Uri.parse(q);
        final segments =
            uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.length >= 2) {
          return (segments[segments.length - 2], segments.last);
        }
      } catch (_) {}
      return null;
    }

    
    final normalized = q.startsWith('/') ? q.substring(1) : q;
    final parts = normalized.split('/');
    if (parts.length == 2) {
      final profileLink = parts[0].trim();
      final permalink = parts[1].trim();
      final slug = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9\-_]*$');
      if (slug.hasMatch(profileLink) && slug.hasMatch(permalink)) {
        return (profileLink, permalink);
      }
    }

    return null;
  }

  

  Future<void> _submitSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    _focusNode.unfocus();

    
    final permalinkParts = _extractPermalink(q);
    if (permalinkParts != null) {
      await _submitPermalinkSearch(permalinkParts.$1, permalinkParts.$2);
      return;
    }

    setState(() {
      _state = _SearchState.results;
      _activeQuery = q;
      _resultsLoading = true;
      _resultsError = null;
      _searchResult = null;
      _isPermalinkResult = false;
      _permalinkTrackData = null;
    });

    final (code, data) = await _service.globalSearch(query: q);
    if (!mounted) return;

    if (code == 200 && data is Map<String, dynamic>) {
      final parsed = SearchResultModel.fromJson(data);

      
      final enriched = <String, Map<String, dynamic>>{};
      await Future.wait(
        parsed.results.map((item) async {
          if (item.type == 'track') {
            final (c, trackData) = await _service.getTrackById(item.id);
            if (c == 200 && trackData is Map<String, dynamic>) {
              final basicInfo =
                  trackData['basicInfo'] as Map<String, dynamic>? ?? {};
              final image = trackData['image'] as Map<String, dynamic>? ?? {};
              final artists =
                  (basicInfo['mainArtists'] as List<dynamic>? ?? []);
              enriched[item.id] = {
                'title': basicInfo['title'] ?? item.id,
                'imageUrl': image['imgLink'],
                'subtitle': artists.isNotEmpty
                    ? artists.first.toString()
                    : 'Track',
              };
            }
          } else if (item.type == 'user') {
            final (c, userData) = await _service.getUserById(item.id);
            if (c == 200 && userData is Map<String, dynamic>) {
              enriched[item.id] = {
                'title': userData['displayName'] ?? item.id,
                'imageUrl': userData['profileImgLink'],
                'subtitle': userData['profileLink'] ?? 'User',
              };
            }
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        _searchResult = parsed;
        _enrichedResults = enriched;
        _resultsLoading = false;
      });
    } else {
      setState(() {
        _resultsError = data?.toString() ?? 'Search failed';
        _resultsLoading = false;
      });
    }
  }

  

  Future<void> _submitPermalinkSearch(
    String profileLink,
    String permalink,
  ) async {
    setState(() {
      _state = _SearchState.results;
      _activeQuery = '$profileLink/$permalink';
      _resultsLoading = true;
      _resultsError = null;
      _searchResult = null;
      _isPermalinkResult = true;
      _permalinkTrackData = null;
    });

    final (code, data) = await _service.getTrackByPermalinkV2(
      profileLink: profileLink,
      permalink: permalink,
    );
    if (!mounted) return;

    if (code == 200 && data is Map<String, dynamic>) {
      setState(() {
        _permalinkTrackData = data;
        _resultsLoading = false;
      });
    } else {
      setState(() {
        _resultsError = code == 404
            ? 'No track found for this permalink'
            : (data?.toString() ?? 'Failed to load track');
        _resultsLoading = false;
        _isPermalinkResult = false;
      });
    }
  }

  Future<void> _onPermalinkResultTap(Map<String, dynamic> trackData) async {
    final trackId = trackData['trackId'] as String? ?? '';
    if (trackId.isNotEmpty) {
      _service.addToSearchHistory(id: trackId, type: 'track');
    }
    final track = PlaybackTrackModel.fromApiJson(trackData);
    await PlaybackStreamingEngineService.shared.playTrack(track);
  }

  

  Future<void> _onResultTap(SearchResultItem item) async {
    
    _service.addToSearchHistory(id: item.id, type: item.type);

    if (item.type == 'track') {
      
      final (code, trackData) = await _service.getTrackById(item.id);
      if (!mounted) return;
      if (code == 200 && trackData is Map<String, dynamic>) {
        final track = PlaybackTrackModel.fromApiJson(trackData);
        await PlaybackStreamingEngineService.shared.playTrack(track);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load track: $trackData')),
          );
        }
      }
    } else if (item.type == 'user') {
      await ProfileNavigator.push(context, item.id);
    } else {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.type} detail screen coming soon')),
        );
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.chineseBlack,
      body: SafeArea(
        child: Column(
          children: [
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FeedSearchBar(
                controller: _searchController,
                focusNode: _focusNode,
                isActive: _state != _SearchState.idle,
                onChanged: _onQueryChanged,
                onSubmitted: _submitSearch,
                onCancel: _onCancel,
                onTap: _onSearchBarTap,
              ),
            ),

            
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(
        currentItem: AppNavItem.search,
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _SearchState.idle:
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const VibesGrid(),
              const SizedBox(height: 80),
            ],
          ),
        );

      case _SearchState.typing:
        return _buildTypingState();

      case _SearchState.results:
        return _buildResultsState();
    }
  }

  

  Widget _buildTypingState() {
    final query = _searchController.text.trim();
    final hasSuggestions = _suggestions.isNotEmpty;
    final hasHistory = _history.isNotEmpty;

    return ListView(
      children: [
        
        if (query.isNotEmpty) ...[
          if (_suggestionsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryOrange),
              ),
            )
          else if (hasSuggestions)
            ..._suggestions.map(
              (s) => ListTile(
                leading: Icon(Icons.search, color: AppColors.white54),
                title: Text(
                  s.title,
                  style: TextStyle(color: AppColors.whiteSmoke),
                ),
                trailing: Icon(
                  Icons.north_west,
                  color: AppColors.white54,
                  size: 16,
                ),
                onTap: () {
                  _searchController.text = s.title;
                  _submitSearch(s.title);
                },
              ),
            ),
        ],

        
        if (hasHistory && query.isEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Recently searched',
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ..._history.map(
            (item) => SearchHistoryTile(
              id: item.id,
              title: item.title,
              subtitle: item.metadata,
              imageUrl: _historyImages[item.id] ?? item.imageUrl,
              type: item.type,
              onTap: () {
                _searchController.text = item.title;
                _submitSearch(item.title);
              },
              onDelete: () => _deleteHistoryItem(item.id),
            ),
          ),
        ],

        if (!_suggestionsLoading &&
            !hasSuggestions &&
            !hasHistory &&
            query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _suggestionsError ?? 'No suggestions found',
                style: TextStyle(
                  color: _suggestionsError != null
                      ? AppColors.primaryOrange
                      : AppColors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  

  Widget _buildResultsState() {
    if (_resultsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_resultsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_resultsError!, style: TextStyle(color: AppColors.white54)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _submitSearch(_activeQuery),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primaryOrange),
              ),
            ),
          ],
        ),
      );
    }

    
    if (_isPermalinkResult && _permalinkTrackData != null) {
      return _buildPermalinkResult(_permalinkTrackData!);
    }

    if (_searchResult == null) return const SizedBox.shrink();

    final allResults = _searchResult!.results;
    final tracks = allResults.where((r) => r.type == 'track').toList();
    final users = allResults.where((r) => r.type == 'user').toList();
    final playlists = allResults.where((r) => r.type == 'playlist').toList();
    final albums = allResults.where((r) => r.type == 'album').toList();

    return Column(
      children: [
        
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primaryOrange,
          labelColor: AppColors.whiteSmoke,
          unselectedLabelColor: AppColors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: _resultTabs.map((t) => Tab(text: t)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResultList(allResults),
              _buildResultList(tracks),
              _buildResultList(users),
              _buildResultList(playlists),
              _buildResultList(albums),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultList(List<SearchResultItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('No results', style: TextStyle(color: AppColors.white54)),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final details = _enrichedResults[item.id];
        return SearchResultTile(
          id: item.id,
          type: item.type,
          title: details?['title'] as String? ?? item.id,
          subtitle: details?['subtitle'] as String?,
          imageUrl: details?['imageUrl'] as String?,
          onTap: () => _onResultTap(item),
        );
      },
    );
  }

  Widget _buildPermalinkResult(Map<String, dynamic> trackData) {
    final basicInfo = trackData['basicInfo'] as Map<String, dynamic>? ?? {};
    final image = trackData['image'] as Map<String, dynamic>? ?? {};
    final artists = (basicInfo['mainArtists'] as List<dynamic>? ?? []);
    final title = basicInfo['title'] as String? ?? 'Unknown Track';
    final artist = artists.isNotEmpty ? artists.first.toString() : '';
    final imageUrl = image['imgLink'] as String?;
    final trackId = trackData['trackId'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Track found',
            style: TextStyle(
              color: AppColors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SearchResultTile(
          id: trackId,
          type: 'track',
          title: title,
          subtitle: artist.isNotEmpty ? artist : null,
          imageUrl: imageUrl,
          onTap: () => _onPermalinkResultTap(trackData),
        ),
      ],
    );
  }
}
