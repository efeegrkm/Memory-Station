import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/memory_event.dart';
import '../services/database_service.dart'; // Database servisini eklemeyi unutma

class MemoryCard extends StatelessWidget {
  final MemoryEvent event;

  const MemoryCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Servisi başlatıyoruz
    final DatabaseService dbService = DatabaseService();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.glowShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
                // event.images yerine FutureBuilder kullanıyoruz
                child: FutureBuilder<String?>(
                  future: dbService.getCoverImage(event.id), // Kapak fotosunu çek
                  builder: (context, snapshot) {
                    // 1. Yükleniyor durumu
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 30, 
                            height: 30, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                          )
                        ),
                      );
                    }
                    
                    // 2. Resim geldi mi?
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      String imageString = snapshot.data!;
                      bool isBase64 = !imageString.startsWith('http');
                      
                      return isBase64
                          ? Image.memory(
                              base64Decode(imageString),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              imageString,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                    }
                    
                    // 3. Resim yoksa veya hata varsa varsayılan göster
                    return Container(
                      height: 160,
                      width: double.infinity,
                      color: AppColors.accent,
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.white, size: 40)
                      ),
                    );
                  },
                ),
                // --- DEĞİŞİKLİK BURADA BİTİYOR ---
              ),
              
              // Kategori Etiketi
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.category,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('d MMMM yyyy', 'tr').format(event.date),
                        style: const TextStyle(
                          fontSize: 12, 
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}