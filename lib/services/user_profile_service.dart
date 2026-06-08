import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String displayName;
  final String city;
  final String title;

  const UserProfile({
    required this.displayName,
    required this.city,
    required this.title,
  });
}

class UserProfileService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<UserProfile> fetchProfile() async {
    final user = _auth.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email?.split('@').first ?? 'Pengguna';

    if (_uid == null) {
      return UserProfile(displayName: displayName, city: '', title: 'Urban Farmer');
    }

    final doc = await _db.collection('users').doc(_uid).get();
    final data = doc.data() ?? {};
    return UserProfile(
      displayName: displayName,
      city: data['city']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Urban Farmer',
    );
  }

  Future<void> updateProfile({
    required String displayName,
    required String city,
    required String title,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(displayName.trim());
    await _db.collection('users').doc(user.uid).set({
      'city': city.trim(),
      'title': title.trim(),
    }, SetOptions(merge: true));
  }
}
