// sets_playlists_routes.dart — Named routes for Module 7

import 'package:flutter/material.dart';

import 'package:cross_team5/features/sets_playlists/screens/my_playlists_screen.dart';
import 'package:cross_team5/features/sets_playlists/screens/my_albums_screen.dart';
import 'package:cross_team5/features/sets_playlists/screens/playlist_detail_screen.dart';
import 'package:cross_team5/features/sets_playlists/screens/album_detail_screen.dart';
import 'package:cross_team5/features/sets_playlists/screens/edit_playlist_screen.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

class SetsPlaylistsRoutes {
  static const String myPlaylists = '/playlists';
  static const String myAlbums = '/albums';
  static const String playlistDetail = '/playlists/detail';
  static const String albumDetail = '/albums/detail';
  static const String editPlaylist = '/playlists/edit';

  static Map<String, WidgetBuilder> routes = {
    myPlaylists: (context) => const MyPlaylistsScreen(),

    myAlbums: (context) => const MyAlbumsScreen(),

    playlistDetail: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return PlaylistDetailScreen(
        playlistId: args['playlistId'] as String,
        isOwner: (args['isOwner'] ?? false) as bool,
      );
    },

    albumDetail: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return AlbumDetailScreen(
        playlistId: args['playlistId'] as String,
        isOwner: (args['isOwner'] ?? false) as bool,
      );
    },

    editPlaylist: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return EditPlaylistScreen(playlist: args['playlist'] as PlaylistModel);
    },
  };
}
