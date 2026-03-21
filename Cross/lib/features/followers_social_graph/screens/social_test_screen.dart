// social_test_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// TEMPORARY SCREEN — for standalone testing of Module 3 only.
// Remove or comment out before final integration with the full app.
//
// PURPOSE:
//   This screen acts as a hub that lets you navigate to every screen in
//   this module independently, without needing any other module to be ready.
//   It also lets you test follow/unfollow/block/unblock with a hardcoded
//   test userId so you don't depend on an auth or profile module.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import 'followers_screen.dart';
import 'following_screen.dart';
import 'blocked_users_screen.dart';


class SocialTestScreen extends StatelessWidget 
{
  // ── Replace this with any real userId from your database for testing ──
  static const String testUserId = 'replace-with-real-user-id';

  const SocialTestScreen({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
    (
      appBar: AppBar
      (
        title: const Text('Module 3 — Social Test Hub'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: Padding
      (
        padding: const EdgeInsets.all(24),
        child: Column
        (
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: 
          [
            // ── Info banner ────────────────────────────────────────────────
            Container
            (
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration
              (
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text
              (
                'TEMP TESTING SCREEN\n'
                'Replace testUserId at the top of this file with a real '
                'userId from your database before testing.',
                style: TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 32),

            // ── Label ──────────────────────────────────────────────────────
            const Text
            (
              'Navigate to:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // ── Followers screen ───────────────────────────────────────────
            _NavButton
            (
              label: 'Followers',
              subtitle: 'GET /api/social/followers/{userId}',
              icon: Icons.group,
              color: Colors.blue,
              onTap: () => Navigator.push
              (
                context,
                MaterialPageRoute
                (
                  builder: (_) => const FollowersScreen(userId: testUserId),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Following screen ───────────────────────────────────────────
            _NavButton
            (
              label: 'Following',
              subtitle: 'GET /api/social/following/{userId}',
              icon: Icons.person_add,
              color: Colors.green,
              onTap: () => Navigator.push
              (
                context,
                MaterialPageRoute
                (
                  builder: (_) => const FollowingScreen(userId: testUserId),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Blocked users screen ───────────────────────────────────────
            _NavButton
            (
              label: 'Blocked Users',
              subtitle: 'GET /api/social/blocked',
              icon: Icons.block,
              color: Colors.red,
              onTap: () => Navigator.push
              (
                context,
                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
              ),
            ),

            const SizedBox(height: 32),

            // ── Testing tip ────────────────────────────────────────────────
            const Text
            (
              'How to test follow/unfollow/block/unblock:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _TipCard
            (
              step: '1',
              text: 'Open Followers or Following screen — user tiles will load from the API.',
            ),
            _TipCard
            (
              step: '2',
              text: 'Tap the Follow / Following button on any tile to test follow & unfollow.',
            ),
            _TipCard
            (
              step: '3',
              text: 'Tap the ⋮ menu on any tile → Block user to test blocking.',
            ),
            _TipCard
            (
              step: '4',
              text: 'Open Blocked Users screen → tap Unblock on any tile to test unblocking.',
            ),
            _TipCard
            (
              step: '5',
              text: 'Check Postman or your backend logs to confirm each API call went through correctly.',
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS — only used inside this test screen
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget 
{
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) 
  {
    return Material
    (
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell
      (
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding
        (
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row
          (
            children: 
            [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Expanded
              (
                child: Column
                (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: 
                  [
                    Text
                    (
                      label,
                      style: TextStyle
                      (
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text
                    (
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}


class _TipCard extends StatelessWidget 
{
  final String step;
  final String text;

  const _TipCard({required this.step, required this.text});

  @override
  Widget build(BuildContext context) 
  {
    return Padding
    (
      padding: const EdgeInsets.only(bottom: 8),
      child: Row
      (
        crossAxisAlignment: CrossAxisAlignment.start,
        children: 
        [
          CircleAvatar
          (
            radius: 12,
            backgroundColor: Colors.orange,
            child: Text
            (
              step,
              style: const TextStyle
              (
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded
          (
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}