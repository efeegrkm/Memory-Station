import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/memory_event.dart';
import '../services/database_service.dart';

class MemoryCard extends StatelessWidget {
  final MemoryEvent event;
  final double scale; // YENİ: Dışarıdan gelen zoom oranı

  // Scale varsayılan olarak 1.0 (tam boyut)
  const MemoryCard({super.key, required this.event, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    // Zoom seviyesine göre boyutları hesapla
    // En küçük 0.5 oranına kadar düşsün, yoksa çok silik olur
    final double effectiveScale = scale.clamp(0.5, 1.0); 
    
    final double imageHeight = 160 * effectiveScale;
    final double titleSize = 18 * effectiveScale;
    final double dateSize = 12 * effectiveScale;
    final double iconSize = 14 * effectiveScale;
    final double contentPadding = 16 * effectiveScale;
    final double borderRadius = 24 * effectiveScale;

    return Container(
      // Margin'i de küçültelim ki kartlar birbirine yaklaşsın
      margin: EdgeInsets.symmetric(vertical: 16 * effectiveScale, horizontal: 8 * effectiveScale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppTheme.glowShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
                child: FutureBuilder<String?>(
                  future: dbService.getCoverImage(event.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: imageHeight,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: SizedBox(
                            width: 30 * effectiveScale, 
                            height: 30 * effectiveScale, 
                            child: CircularProgressIndicator(strokeWidth: 2 * effectiveScale, color: AppColors.primary)
                          )
                        ),
                      );
                    }
                    
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      String imageString = snapshot.data!;
                      bool isBase64 = !imageString.startsWith('http');
                      
                      return isBase64
                          ? Image.memory(
                              base64Decode(imageString),
                              height: imageHeight, // Dinamik yükseklik
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              imageString,
                              height: imageHeight, // Dinamik yükseklik
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                    }
                    
                    return Container(
                      height: imageHeight,
                      width: double.infinity,
                      color: AppColors.accent,
                      child: Center(
                        child: Icon(Icons.image, color: Colors.white, size: 40 * effectiveScale)
                      ),
                    );
                  },
                ),
              ),
              
              // Kategori Etiketi
              Positioned(
                top: 12 * effectiveScale, right: 12 * effectiveScale,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * effectiveScale, vertical: 4 * effectiveScale),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12 * effectiveScale),
                  ),
                  child: Text(
                    event.category,
                    style: TextStyle(
                      fontSize: 10 * effectiveScale, // Fontu da küçült
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textMain
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: EdgeInsets.all(contentPadding), // İç boşluk küçülüyor
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * effectiveScale, vertical: 4 * effectiveScale),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8 * effectiveScale),
                      ),
                      child: Text(
                        DateFormat('d MMMM yyyy', 'tr').format(event.date),
                        style: TextStyle(
                          fontSize: dateSize, 
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * effectiveScale),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 4 * effectiveScale),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: iconSize, color: AppColors.textLight),
                    SizedBox(width: 4 * effectiveScale),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(fontSize: dateSize, color: AppColors.textLight),
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