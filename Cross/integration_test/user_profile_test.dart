import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cross_team5/main.dart' as app;

import 'helpers/auth_helpers.dart';
import 'helpers/nav_helpers.dart';

void main() {
  group('Navigation', () {
    testWidgets('Home screen -> Library screen -> User Profile screen', (tester) async {
      app.main();
      // Wait for splash to redirect to Home screen
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Home screen -> Library screen
      final libraryNavButton = find.byKey(const Key('test_home_to_library_nav'));
      expect(libraryNavButton, findsOneWidget);

      await tester.tap(libraryNavButton);
      await tester.pumpAndSettle();

      NavHelpers.assertOnLibraryScreen();

      // Library screen -> User Profile screen
      final profileButton = find.byKey(const Key('test_library_to_profile_btn'));
      expect(profileButton, findsOneWidget);

      await tester.tap(profileButton);
      await tester.pumpAndSettle();

      NavHelpers.assertOnUserProfileScreen();
    });

    testWidgets('User Profile screen -> Edit Profile screen', (tester) async {
      app.main();
      // Already tested {
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
        await tester.pumpAndSettle();
      // }

      // Tap edit button
      final editBtn = find.byKey(const Key('test_profile_edit_btn'));
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      NavHelpers.assertOnEditProfileScreen();
    });

    testWidgets('Edit Profile screen (cancel) -> User Profile screen', (tester) async {
      app.main();
      // Already tested {
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
        await tester.pumpAndSettle();
      // }

      // Tap cancel button
      final cancelBtn = find.byKey(const Key('test_edit_profile_cancel_btn'));
      expect(cancelBtn, findsOneWidget);

      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      NavHelpers.assertOnUserProfileScreen();
    });

    testWidgets('Edit Profile screen (save) -> User Profile screen', (tester) async {
      app.main();
      // Already tested {
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
        await tester.pumpAndSettle();
      // }

      // Tap save button
      final saveBtn = find.byKey(const Key('test_edit_profile_save_btn'));
      expect(saveBtn, findsOneWidget);

      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      NavHelpers.assertOnUserProfileScreen();
    });
  });

  group('User Profile', () {
    testWidgets('Tapping three dots opens share sheet', (tester) async {
      app.main();
      // Already tested {
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
        await tester.pumpAndSettle();
      // }

      // Tap three dots
      final moreBtn = find.byKey(const Key('test_profile_more_btn'));
      expect(moreBtn, findsOneWidget);

      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('test_profile_share_sheet')), findsOneWidget);
    });

    testWidgets('Copy link copies to clipboard', (tester) async {
      app.main();
      // Already tested {
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_profile_more_btn')));
        await tester.pumpAndSettle();
      // }

      // Tap Copy link
      final copyLink = find.descendant(
        of: find.byKey(const Key('test_profile_share_sheet')),
        matching: find.text('Copy link'),
      );
      expect(copyLink, findsOneWidget);
      
      await tester.tap(copyLink);
      await tester.pumpAndSettle();

      final clipboardData = await Clipboard.getData('text/plain');
      expect(clipboardData?.text, isNotNull);
      expect(clipboardData?.text, isNotEmpty);

      // Assert sheet is closed
      expect(find.byKey(const Key('test_profile_share_sheet')), findsNothing);
    });

    testWidgets('Tapping linked profile does not crash', (tester) async {
      app.main();
      // Already tested {
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_profile_more_btn')));
        await tester.pumpAndSettle();
      // }

      // Tap linked profile
      final linkedProfile = find.descendant(
        of: find.byKey(const Key('test_profile_share_sheet')),
        matching: find.byType(ListTile),
      );

      if (linkedProfile.evaluate().isNotEmpty) {
        await tester.tap(linkedProfile.first);
        await tester.pumpAndSettle();
      }

      // Assert sheet is closed
      expect(find.byKey(const Key('test_profile_share_sheet')), findsNothing);
    });

    testWidgets('Saving profile reflects updated banner URL on profile screen', (tester) async {
      app.main();

      // Navigate to Edit Profile
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
      await tester.pumpAndSettle();

      const testUrl = 'https://images.unsplash.com/photo-1603647045834-a31d35679a2b?fm=jpg&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDExfHx8ZW58MHx8fHx8&ixlib=rb-4.1.0&q=60&w=3000';

      // Open Banner Bottom Sheet
      final bannerBtn = find.byKey(const Key('test_edit_banner_btn'));
      expect(bannerBtn, findsOneWidget);
      await tester.tap(bannerBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is opened
      expect(find.byKey(const Key('test_edit_field_sheet')), findsOneWidget);

      // Banner URL input
      final input = find.byKey(const Key('test_edit_field_input'));
      expect(input, findsOneWidget);

      // Done button 
      final doneBtn = find.byKey(const Key('test_edit_field_done_btn'));
      expect(doneBtn, findsOneWidget);

      // Invalid URL
      await tester.enterText(input, 'not-a-url');
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_field_sheet')), findsOneWidget);

      // Valid URL
      await tester.enterText(input, testUrl);
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is closed
      expect(find.byKey(const Key('test_edit_field_sheet')), findsNothing);

      // Assert banner URL is reflected in the edit screen banner container
      final bannerContainer = tester.widget<Container>(
        find.byKey(const Key('test_edit_banner_image')),
      );
      final decoration = bannerContainer.decoration as BoxDecoration;
      final image = decoration.image?.image as NetworkImage;
      expect(image.url, equals(testUrl));

      // Save Profile
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Assert banner image is present with correct URL on profile screen
      final bannerFinder = find.byKey(const Key('test_profile_banner_image'));
      expect(bannerFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(bannerFinder);
      expect((imageWidget.image as NetworkImage).url, equals(testUrl));
    });

    testWidgets('Saving profile reflects updated avatar URL on profile screen', (tester) async {
      app.main();

      // Navigate to Edit Profile
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
      await tester.pumpAndSettle();

      const testUrl = 'https://images.unsplash.com/photo-1603647045834-a31d35679a2b?fm=jpg&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDExfHx8ZW58MHx8fHx8&ixlib=rb-4.1.0&q=60&w=3000';

      // Open avatar bottom sheet
      final avatarBtn = find.byKey(const Key('test_edit_avatar_btn'));
      expect(avatarBtn, findsOneWidget);
      await tester.tap(avatarBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is opened
      expect(find.byKey(const Key('test_edit_field_sheet')), findsOneWidget);

      // Avatar URL input
      final input = find.byKey(const Key('test_edit_field_input'));
      expect(input, findsOneWidget);

      // Done button
      final doneBtn = find.byKey(const Key('test_edit_field_done_btn'));
      expect(doneBtn, findsOneWidget);

      // Invalid URL
      await tester.enterText(input, 'not-a-url');
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_field_sheet')), findsOneWidget);

      // Valid URL
      await tester.enterText(input, testUrl);
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is closed
      expect(find.byKey(const Key('test_edit_field_sheet')), findsNothing);

      // Assert avatar URL is reflected in the edit screen avatar container
      final avatarWidget = tester.widget<CircleAvatar>(
        find.byKey(const Key('test_edit_avatar_image')),
      );
      expect((avatarWidget.backgroundImage as NetworkImage).url, equals(testUrl));

      // Save profile
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Assert avatar on profile screen reflects the new URL
      final avatarFinder = find.byKey(const Key('test_profile_avatar_image'));
      expect(avatarFinder, findsOneWidget);
      final savedAvatarWidget = tester.widget<CircleAvatar>(avatarFinder);
      expect((savedAvatarWidget.backgroundImage as NetworkImage).url, equals(testUrl));
    });

    testWidgets('Saving profile reflects updated display name on profile screen', (tester) async {
      app.main();

      // Navigate to Edit Profile
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
      await tester.pumpAndSettle();

      const testName = 'Johnny';

      // Tap the Display name row
      final displayNameRow = find.byKey(const Key('test_edit_displayname_row'));
      expect(displayNameRow, findsOneWidget);

      await tester.tap(displayNameRow);
      await tester.pumpAndSettle();

      // Assert bottom sheet is opened
      expect(find.byKey(const Key('test_edit_field_sheet')), findsOneWidget);

      // Name input
      final input = find.byKey(const Key('test_edit_field_input'));
      expect(input, findsOneWidget);

      // Done button
      final doneBtn = find.byKey(const Key('test_edit_field_done_btn'));
      expect(doneBtn, findsOneWidget);

      // Empty name
      await tester.enterText(input, '');
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_field_sheet')), findsOneWidget);

      // Valid name
      await tester.enterText(input, testName);
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is closed
      expect(find.byKey(const Key('test_edit_field_sheet')), findsNothing);

      // Assert new display name is reflected in the edit form before saving
      final displayNameText = tester.widget<Text>(
        find.byKey(const Key('test_edit_displayname_value')),
      );
      expect(displayNameText.data, equals(testName));

      // Tap Save
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Assert display name is updated on profile screen
      final displayNameWidget = tester.widget<Text>(find.byKey(const Key('test_profile_display_name')));
      expect(displayNameWidget.data, equals(testName));
    });

    testWidgets('Saving profile reflects updated city on profile screen', (tester) async {
      app.main();

      // Navigate to Edit Profile
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
      await tester.pumpAndSettle();

      const testCity = 'Berlin';

      // Tap the City row
      final cityRow = find.byKey(const Key('test_edit_city_row'));
      expect(cityRow, findsOneWidget);

      await tester.tap(cityRow);
      await tester.pumpAndSettle();

      // Assert bottom sheet is opened
      expect(find.byKey(const Key('test_edit_field_sheet')), findsOneWidget);

      // Type the new city into the text field
      final input = find.byKey(const Key('test_edit_field_input'));
      expect(input, findsOneWidget);

      await tester.enterText(input, testCity);
      await tester.pumpAndSettle();

      // Tap Done
      final doneBtn = find.byKey(const Key('test_edit_field_done_btn'));
      expect(doneBtn, findsOneWidget);

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is closed
      expect(find.byKey(const Key('test_edit_field_sheet')), findsNothing);

      // Assert new city is reflected in the edit form before saving
      final cityText = tester.widget<Text>(
        find.byKey(const Key('test_edit_city_value')),
      );
      expect(cityText.data, equals(testCity));

      // Tap Save
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Assert city appears in the location text on profile screen
      final locationWidget = tester.widget<Text>(find.byKey(const Key('test_profile_location')));
      expect(locationWidget.data, contains(testCity));
    });

    testWidgets('Saving profile reflects updated country on profile screen', (tester) async {
      app.main();

      // Navigate to Edit Profile
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
      await tester.pumpAndSettle();

      const testCountry = 'Egypt';

      // Tap the Country row
      final countryRow = find.byKey(const Key('test_edit_country_row'));
      expect(countryRow, findsOneWidget);

      await tester.tap(countryRow);
      await tester.pumpAndSettle();

      // Assert country sheet is opened
      expect(find.byKey(const Key('test_edit_country_sheet')), findsOneWidget);

      // Choose the new country
      final countryOption = find.text(testCountry);
      expect(countryOption, findsOneWidget);

      // Tap the new country
      await tester.tap(countryOption);
      await tester.pumpAndSettle();

      // Assert country sheet is closed
      expect(find.byKey(const Key('test_edit_country_sheet')), findsNothing);

      // Assert new country is reflected in the edit form before saving
      final countryText = tester.widget<Text>(
        find.byKey(const Key('test_edit_country_value')),
      );
      expect(countryText.data, equals(testCountry));

      // Tap Save
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Assert country appears in the location text on profile screen
      final locationWidget = tester.widget<Text>(find.byKey(const Key('test_profile_location')));
      expect(locationWidget.data, contains(testCountry));
    });

    testWidgets('Saving profile reflects updated bio on profile screen', (tester) async {
      app.main();

      // Navigate to Edit Profile
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
      await tester.pumpAndSettle();

      const testBio = 'This is my test bio.';

      // Tap the Bio row
      final bioRow = find.byKey(const Key('test_edit_bio_row'));
      expect(bioRow, findsOneWidget);

      await tester.tap(bioRow);
      await tester.pumpAndSettle();

      // Assert bottom sheet is opened
      expect(find.byKey(const Key('test_edit_field_sheet')), findsOneWidget);

      // Type the new bio into the text field
      final input = find.byKey(const Key('test_edit_field_input'));
      expect(input, findsOneWidget);

      await tester.enterText(input, testBio);
      await tester.pumpAndSettle();

      // Tap Done
      final doneBtn = find.byKey(const Key('test_edit_field_done_btn'));
      expect(doneBtn, findsOneWidget);

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is closed
      expect(find.byKey(const Key('test_edit_field_sheet')), findsNothing);

      // Assert new bio is reflected in the edit form before saving
      final bioText = tester.widget<Text>(
        find.byKey(const Key('test_edit_bio_value')),
      );
      expect(bioText.data, equals(testBio));

      // Tap Save
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Assert bio text is visible on profile screen
      final bioWidget = tester.widget<Text>(find.byKey(const Key('test_profile_bio')));
      expect(bioWidget.data, equals(testBio));
    });

    testWidgets('Adding a link reflects the new link in the list and on the profile share sheet', (tester) async {
      app.main();

      // Navigate to Edit Profile
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
      await tester.pumpAndSettle();

      const testName = 'gitlens';
      const testUrl = 'https://gitlens.com/test';

      // Tap the Add Link button
      final addLinkBtn = find.byKey(const Key('test_edit_add_link_btn'));
      expect(addLinkBtn, findsOneWidget);

      await tester.tap(addLinkBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is opened
      expect(find.byKey(const Key('test_edit_link_sheet')), findsOneWidget);

      // Link name input
      final nameInput = find.byKey(const Key('test_edit_link_name_input'));
      expect(nameInput, findsOneWidget);

      // Link URL input
      final urlInput = find.byKey(const Key('test_edit_link_url_input'));
      expect(urlInput, findsOneWidget);

      // Done button
      final doneBtn = find.byKey(const Key('test_edit_link_done_btn'));
      expect(doneBtn, findsOneWidget);

      // Empty name
      await tester.enterText(nameInput, '');
      await tester.enterText(urlInput, testUrl);
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_link_sheet')), findsOneWidget);

      // Empty URL
      await tester.enterText(nameInput, testName);
      await tester.enterText(urlInput, '');
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_link_sheet')), findsOneWidget);
      
      // Invalid URL
      await tester.enterText(nameInput, testName);
      await tester.enterText(urlInput, 'not-a-url');
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_link_sheet')), findsOneWidget);

      // Valid name and URL
      await tester.enterText(nameInput, testName);
      await tester.enterText(urlInput, testUrl);
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is closed
      expect(find.byKey(const Key('test_edit_link_sheet')), findsNothing);

      // Assert new link label is visible in the edit form
      final labelText = tester.widget<Text>(
        find.byKey(const Key('test_edit_link_label_0')),
      );
      expect(labelText.data, equals(testName));

      // Assert new link URL is visible in the edit form
      final valueText = tester.widget<Text>(
        find.byKey(const Key('test_edit_link_value_0')),
      );
      expect(valueText.data, equals(testUrl));

      // Tap Save
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Tap three dots to open share sheet
      final moreBtn = find.byKey(const Key('test_profile_more_btn'));
      expect(moreBtn, findsOneWidget);

      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Assert share sheet is opened
      expect(find.byKey(const Key('test_profile_share_sheet')), findsOneWidget);

      // Assert new link is visible in the share sheet
      expect(find.text(testName), findsOneWidget);
      expect(find.text(testUrl), findsOneWidget);
    });

    testWidgets('Editing a link reflects the updated link in the list and on the profile share sheet', (tester) async {
      app.main();
      // Already tested {
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
        await tester.pumpAndSettle();
      // }

      const updatedName = 'SoundCloud';
      const updatedUrl = 'https://soundcloud.com/test';

      // Tap the first existing link row
      final linkRow = find.byKey(const Key('test_edit_link_row_0'));
      expect(linkRow, findsOneWidget);

      await tester.tap(linkRow);
      await tester.pumpAndSettle();

      // Assert bottom sheet is opened
      expect(find.byKey(const Key('test_edit_link_sheet')), findsOneWidget);

      // Link name input
      final nameInput = find.byKey(const Key('test_edit_link_name_input'));
      expect(nameInput, findsOneWidget);

      // Link URL input
      final urlInput = find.byKey(const Key('test_edit_link_url_input'));
      expect(urlInput, findsOneWidget);

      // Done button
      final doneBtn = find.byKey(const Key('test_edit_link_done_btn'));
      expect(doneBtn, findsOneWidget);
      
      // Empty name
      await tester.enterText(nameInput, '');
      await tester.enterText(urlInput, updatedUrl);
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_link_sheet')), findsOneWidget);
      
      // Empty URL
      await tester.enterText(nameInput, updatedName);
      await tester.enterText(urlInput, '');
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_link_sheet')), findsOneWidget);
      
      // Invalid URL
      await tester.enterText(nameInput, updatedName);
      await tester.enterText(urlInput, 'not-a-url');
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is still open
      expect(find.byKey(const Key('test_edit_link_sheet')), findsOneWidget);

      // Valid name and URL
      await tester.enterText(nameInput, updatedName);
      await tester.enterText(urlInput, updatedUrl);
      await tester.pumpAndSettle();

      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Assert bottom sheet is closed
      expect(find.byKey(const Key('test_edit_link_sheet')), findsNothing);

      // Assert updated link label is visible
      final labelText = tester.widget<Text>(
        find.byKey(const Key('test_edit_link_label_0')),
      );
      expect(labelText.data, equals(updatedName));

      // Assert updated link URL is visible
      final valueText = tester.widget<Text>(
        find.byKey(const Key('test_edit_link_value_0')),
      );
      expect(valueText.data, equals(updatedUrl));

      // Tap Save
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Tap three dots to open share sheet
      final moreBtn = find.byKey(const Key('test_profile_more_btn'));
      expect(moreBtn, findsOneWidget);

      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Assert share sheet is opened
      expect(find.byKey(const Key('test_profile_share_sheet')), findsOneWidget);

      // Assert new link is visible in the share sheet
      expect(find.text(updatedName), findsOneWidget);
      expect(find.text(updatedUrl), findsOneWidget);
    });

    testWidgets('Deleting a link removes it from the list', (tester) async {
      app.main();

      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('test_home_to_library_nav')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_library_to_profile_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test_profile_edit_btn')));
      await tester.pumpAndSettle();

      // Assert the row exists before deleting
      expect(find.byKey(const Key('test_edit_link_row_0')), findsOneWidget);

      final labelText = tester.widget<Text>(
        find.byKey(const Key('test_edit_link_label_0')),
      );
      final valueText = tester.widget<Text>(
        find.byKey(const Key('test_edit_link_value_0')),
      );

      final existingName = labelText.data!;
      final existingUrl = valueText.data!;

      // Delete
      final deleteBtn = find.byKey(const Key('test_edit_link_delete_btn_0'));
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Assert the row is gone
      expect(find.byKey(const Key('test_edit_link_row_0')), findsNothing);

      // Tap Save
      await tester.tap(find.byKey(const Key('test_edit_profile_save_btn')));
      await tester.pumpAndSettle();

      // Tap three dots to open share sheet
      final moreBtn = find.byKey(const Key('test_profile_more_btn'));
      expect(moreBtn, findsOneWidget);

      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Assert share sheet opened
      expect(find.byKey(const Key('test_profile_share_sheet')), findsOneWidget);

      // Assert link is gone from share sheet
      expect(find.text(existingName), findsNothing);
      expect(find.text(existingUrl), findsNothing);
    });
  });
}