



































import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/repost_status.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';

class RepostBottomSheet extends StatefulWidget {
  
  final String? trackId;
  final String? playlistId;

  
  final String title;
  final String artist;
  final String? thumbnailUrl;

  
  final bool isCurrentlyReposted;
  final int currentRepostCount;

  
  final void Function(bool isNowReposted, int newCount) onRepostToggled;

  const RepostBottomSheet({
    super.key,
    this.trackId,
    this.playlistId,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.isCurrentlyReposted,
    required this.currentRepostCount,
    required this.onRepostToggled,
  }) : assert(
         (trackId != null) != (playlistId != null),
         'Provide exactly one of trackId or playlistId.',
       );

  @override
  State<RepostBottomSheet> createState() => _RepostBottomSheetState();
}

class _RepostBottomSheetState extends State<RepostBottomSheet> {
  final EngagementApiService _service = EngagementApiService();
  final TextEditingController _captionController = TextEditingController();
  final int _maxCaptionLength = 140;

  bool _isLoading = false;
  bool _isFetchingStatus = false;

  
  bool get _isTrack => widget.trackId != null;

  
  late bool _alreadyReposted;

  @override
  void initState() {
    super.initState();
    _alreadyReposted = widget.isCurrentlyReposted;

    
    if (_isTrack && widget.isCurrentlyReposted) {
      _fetchExistingCaption();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  
  
  
  
  Future<void> _fetchExistingCaption() async {
    setState(() => _isFetchingStatus = true);

    final result = await _service.getTrackRepostStatus(
      trackId: widget.trackId!,
    );

    if (mounted && result.$1 == 200) {
      final status = result.$2 as RepostStatus;
      if (status.caption != null && status.caption!.isNotEmpty) {
        _captionController.text = status.caption!;
      }
    }

    if (mounted) setState(() => _isFetchingStatus = false);
  }

  
  
  
  Future<void> _handleAction() async {
    setState(() => _isLoading = true);

    final caption = _captionController.text.trim();

    int statusCode;
    dynamic responseData;

    if (_isTrack) {
      
      
      if (_alreadyReposted && caption.isNotEmpty) {
        final patchResult = await _service.updateTrackRepostCaption(
          trackId: widget.trackId!,
          caption: caption,
        );
        statusCode = patchResult.$1;
        responseData = patchResult.$2;
      } else {
        final postResult = await _service.toggleTrackRepost(
          trackId: widget.trackId!,
          caption: caption.isNotEmpty ? caption : null,
        );
        statusCode = postResult.$1;
        responseData = postResult.$2;
      }
    } else {
      
      final result = await _service.togglePlaylistRepost(
        playlistId: widget.playlistId!,
      );
      statusCode = result.$1;
      responseData = result.$2;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (statusCode == 200) {
      
      bool isNowReposted;
      int newCount;

      if (responseData is Map<String, dynamic>) {
        isNowReposted = responseData['reposted'] as bool? ?? !_alreadyReposted;
        newCount =
            responseData['numberOfReposts'] as int? ??
            widget.currentRepostCount;
      } else {
        
        isNowReposted = true;
        newCount = widget.currentRepostCount;
      }

      widget.onRepostToggled(isNowReposted, newCount);
      Navigator.pop(context);

      
      final message = isNowReposted
          ? 'Reposted to your profile'
          : 'Repost removed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.container,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showSnackbar(responseData.toString());
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.container,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: AppColors.whiteSmoke),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Repost',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: AppColors.containerMid, height: 1),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    if (_isTrack) ...[
                      _isFetchingStatus
                          ? const SizedBox(
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            )
                          : TextField(
                              controller: _captionController,
                              maxLength: _maxCaptionLength,
                              maxLines: 3,
                              minLines: 2,
                              style: TextStyle(
                                color: AppColors.whiteSmoke,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a caption (optional)',
                                hintStyle: TextStyle(color: AppColors.white54),
                                counterStyle: TextStyle(
                                  color: AppColors.white54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.borderDark,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.borderDark,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.containerDark,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                      const SizedBox(height: 12),
                    ],

                    
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.containerDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: widget.thumbnailUrl != null
                                ? Image.network(
                                    widget.thumbnailUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _placeholderThumb(),
                                  )
                                : _placeholderThumb(),
                          ),
                          const SizedBox(width: 12),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: AppColors.whiteSmoke,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.artist,
                                  style: TextStyle(
                                    color: AppColors.white54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _alreadyReposted
                              ? AppColors.containerMid
                              : AppColors.whiteSmoke,
                          foregroundColor: _alreadyReposted
                              ? AppColors.whiteSmoke
                              : AppColors.pureBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          disabledBackgroundColor: AppColors.containerMid,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.whiteSmoke,
                                ),
                              )
                            : Text(
                                _alreadyReposted ? 'Remove Repost' : 'Repost',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 50,
      height: 50,
      color: AppColors.tileDark,
      child: Icon(Icons.music_note, color: AppColors.greyMuted, size: 24),
    );
  }
}
