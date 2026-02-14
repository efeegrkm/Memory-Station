import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryEvent {
  final String id;
  final String title;
  final String location;
  final String description;
  final DateTime date;
  final String category;
  final String type;
  // --- YENİ ALANLAR ---
  final double? latitude;
  final double? longitude;

  MemoryEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.date,
    required this.category,
    required this.type,
    this.latitude,
    this.longitude,
  });

  factory MemoryEvent.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MemoryEvent(
      id: doc.id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? 'Diğer',
      type: data['type'] ?? 'memory',
      // Veritabanında varsa al, yoksa null
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'description': description,
      'date': Timestamp.fromDate(date),
      'category': category,
      'type': type,
      // Harita verilerini kaydet
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}