// Dart imports
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/features/user_profile_social_identity/models/profile_link_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/user_profile_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/services/user_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileModel currentProfile;
  final String token;

  const EditProfileScreen({
    super.key,
    required this.currentProfile,
    required this.token,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserProfileService _apiService = UserProfileService();

  late final TextEditingController _displayNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarController;
  late final TextEditingController _bannerController;

  late List<ProfileLinkModel> _editableLinks;
  late List<String> _selectedGenres;

  static const List<String> _countryOptions = [
    'Egypt',
    'Saudi Arabia',
    'United Arab Emirates',
    'Qatar',
    'Kuwait',
    'Bahrain',
    'Oman',
    'Jordan',
    'Lebanon',
    'Iraq',
    'Palestine',
    'Morocco',
    'Algeria',
    'Tunisia',
    'Libya',
    'Sudan',
    'United States',
    'United Kingdom',
    'Canada',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Netherlands',
    'Turkey',
    'India',
    'Pakistan',
    'Japan',
    'China',
    'Australia',
  ];

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController(
      text: widget.currentProfile.displayName,
    );
    _cityController = TextEditingController(text: widget.currentProfile.city);
    _countryController = TextEditingController(
      text: widget.currentProfile.country,
    );
    _bioController = TextEditingController(text: widget.currentProfile.bio);
    _avatarController = TextEditingController(
      text: widget.currentProfile.profileImgLink,
    );
    _bannerController = TextEditingController(
      text: widget.currentProfile.bannerImgLink,
    );

    _editableLinks = [...widget.currentProfile.links];
    _selectedGenres = [...widget.currentProfile.favoriteGenres];
  }

  Future<void> _editField({
    required String title,
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
  }) async {
    final temp = TextEditingController(text: controller.text);

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: temp,
                maxLines: maxLines,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, temp.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        controller.text = result;
      });
    }
  }

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Select country',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 420,
                child: ListView.builder(
                  itemCount: _countryOptions.length,
                  itemBuilder: (context, index) {
                    final country = _countryOptions[index];
                    final isSelected =
                        _countryController.text.trim() == country;

                    return ListTile(
                      onTap: () => Navigator.pop(context, country),
                      title: Text(
                        country,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _countryController.text = result;
      });
    }
  }

  Future<void> _editLink({ProfileLinkModel? existing, int? index}) async {
    final nameController = TextEditingController(text: existing?.title ?? '');
    final linkController = TextEditingController(text: existing?.link ?? '');

    final result = await showModalBottomSheet<ProfileLinkModel>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existing == null ? 'Add link' : 'Edit link',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Link name',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final link = linkController.text.trim();

                    if (name.isEmpty || link.isEmpty) return;

                    Navigator.pop(
                      context,
                      ProfileLinkModel(
                        linkId: existing?.linkId ?? '',
                        title: name,
                        link: link,
                        platform: name.toLowerCase(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (index != null) {
        _editableLinks[index] = result;
      } else {
        _editableLinks.add(result);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final updated = widget.currentProfile.copyWith(
        displayName: _displayNameController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        bio: _bioController.text.trim(),
        profileImgLink: _avatarController.text.trim(),
        bannerImgLink: _bannerController.text.trim(),
        links: _editableLinks.where((e) => e.link.trim().isNotEmpty).toList(),
        favoriteGenres: _selectedGenres,
        supportLink: widget.currentProfile.supportLink,
        bannerLinks: widget.currentProfile.bannerLinks,
        firstName: widget.currentProfile.firstName,
        lastName: widget.currentProfile.lastName,
        profileUrl: widget.currentProfile.profileUrl,
      );

      await _apiService.updateUserProfile(updated, widget.token);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  int _countOf(TextEditingController controller) =>
      controller.text.trim().length;

  @override
  void dispose() {
    _displayNameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _avatarController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: top),
            color: Colors.black,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0B0B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 104,
                            decoration: BoxDecoration(
                              color: const Color(0xFF090909),
                              image: _bannerController.text.trim().isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        _bannerController.text,
                                      ),
                                      fit: BoxFit.cover,
                                      onError: (_, _) {},
                                    )
                                  : null,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 34,
                            child: _CameraBadge(
                              onTap: () => _editField(
                                title: 'Banner URL',
                                controller: _bannerController,
                                hint: 'https://example.com/banner.jpg',
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            bottom: -34,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  backgroundImage:
                                      _avatarController.text.trim().isNotEmpty
                                      ? NetworkImage(_avatarController.text)
                                      : null,
                                  child: _avatarController.text.trim().isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white38,
                                          size: 32,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  left: 18,
                                  top: 18,
                                  child: _CameraBadge(
                                    small: true,
                                    onTap: () => _editField(
                                      title: 'Avatar URL',
                                      controller: _avatarController,
                                      hint: 'https://example.com/avatar.jpg',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),
                      _EditRow(
                        label: 'Display name',
                        value: _displayNameController.text.isEmpty
                            ? 'Display name'
                            : _displayNameController.text,
                        trailing: _countOf(_displayNameController).toString(),
                        onTap: () => _editField(
                          title: 'Display name',
                          controller: _displayNameController,
                          hint: 'Enter display name',
                        ),
                      ),
                      _EditRow(
                        label: 'City',
                        value: _cityController.text.isEmpty
                            ? 'Where are you based?'
                            : _cityController.text,
                        trailing: _countOf(_cityController).toString(),
                        onTap: () => _editField(
                          title: 'City',
                          controller: _cityController,
                          hint: 'Enter city',
                        ),
                      ),
                      _EditRow(
                        label: 'Country',
                        value: _countryController.text.isEmpty
                            ? 'Select your country'
                            : _countryController.text,
                        chevron: true,
                        onTap: _pickCountry,
                      ),
                      _EditRow(
                        label: 'Bio',
                        value: _bioController.text.isEmpty
                            ? 'Tell the world a bit about yourself'
                            : _bioController.text,
                        chevron: true,
                        onTap: () => _editField(
                          title: 'Bio',
                          controller: _bioController,
                          hint: 'Write your bio',
                          maxLines: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _EditSection(
                  title: 'Linked Profiles',
                  child: Column(
                    children: [
                      ..._editableLinks.asMap().entries.map(
                        (entry) => _LinkedProfileRow(
                          label: entry.value.title.trim().isEmpty
                              ? 'Link'
                              : entry.value.title,
                          value: entry.value.link,
                          onTap: () => _editLink(
                            existing: entry.value,
                            index: entry.key,
                          ),
                          onDelete: () {
                            setState(() {
                              _editableLinks.removeAt(entry.key);
                            });
                          },
                        ),
                      ),
                      ListTile(
                        dense: true,
                        onTap: () => _editLink(),
                        leading: const Icon(Icons.add, color: Colors.white),
                        title: const Text(
                          'Add link',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _EditSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _LinkedProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _LinkedProfileRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final shownValue = value.trim().isEmpty ? 'Not linked' : value.trim();

    return ListTile(
      dense: true,
      onTap: onTap,
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        shownValue,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF9A9A9A)),
      ),
      trailing: onDelete == null
          ? const Icon(Icons.chevron_right, color: Colors.white54)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final String value;
  final String? trailing;
  final bool chevron;
  final VoidCallback onTap;

  const _EditRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
    this.chevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder =
        value == 'Where are you based?' ||
        value == 'Select your country' ||
        value == 'Select role' ||
        value == 'Tell the world a bit about yourself';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      color: isPlaceholder
                          ? const Color(0xFFCACACA)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  trailing!,
                  style: const TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 13,
                  ),
                ),
              ),
            if (chevron)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.chevron_right, color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }
}

class _CameraBadge extends StatelessWidget {
  final VoidCallback onTap;
  final bool small;

  const _CameraBadge({required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: small ? 24 : 28,
        height: small ? 24 : 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: small ? 14 : 16,
        ),
      ),
    );
  }
}
