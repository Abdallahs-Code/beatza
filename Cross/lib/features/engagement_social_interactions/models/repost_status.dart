// Model for the repost status of a track for the authenticated user.
// Used by: RepostBottomSheet — to pre-fill the caption field when
//          the user has already reposted and opens the sheet again.
//
// API source:
//   GET /api/engagement/tracks/v1/{trackId}/repost
//   Requires authentication (Bearer token).
//
// 200 response shape:
// {
//   "reposted":   true,
//   "caption":    "Love this track!",   ← null/absent if no caption was set
//   "repostedAt": "2025-01-15T12:00:002"
// }
//
// 401 → Authorization failed
// 404 → Track not found
//
// NOTE: There is no equivalent status endpoint for playlists.
//       Playlist repost state is inferred from the toggle response:
//       POST /api/engagement/playlists/v1/{playlistId}/repost
//       returns { "reposted": true/false, "numberOfReposts": 3 }
//
// PATCH endpoint (update caption after reposting):
//   PATCH /api/engagement/tracks/v1/{trackId}/repost
//   Body:    { "caption": "Updated caption text!" }
//   200:     { "success": true, "caption": "Updated caption text!" }
//   400:     { "error": "You have not reposted this track" }
//   Requires user to have already reposted the track.

class RepostStatus {
  final bool _reposted;
  final String? _caption;
  final String? _repostedAt;

  RepostStatus(this._reposted, this._caption, this._repostedAt);

  bool get reposted => _reposted;
  String? get caption => _caption;
  String? get repostedAt => _repostedAt;

  // ─────────────────────────────────────────────
  // Factory: parse the GET repost status response.
  // ─────────────────────────────────────────────
  factory RepostStatus.fromJson(Map<String, dynamic> json) {
    return RepostStatus(
      json['reposted'] as bool? ?? false,
      json['caption']?.toString(),
      json['repostedAt']?.toString(),
    );
  }

  // ─────────────────────────────────────────────
  // Convenience: a "not reposted" state, used as
  // the default before the API call returns.
  // ─────────────────────────────────────────────
  factory RepostStatus.notReposted() {
    return RepostStatus(false, null, null);
  }
}
