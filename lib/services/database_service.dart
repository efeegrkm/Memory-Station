import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getEvents() {
    return _db.collection('events').orderBy('date', descending: true).snapshots();
  }

  // --- YENİ: Tüm Kategorileri Getir (Dinamik Liste İçin) ---
  Future<Set<String>> getAllCategories() async {
    final snapshot = await _db.collection('events').get();
    Set<String> categories = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['category'] != null) {
        categories.add(data['category'] as String);
      }
    }
    return categories;
  }

  // --- FOTOĞRAF İŞLEMLERİ ---

  Future<String> imageToBase64(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  Stream<QuerySnapshot> getCoverImageStream(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('album')
        .orderBy('createdAt')
        .limit(1)
        .snapshots();
  }

  Future<String?> getCoverImage(String eventId) async {
    QuerySnapshot snapshot = await _db
        .collection('events')
        .doc(eventId)
        .collection('album')
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first['data'] as String;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getImagesWithIds(String eventId) async {
    QuerySnapshot snapshot = await _db
        .collection('events')
        .doc(eventId)
        .collection('album')
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'data': doc['data'] as String
    }).toList();
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.collection('events').doc(id).update(data);
  }

  Future<void> addPhotoToAlbum(String eventId, XFile image) async {
    String base64 = await imageToBase64(image);
    await _db.collection('events').doc(eventId).collection('album').add({
      'data': base64,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePhotoFromAlbum(String eventId, String photoId) async {
    await _db.collection('events').doc(eventId).collection('album').doc(photoId).delete();
  }

  Future<void> addEventWithImages(Map<String, dynamic> eventData, List<XFile> images) async {
    DocumentReference docRef = await _db.collection('events').add(eventData);
    for (var image in images) {
      String base64 = await imageToBase64(image);
      await docRef.collection('album').add({
        'data': base64,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteEvent(String id) async {
    var album = await _db.collection('events').doc(id).collection('album').get();
    for (var doc in album.docs) {
      await doc.reference.delete();
    }
    await _db.collection('events').doc(id).delete();
  }

  Future<void> clearDatabase() async {
    var collection = _db.collection('events');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await deleteEvent(doc.id);
    }
  }
}