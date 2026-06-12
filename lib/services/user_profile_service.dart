import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UserProfile {
  final String displayName;
  final String city;
  final String title;
  final String? photoUrl;

  const UserProfile({
    required this.displayName,
    required this.city,
    required this.title,
    this.photoUrl,
  });
}

class UserProfileService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

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
      photoUrl: data['photoUrl']?.toString() ?? user?.photoURL,
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

  /// Upload foto profil dari kamera atau galeri.
  /// Mengembalikan URL foto yang sudah tersimpan.
  Future<String?> uploadPhoto(ImageSource source) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return null;

    final ref = _storage.ref('users/${user.uid}/profile.jpg');
    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    await user.updatePhotoURL(url);
    await _db.collection('users').doc(user.uid).set(
      {'photoUrl': url},
      SetOptions(merge: true),
    );
    return url;
  }
}
