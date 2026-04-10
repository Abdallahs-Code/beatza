import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/track_model.dart';

class SmartWaveformPlayer extends StatefulWidget {
  final TrackModel track;
  final VoidCallback? onClose;

  const SmartWaveformPlayer({super.key, required this.track, this.onClose});

  @override
  State<SmartWaveformPlayer> createState() => _SmartWaveformPlayerState();
}

class _SmartWaveformPlayerState extends State<SmartWaveformPlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<double> _waveformHeights = [];
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _generateWaveform();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant SmartWaveformPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _generateWaveform();
      _playTrack();
    }
  }

  void _generateWaveform() {
    final random = Random(widget.track.id.hashCode);
    _waveformHeights = List.generate(60, (_) => random.nextDouble() * 40 + 10);
  }

  void _initPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
    });
    _playTrack();
  }

  void _playTrack() async {
    if (widget.track.audioUrl.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(widget.track.audioUrl));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file not found!'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  void _showDevicesModal() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Current Device', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.speaker_phone, color: Color(0xFFFF5500)),
                    title: const Text('Speaker', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Other Devices', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.airplay, color: Colors.white),
                    title: const Text('AirPlay or Bluetooth', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cast, color: Colors.white),
                    title: const Text('Google Cast', style: TextStyle(color: Colors.white, fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
  void _showFullPlayer() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    image: widget.track.coverImagePath != null
                        ? DecorationImage(
                      image: FileImage(File(widget.track.coverImagePath!)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
                    )
                        : null,
                    color: const Color(0xFF121212),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(2)))),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32), onPressed: () => Navigator.pop(context)),
                            const Icon(Icons.more_horiz, color: Colors.white, size: 28),
                          ],
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder<Duration>(
                          stream: _audioPlayer.onPositionChanged,
                          builder: (context, snapshot) {
                            double progress = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                height: 60,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(_waveformHeights.length, (index) {
                                    bool isPlayed = (index / _waveformHeights.length) <= progress;
                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        height: _waveformHeights[index],
                                        decoration: BoxDecoration(
                                          color: isPlayed ? const Color(0xFFFF5500) : Colors.white54,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          }
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.transparent, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _toggleLike();
                                setModalState((){});
                              },
                              child: Row(
                                children: [
                                  Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? const Color(0xFFFF5500) : Colors.white, size: 28),
                                  const SizedBox(width: 8),
                                  Text(_isLiked ? '2991' : '2990', style: TextStyle(color: _isLiked ? const Color(0xFFFF5500) : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
                                SizedBox(width: 8),
                                Text('13', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const Icon(Icons.ios_share, color: Colors.white, size: 28),
                            const Icon(Icons.playlist_add, color: Colors.white, size: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: GestureDetector(
        onTap: _showFullPlayer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: SizedBox(
                  width: 44, height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        color: const Color(0xFFFF5500),
                        backgroundColor: Colors.white10,
                        strokeWidth: 3,
                      ),
                      Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.track.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    const Text('Belal Elseddik', style: TextStyle(color: Colors.white54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

              GestureDetector(
                onTap: _showDevicesModal,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(Icons.devices, color: Color(0xFFFF5500), size: 24),
                ),
              ),
              GestureDetector(
                onTap: _toggleLike,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? const Color(0xFFFF5500) : Colors.white, size: 26),
                ),
              ),
              if (widget.onClose != null)
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}