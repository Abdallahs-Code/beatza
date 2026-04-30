// Dart imports
import 'dart:io';

// Package imports
import 'package:cross_team5/features/user_profile_social_identity/models/profile_link_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/user_profile_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _displayNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarController;
  late final TextEditingController _bannerController;

  late List<ProfileLinkModel> _editableLinks;
  late List<ProfileLinkModel> _editableBannerLinks;
  late List<String> _selectedGenres;

  bool _saving = false;

  static const Map<String, List<String>> _countryCityMap = {
    'Egypt': [
      'Cairo',
      'Giza',
      'Alexandria',
      'Mansoura',
      'Tanta',
      'Zagazig',
      'Ismailia',
      'Port Said',
      'Suez',
      'Fayoum',
      'Minya',
      'Asyut',
      'Sohag',
      'Qena',
      'Luxor',
      'Aswan',
    ],
    'Saudi Arabia': [
      'Riyadh',
      'Jeddah',
      'Mecca',
      'Medina',
      'Dammam',
      'Khobar',
      'Taif',
      'Abha',
      'Tabuk',
      'Jazan',
    ],
    'United Arab Emirates': [
      'Dubai',
      'Abu Dhabi',
      'Sharjah',
      'Ajman',
      'Al Ain',
      'Ras Al Khaimah',
      'Fujairah',
      'Umm Al Quwain',
    ],
    'Qatar': ['Doha', 'Al Rayyan', 'Al Wakrah', 'Al Khor', 'Lusail'],
    'Kuwait': ['Kuwait City', 'Hawalli', 'Farwaniya', 'Ahmadi', 'Jahra'],
    'Bahrain': ['Manama', 'Muharraq', 'Riffa', 'Hamad Town', 'A’ali'],
    'Oman': ['Muscat', 'Salalah', 'Sohar', 'Nizwa', 'Sur'],
    'Jordan': ['Amman', 'Irbid', 'Zarqa', 'Aqaba', 'Madaba'],
    'Lebanon': ['Beirut', 'Tripoli', 'Sidon', 'Tyre', 'Jounieh'],
    'Iraq': ['Baghdad', 'Basra', 'Mosul', 'Erbil', 'Najaf', 'Karbala'],
    'Palestine': [
      'Jerusalem',
      'Ramallah',
      'Nablus',
      'Hebron',
      'Gaza',
      'Bethlehem',
    ],
    'Morocco': ['Casablanca', 'Rabat', 'Marrakesh', 'Fez', 'Tangier', 'Agadir'],
    'Algeria': ['Algiers', 'Oran', 'Constantine', 'Annaba', 'Blida'],
    'Tunisia': ['Tunis', 'Sfax', 'Sousse', 'Kairouan', 'Bizerte'],
    'Libya': ['Tripoli', 'Benghazi', 'Misrata', 'Zawiya', 'Sabha'],
    'Sudan': ['Khartoum', 'Omdurman', 'Port Sudan', 'Nyala', 'Kassala'],
    'United States': [
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'Miami',
      'San Francisco',
      'Washington',
    ],
    'United Kingdom': [
      'London',
      'Manchester',
      'Birmingham',
      'Liverpool',
      'Leeds',
      'Glasgow',
    ],
    'Canada': [
      'Toronto',
      'Vancouver',
      'Montreal',
      'Ottawa',
      'Calgary',
      'Edmonton',
    ],
    'Germany': [
      'Berlin',
      'Munich',
      'Hamburg',
      'Frankfurt',
      'Cologne',
      'Stuttgart',
    ],
    'France': ['Paris', 'Marseille', 'Lyon', 'Toulouse', 'Nice'],
    'Italy': ['Rome', 'Milan', 'Naples', 'Turin', 'Florence'],
    'Spain': ['Madrid', 'Barcelona', 'Valencia', 'Seville', 'Malaga'],
    'Netherlands': [
      'Amsterdam',
      'Rotterdam',
      'The Hague',
      'Utrecht',
      'Eindhoven',
    ],
    'Turkey': ['Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Antalya'],
    'India': [
      'Mumbai',
      'Delhi',
      'Bangalore',
      'Hyderabad',
      'Chennai',
      'Kolkata',
    ],
    'Pakistan': ['Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad'],
    'Japan': ['Tokyo', 'Osaka', 'Kyoto', 'Nagoya', 'Yokohama'],
    'China': ['Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen', 'Chengdu'],
    'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide'],
  };

  List<String> get _countryOptions => _countryCityMap.keys.toList();

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
    _editableBannerLinks = [...widget.currentProfile.bannerLinks];
    _selectedGenres = [...widget.currentProfile.favoriteGenres];
  }

  bool _isValidUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    final normalized =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';

    final uri = Uri.tryParse(normalized);

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<bool> _isReachableUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode != 404;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showErrorDialog(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.container,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _showImageOptions(TextEditingController controller, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Change $title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(controller, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => controller.text = '');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
    TextEditingController controller,
    ImageSource source,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => controller.text = image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _editField({
    required String title,
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
  }) async {
    final temp = TextEditingController(text: controller.text);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
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
                maxLength: 50,
                autofocus: true,
                textInputAction: maxLines == 1
                    ? TextInputAction.done
                    : TextInputAction.newline,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.container,
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
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

    final trimmedValue = temp.text.trim();

    if (title == 'Display name' && trimmedValue.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name cannot be empty.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        controller.text = trimmedValue;
      });
    }
  }

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
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
              if (_countryController.text.trim().isNotEmpty)
                ListTile(
                  onTap: () => Navigator.pop(context, ''),
                  leading: const Icon(Icons.close, color: Colors.redAccent),
                  title: const Text(
                    'Clear location',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
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
        if (result.isEmpty) {
          _countryController.text = '';
          _cityController.text = '';
        } else {
          _countryController.text = result;
          final validCities = _countryCityMap[result] ?? const [];
          if (validCities.isEmpty) {
            _cityController.text = '';
          } else if (!validCities.contains(_cityController.text.trim())) {
            _cityController.text = validCities.first;
          }
        }
      });
    }
  }

  Future<void> _pickCity() async {
    final selectedCountry = _countryController.text.trim();
    final cityOptions = _countryCityMap[selectedCountry] ?? const [];

    if (cityOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No cities available for the selected country.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final searchController = TextEditingController(
      text: _cityController.text.trim(),
    );
    List<String> filteredCities = List<String>.from(cityOptions);

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterCities(String query) {
              final trimmed = query.trim().toLowerCase();
              setModalState(() {
                filteredCities = cityOptions.where((city) {
                  return city.toLowerCase().contains(trimmed);
                }).toList();
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Select city',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: filterCities,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search city',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: AppColors.container,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_cityController.text.trim().isNotEmpty)
                      ListTile(
                        onTap: () => Navigator.pop(context, ''),
                        leading: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                        ),
                        title: const Text(
                          'Clear city',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    SizedBox(
                      height: 420,
                      child: filteredCities.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching cities found.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                final city = filteredCities[index];
                                final isSelected =
                                    _cityController.text.trim() == city;

                                return ListTile(
                                  onTap: () => Navigator.pop(context, city),
                                  title: Text(
                                    city,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (result != null) {
      setState(() {
        _cityController.text = result; // '' clears, non-empty sets
      });
    }
  }

  Future<void> _validateAndPopLink({
    required BuildContext bottomSheetContext,
    required ProfileLinkModel? existing,
    required TextEditingController nameController,
    required TextEditingController linkController,
  }) async {
    final name = nameController.text.trim();
    String link = linkController.text.trim();

    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }

    if (name.isEmpty || !_isValidUrl(link)) {
      await _showErrorDialog(
        'Invalid Link Format',
        'Please enter a valid link.\nIt must start with http:// or https://',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final isReachable = await _isReachableUrl(link);

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (!isReachable) {
      await _showErrorDialog(
        'Link Not Reachable',
        'This link could not be accessed.\nPlease check the URL and try again.',
      );
      return;
    }

    if (!bottomSheetContext.mounted) return;

    Navigator.pop(
      bottomSheetContext,
      ProfileLinkModel(
        linkId: existing?.linkId ?? '',
        title: name,
        link: link,
        platform: name.toLowerCase(),
      ),
    );
  }

  Future<void> _editLink({
    ProfileLinkModel? existing,
    int? index,
    bool isBannerLink = false,
  }) async {
    final nameController = TextEditingController(text: existing?.title ?? '');
    final linkController = TextEditingController(text: existing?.link ?? '');

    final result = await showModalBottomSheet<ProfileLinkModel>(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        final bottom = MediaQuery.of(bottomSheetContext).viewInsets.bottom;

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
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Link name',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.container,
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
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.container,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) async {
                  await _validateAndPopLink(
                    bottomSheetContext: bottomSheetContext,
                    existing: existing,
                    nameController: nameController,
                    linkController: linkController,
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _validateAndPopLink(
                      bottomSheetContext: bottomSheetContext,
                      existing: existing,
                      nameController: nameController,
                      linkController: linkController,
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
      final targetList = isBannerLink ? _editableBannerLinks : _editableLinks;
      if (index != null) {
        targetList[index] = result;
      } else {
        targetList.add(result);
      }
    });
  }

  Future<void> _save() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name cannot be empty.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final country = _countryController.text.trim();
    final city = _cityController.text.trim();

    setState(() => _saving = true);

    try {
      final linksToSave = [
        ..._editableLinks,
        ..._editableBannerLinks,
      ].where((e) => e.link.trim().isNotEmpty).toList();

      const bannerLinksToSave = <ProfileLinkModel>[];

      final updatedTextProfile = widget.currentProfile.copyWith(
        displayName: displayName,
        city: city,
        country: country,
        bio: _bioController.text.trim(),
        links: linksToSave,
        bannerLinks: bannerLinksToSave,
        favoriteGenres: _selectedGenres,
      );

      await _apiService.updateUserProfile(updatedTextProfile, widget.token);

      bool imageChanged = false;
      File? newProfileImg;
      File? newBannerImg;
      bool removeProfileImg = false;
      bool removeBannerImg = false;

      final currentAvatar = widget.currentProfile.profileImgLink;
      final currentBanner = widget.currentProfile.bannerImgLink;
      final newAvatarVal = _avatarController.text.trim();
      final newBannerVal = _bannerController.text.trim();

      if (newAvatarVal != currentAvatar) {
        imageChanged = true;
        if (newAvatarVal.isEmpty) {
          removeProfileImg = true;
        } else if (!newAvatarVal.startsWith('http')) {
          newProfileImg = File(newAvatarVal);
        }
      }

      if (newBannerVal != currentBanner) {
        imageChanged = true;
        if (newBannerVal.isEmpty) {
          removeBannerImg = true;
        } else if (!newBannerVal.startsWith('http')) {
          newBannerImg = File(newBannerVal);
        }
      }

      if (imageChanged) {
        await _apiService.updateProfileImages(
          token: widget.token,
          profileImg: newProfileImg,
          bannerImg: newBannerImg,
          removeProfileImg: removeProfileImg,
          removeBannerImg: removeBannerImg,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

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
      body: Focus(
        autofocus: true,
        child: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            LogicalKeySet(LogicalKeyboardKey.numpadEnter):
                const ActivateIntent(),
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (e) {
                  final focusedContext =
                      FocusManager.instance.primaryFocus?.context;

                  final isTyping = focusedContext?.widget is EditableText;

                  if (!isTyping && !_saving) {
                    _save();
                  }
                  return null;
                },
              ),
            },
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: top),
                  color: Colors.black,
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
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
                          color: AppColors.backgroundVeryDark,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () => _showImageOptions(
                                    _bannerController,
                                    'Banner',
                                  ),
                                  child: Container(
                                    height: 104,
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundDeepest,
                                      image:
                                          _bannerController.text
                                              .trim()
                                              .isNotEmpty
                                          ? DecorationImage(
                                              image:
                                                  _bannerController.text
                                                      .startsWith('http')
                                                  ? NetworkImage(
                                                      _bannerController.text,
                                                    )
                                                  : FileImage(
                                                          File(
                                                            _bannerController
                                                                .text,
                                                          ),
                                                        )
                                                        as ImageProvider,
                                              fit: BoxFit.cover,
                                              onError: (_, _) {},
                                            )
                                          : null,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: _CameraBadge(
                                      onTap: () => _showImageOptions(
                                        _bannerController,
                                        'Banner',
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 18,
                                  bottom: -34,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showImageOptions(
                                          _avatarController,
                                          'Profile Picture',
                                        ),
                                        child: CircleAvatar(
                                          radius: 34,
                                          backgroundColor: const Color(
                                            0xFF1A1A1A,
                                          ),
                                          backgroundImage:
                                              _avatarController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? (_avatarController.text
                                                        .startsWith('http')
                                                    ? NetworkImage(
                                                        _avatarController.text,
                                                      )
                                                    : FileImage(
                                                            File(
                                                              _avatarController
                                                                  .text,
                                                            ),
                                                          )
                                                          as ImageProvider)
                                              : null,
                                          child:
                                              _avatarController.text
                                                  .trim()
                                                  .isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Colors.white38,
                                                  size: 32,
                                                )
                                              : null,
                                        ),
                                      ),
                                      _CameraBadge(
                                        small: true,
                                        onTap: () => _showImageOptions(
                                          _avatarController,
                                          'Profile Picture',
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
                                  ? 'Not set'
                                  : _displayNameController.text,
                              onTap: () => _editField(
                                title: 'Display name',
                                controller: _displayNameController,
                                hint: 'Enter display name',
                              ),
                            ),
                            _EditRow(
                              label: 'City',
                              value: _cityController.text.isEmpty
                                  ? (_countryController.text.trim().isEmpty
                                        ? 'Select your country first'
                                        : 'Select your city')
                                  : _cityController.text,
                              chevron: true,
                              enabled: _countryController.text
                                  .trim()
                                  .isNotEmpty,
                              onTap: _pickCity,
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
                                  isBannerLink: false,
                                ),
                                onDelete: () => setState(() {
                                  _editableLinks.removeAt(entry.key);
                                }),
                              ),
                            ),
                            ..._editableBannerLinks.asMap().entries.map(
                              (entry) => _LinkedProfileRow(
                                label: entry.value.title.trim().isEmpty
                                    ? 'Link'
                                    : entry.value.title,
                                value: entry.value.link,
                                onTap: () => _editLink(
                                  existing: entry.value,
                                  index: entry.key,
                                  isBannerLink: true,
                                ),
                                onDelete: () => setState(() {
                                  _editableBannerLinks.removeAt(entry.key);
                                }),
                              ),
                            ),
                            ListTile(
                              dense: true,
                              onTap: () => _editLink(),
                              leading: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
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
          ),
        ),
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
        color: AppColors.backgroundVeryDark,
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
        style: const TextStyle(color: AppColors.greyMedium),
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
  final bool chevron;
  final VoidCallback onTap;
  final bool enabled;

  const _EditRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.chevron = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder =
        value == 'Not set' ||
        value == 'Where are you based?' ||
        value == 'Select your country' ||
        value == 'Select your country first' ||
        value == 'Select your city' ||
        value == 'Tell the world a bit about yourself';

    final textColor = !enabled
        ? AppColors.greyDark
        : isPlaceholder
        ? AppColors.greyEnabled
        : Colors.white;

    return InkWell(
      onTap: enabled ? onTap : null,
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
                    style: TextStyle(
                      color: enabled
                          ? AppColors.greyMedium
                          : AppColors.greyDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (chevron)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right,
                  color: enabled ? Colors.white54 : AppColors.greyDark,
                ),
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
        width: small ? 28 : 34,
        height: small ? 28 : 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: small ? 16 : 18,
        ),
      ),
    );
  }
}
