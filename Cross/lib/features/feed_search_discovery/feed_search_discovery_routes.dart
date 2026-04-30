// Routes: FeedSearchDiscoveryRoutes
// Module 8 — Feed, Search & Discovery
//
// Spread into AppRouter.routes:
//   ...FeedSearchDiscoveryRoutes.routes
//
// Available routes:
//   /feed    → FeedScreen  (Discover + Following tabs)
//   /search  → SearchScreen

import 'package:flutter/material.dart';

import 'screens/feed_screen.dart';
import 'screens/search_screen.dart';

class FeedSearchDiscoveryRoutes {
  FeedSearchDiscoveryRoutes._();

  static const String feed = '/feed';
  static const String search = '/search';

  static Map<String, WidgetBuilder> get routes => {
    feed: (_) => const FeedScreen(),
    search: (_) => const SearchScreen(),
  };
}
