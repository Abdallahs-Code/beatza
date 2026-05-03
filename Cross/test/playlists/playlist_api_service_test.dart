


import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:cross_team5/features/sets_playlists/services/playlist_api_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => 'http://localhost:4123';
}

void main() {
  late MockHttpClient mockClient;
  late MockFlutterSecureStorage mockStorage;
  late PlaylistApiService service;

  const String fakeToken = 'fake_jwt_token';

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost:4123'));
    registerFallbackValue(
      http.Request('GET', Uri.parse('http://localhost/fallback')),
    );
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockStorage = MockFlutterSecureStorage();

    when(
      () => mockStorage.read(key: 'access_token'),
    ).thenAnswer((_) async => fakeToken);

    service = PlaylistApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      storage: mockStorage,
    );
  });

  

  Map<String, dynamic> makePlaylistJson({
    String id = 'playlist_001',
    String title = 'Test Playlist',
    bool isPrivate = false,
    List<String> tracks = const [],
  }) {
    return {
      '_id': id,
      'artistId': 'artist_001',
      'title': title,
      'description': 'Test description',
      'genre': 'Electronic',
      'listOfTracks': tracks,
      'additionalTags': [],
      'permalink': 'test-playlist',
      'type': isPrivate ? 'private' : 'public',
      'numOfLikes': 5,
      'numOfReposts': 2,
      'playlistType': 'playlist',
      'playlistLengthInSeconds': 360,
      'likedUser': [],
      'isLiked': false,
      'isReposted': false,
      'image': {
        'imgLink': 'https://example.com/img.jpg',
        'publicId': 'playlist/file_abc',
      },
      'createdAt': '2026-04-20T15:12:45.273Z',
      'updatedAt': '2026-04-20T18:04:13.650Z',
    };
  }

  http.Response jsonResponse(dynamic body, int statusCode) {
    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }

  

  group('PlaylistModel.fromJson', () {
    test('parses all fields correctly', () {
      final json = makePlaylistJson(title: 'My Jams', isPrivate: true);
      final model = PlaylistModel.fromJson(json);

      expect(model.id, 'playlist_001');
      expect(model.title, 'My Jams');
      expect(model.isPrivate, isTrue);
      expect(model.playlistType, 'playlist');
      expect(model.numOfLikes, 5);
      expect(model.image!.imgLink, 'https://example.com/img.jpg');
    });

    test('parses secret_token alias into secretToken', () {
      final json = Map<String, dynamic>.from(
        makePlaylistJson(isPrivate: true),
      )..['secret_token'] = 'tok_test_abc';

      final model = PlaylistModel.fromJson(json);
      expect(model.secretToken, 'tok_test_abc');
    });

    test('handles missing optional fields gracefully', () {
      final json = <String, dynamic>{
        '_id': 'p1',
        'artistId': 'a1',
        'title': 'Min',
        
      };
      final model = PlaylistModel.fromJson(json);
      expect(model.id, 'p1');
      expect(model.isPrivate, isFalse);
      expect(model.tracks, isEmpty);
      expect(model.image, isNull);
    });
  });

  group('createPlaylist', () {
    test('returns 200 and created PlaylistModel on success', () async {
      final responseBody = {
        'message': 'Created successfully',
        'data': {
          'playlists': [makePlaylistJson(title: 'New Playlist')],
        },
      };

      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => jsonResponse(responseBody, 200));

      final (statusCode, playlist) = await service.createPlaylist(
        playlistName: 'New Playlist',
        isPrivate: false,
      );

      expect(statusCode, 200);
      expect(playlist, isNotNull);
      expect(playlist!.title, 'New Playlist');
    });

    test('returns 403 when free user hits limit', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse({'message': 'Not enough permissions'}, 403),
      );

      final (statusCode, playlist) = await service.createPlaylist(
        playlistName: 'Extra',
      );

      expect(statusCode, 403);
      expect(playlist, isNull);
    });

    test('returns 401 when token is missing', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);

      final (statusCode, playlist) = await service.createPlaylist(
        playlistName: 'New',
      );

      expect(statusCode, 401);
      expect(playlist, isNull);
    });
  });

  // ── Get my playlists ─────────────────────────────────────────────────────

  group('getMyPlaylists', () {
    test('returns list of playlists on 200', () async {
      final responseBody = {
        'message': 'Playlists retrieved successfully',
        'data': {
          'playlists': [
            makePlaylistJson(id: 'p1', title: 'Playlist 1'),
            makePlaylistJson(id: 'p2', title: 'Playlist 2'),
          ],
        },
      };

      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => jsonResponse(responseBody, 200));

      final (statusCode, playlists) = await service.getMyPlaylists();

      expect(statusCode, 200);
      expect(playlists.length, 2);
      expect(playlists[0].title, 'Playlist 1');
    });

    test('returns empty list on 401', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);

      final (statusCode, playlists) = await service.getMyPlaylists();

      expect(statusCode, 401);
      expect(playlists, isEmpty);
    });
  });

  // ── Create playlist — POST …/with-image only (multipart, optional image) ─

  group('createPlaylistWithImage', () {
    test('returns playlist on 200 without image file', () async {
      final responseBody = {
        'message': 'Created successfully',
        'data': {
          'playlists': [
            makePlaylistJson(id: 'new_p', title: 'Created'),
          ],
        },
      };
      final bytes = utf8.encode(jsonEncode(responseBody));

      when(() => mockClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream<List<int>>.value(bytes),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final (code, model) = await service.createPlaylistWithImage(
        title: 'Created',
        listOfTracks: const ['track_a'],
        imagePath: null,
      );

      expect(code, 200);
      expect(model, isNotNull);
      expect(model!.id, 'new_p');
      verify(() => mockClient.send(any())).called(1);
    });

    test('returns 401 when no token without calling send', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);

      final (code, model) = await service.createPlaylistWithImage(
        title: 'X',
        imagePath: null,
      );

      expect(code, 401);
      expect(model, isNull);
      verifyNever(() => mockClient.send(any()));
    });
  });

  // ── Add track to playlist ────────────────────────────────────────────────
  // Service uses PATCH /playlists/v1/{playlistId}/tracks/{trackId}

  group('addTrackToPlaylist', () {
    test('returns 200 and success message', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => jsonResponse({
          'message': 'Track added to playlist successfully',
        }, 200),
      );

      final (statusCode, message) = await service.addTrackToPlaylist(
        playlistId: 'playlist_001',
        trackId: 'track_001',
      );

      expect(statusCode, 200);
      expect(message, contains('added'));
    });

    test('returns 403 when not owner', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => jsonResponse({'message': 'Not enough permissions'}, 403),
      );

      final (statusCode, _) = await service.addTrackToPlaylist(
        playlistId: 'playlist_001',
        trackId: 'track_999',
      );

      expect(statusCode, 403);
    });
  });

  

  group('removeTrackFromPlaylist', () {
    test('returns 200 on success', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            jsonResponse({'message': 'Track removed successfully'}, 200),
      );

      final (statusCode, message) = await service.removeTrackFromPlaylist(
        playlistId: 'playlist_001',
        trackId: 'track_001',
      );

      expect(statusCode, 200);
    });

    test('returns 403 when not owner', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => jsonResponse({'message': 'Not enough permissions'}, 403),
      );

      final (statusCode, _) = await service.removeTrackFromPlaylist(
        playlistId: 'p1',
        trackId: 't1',
      );

      expect(statusCode, 403);
    });
  });

  

  group('reorderTrack', () {
    test('returns 200 on success', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            jsonResponse({'message': 'Track order updated successfully'}, 200),
      );

      final (statusCode, message) = await service.reorderTrack(
        playlistId: 'playlist_001',
        trackId: 'track_001',
        oldPosition: 0,
        newPosition: 3,
      );

      expect(statusCode, 200);
      expect(message, contains('updated'));
    });

    test('returns 403 when not owner', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse({'message': 'Not enough permissions'}, 403),
      );

      final (statusCode, _) = await service.reorderTrack(
        playlistId: 'p1',
        trackId: 't1',
        oldPosition: 0,
        newPosition: 2,
      );

      expect(statusCode, 403);
    });

    test('sends correct body', () async {
      String? capturedBody;
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((invocation) async {
        capturedBody =
            invocation.namedArguments[const Symbol('body')] as String?;
        return jsonResponse({
          'message': 'Track order updated successfully',
        }, 200);
      });

      await service.reorderTrack(
        playlistId: 'p1',
        trackId: 'trk_123',
        oldPosition: 0,
        newPosition: 3,
      );

      expect(capturedBody, isNotNull);
      final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(decoded['trackId'], 'trk_123');
      expect(decoded['oldPosition'], 0);
      expect(decoded['newPosition'], 3);
    });
  });

  

  group('deletePlaylist', () {
    test('returns 200 and deleted:true on success', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => jsonResponse({
          'message': 'Deleted successfully',
          'data': {'deleted': true},
        }, 200),
      );

      final (statusCode, deleted) = await service.deletePlaylist(
        playlistId: 'playlist_001',
      );

      expect(statusCode, 200);
      expect(deleted, isTrue);
    });

    test('returns 200 and deleted:true when backend omits deleted flag', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            jsonResponse({'message': 'Deleted successfully', 'data': {}}, 200),
      );

      final (statusCode, deleted) = await service.deletePlaylist(
        playlistId: 'playlist_001',
      );

      expect(statusCode, 200);
      expect(deleted, isTrue);
    });

    test('returns 403 when not owner', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => jsonResponse({
          'message': 'Not enough permissions to access this resource',
        }, 403),
      );

      final (statusCode, deleted) = await service.deletePlaylist(
        playlistId: 'p_other',
      );

      expect(statusCode, 403);
      expect(deleted, isFalse);
    });

    test('returns 404 when playlist not found', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            jsonResponse({'message': 'Property not found or not updated'}, 404),
      );

      final (statusCode, deleted) = await service.deletePlaylist(
        playlistId: 'nonexistent',
      );

      expect(statusCode, 404);
      expect(deleted, isFalse);
    });

    test('returns 401 when token missing', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);

      final (statusCode, deleted) = await service.deletePlaylist(
        playlistId: 'p1',
      );

      expect(statusCode, 401);
      expect(deleted, isFalse);
    });
  });

  

  group('getPlaylistWithTracks', () {
    test('returns paginated playlist with tracks on 200', () async {
      final playlistJson = {
        ...makePlaylistJson(id: 'p1', title: 'My Set'),
        'totalTracks': 2,
        'totalPages': 1,
        'page': 1,
        'tracks': [
          {
            '_id': 't1',
            'basicInfo': {
              'title': 'Track A',
              'permalink': 'track-a',
              'mainArtists': ['Artist One'],
            },
            'durationInSeconds': 180,
            'numOfPlays': 100,
            'numOfLikes': 20,
            'isLiked': false,
            'isReposted': false,
          },
        ],
      };

      final responseBody = {
        'message': 'Playlists retrieved successfully',
        'data': {
          'playlist': [playlistJson],
        },
      };

      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => jsonResponse(responseBody, 200));

      final (statusCode, playlist) = await service.getPlaylistWithTracks(
        playlistId: 'p1',
      );

      expect(statusCode, 200);
      expect(playlist, isNotNull);
      expect(playlist!.title, 'My Set');
      expect(playlist.tracks.length, 1);
      expect(playlist.tracks.first.title, 'Track A');
      expect(playlist.totalTracks, 2);
    });
  });
}
