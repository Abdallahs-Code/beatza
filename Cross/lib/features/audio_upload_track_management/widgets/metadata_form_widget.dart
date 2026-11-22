import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class MetadataFormWidget extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController genreController;
  final TextEditingController tagsController;

  const MetadataFormWidget({
    super.key,
    required this.titleController,
    required this.genreController,
    required this.tagsController,
  });

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white10),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppColors.whiteSmoke),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.greyDark3),
          labelStyle: TextStyle(color: AppColors.greyMedium),
          prefixIcon: Icon(icon, color: AppColors.greyMedium, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Track Details',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(titleController, 'Title', Icons.title),
        _buildTextField(
          genreController,
          'Genre',
          Icons.music_note,
          hint: 'e.g. Hip-Hop, Pop',
        ),
        _buildTextField(
          tagsController,
          'Tags',
          Icons.tag,
          hint: 'Comma separated',
        ),
      ],
    );
  }
}
