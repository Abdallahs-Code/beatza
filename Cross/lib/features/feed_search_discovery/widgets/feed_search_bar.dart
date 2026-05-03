








import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class FeedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;
  final VoidCallback onTap;
  final Duration debounceDuration;

  const FeedSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCancel,
    required this.onTap,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<FeedSearchBar> createState() => _FeedSearchBarState();
}

class _FeedSearchBarState extends State<FeedSearchBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tileDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onTap: widget.onTap,
              onChanged: _onTextChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: AppColors.whiteSmoke, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: AppColors.white54),
                prefixIcon: Icon(Icons.search, color: AppColors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        
        if (widget.isActive)
          GestureDetector(
            onTap: widget.onCancel,
            child: Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.whiteSmoke, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }
}
