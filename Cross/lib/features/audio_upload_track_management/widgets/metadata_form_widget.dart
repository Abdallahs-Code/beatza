import 'package:flutter/material.dart';

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
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF555555)),
          labelStyle: const TextStyle(color: Color(0xFF9A9A9A)),
          prefixIcon: Icon(icon, color: const Color(0xFF9A9A9A), size: 20),
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
        const Text(
          'Track Details',
          style: TextStyle(
            color: Colors.white,
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
