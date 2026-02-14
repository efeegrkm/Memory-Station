import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getEvents() {
    return _db.collection('events').orderBy('date', descending: true).snapshots();
  }

  // --- KRİTİK DEĞİŞİKLİK: FOTOĞRAFLARI AYRI KAYDETME ---
  
  // 1. Önce Anı Bilgisini Kaydet, Sonra Fotoğrafları Altına Ekle
  Future<void> addEventWithImages(Map<String, dynamic> eventData, List<XFile> images) async {
    // 1. Ana dökümanı oluştur (Henüz foto yok)
    DocumentReference docRef = await _db.collection('events').add(eventData);

    // 2. Fotoğrafları bu dökümanın "album" adlı alt koleksiyonuna tek tek ekle
    for (var image in images) {
      String base64 = await imageToBase64(image);
      // Her fotoğraf ayrı bir döküman oluyor (1 MB sınırı artık fotoğraf başına geçerli!)
      await docRef.collection('album').add({
        'data': base64,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Belirli bir anının fotoğraflarını çekmek için
  Future<List<String>> getImagesForEvent(String eventId) async {
    QuerySnapshot snapshot = await _db
        .collection('events')
        .doc(eventId)
        .collection('album')
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) => doc['data'] as String).toList();
  }
  
  // İlk fotoğrafı (Kapak için) çekmek istersek hızlı bir metod
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

  // Anıyı ve altındaki fotoları silme
  Future<void> deleteEvent(String id) async {
    // Önce alt koleksiyondaki fotoları silmemiz lazım (Firestore otomatik silmez)
    var album = await _db.collection('events').doc(id).collection('album').get();
    for (var doc in album.docs) {
      await doc.reference.delete();
    }
    // Sonra ana anıyı sil
    await _db.collection('events').doc(id).delete();
  }

  Future<void> clearDatabase() async {
    var collection = _db.collection('events');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await deleteEvent(doc.id); // Yukarıdaki güvenli silme metodunu kullanır
    }
  }

  Future<String> imageToBase64(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }
}