







import 'package:flutter/material.dart';
import 'package:cross_team5/features/engagement_social_interactions/screens/likers_screen.dart';
import 'package:cross_team5/features/engagement_social_interactions/screens/comments_screen.dart';

class EngagementSocialInteractionsRoutes {
  
  
  
  
  

  static const String likers = '/engagement/likers';
  static const String comments = '/engagement/comments';

  static Map<String, WidgetBuilder> routes = {
    
    
    
    
    
    
    
    
    
    
    
    likers: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return LikersScreen(
        trackId: args['trackId'] as String,
        initialTab: args['initialTab'] as int? ?? 0,
      );
    },

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    comments: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return CommentsScreen(
        trackId: args['trackId'] as String,
        trackTitle: args['trackTitle'] as String,
        trackArtist: args['trackArtist'] as String,
        trackThumbnailUrl: args['trackThumbnailUrl'] as String?,
        currentPositionSeconds: args['currentPositionSeconds'] as int? ?? 0,
        syncWithPlayer: args['syncWithPlayer'] as bool? ?? true,
      );
    },
  };
}
