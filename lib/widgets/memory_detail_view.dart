import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/memory_event.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';

class MemoryDetailView extends StatefulWidget {
  final MemoryEvent event;
  const MemoryDetailView({super.key, required this.event});

  @override
  State<MemoryDetailView> createState() => _MemoryDetailViewState();
}

class _MemoryDetailViewState extends State<MemoryDetailView> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  
  // Resimleri burada saklayacağız
  List<String>? _images;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // Veriyi sadece bir kez çeken fonksiyon
  void _loadImages() async {
    try {
      List<String> images = await _dbService.getImagesForEvent(widget.event.id);
      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Silinsin mi?"),
        content: const Text("Bu anı ve fotoğrafları silinecek."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteEvent(widget.event.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
           Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FOTOĞRAF GALERİSİ (PAGEVIEW) ---
                  SizedBox(
                    height: 350,
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : (_images == null || _images!.isEmpty)
                        ? Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported))
                        : Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: _images!.length,
                              onPageChanged: (index) {
                                // Artık setState yapınca Future tekrar çalışmayacak
                                setState(() => _currentImageIndex = index);
                              },
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: AppTheme.glowShadow,
                                    image: DecorationImage(
                                      image: MemoryImage(base64Decode(_images![index])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Nokta Göstergesi
                            if (_images!.length > 1)
                              Positioned(
                                bottom: 10, left: 0, right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _images!.asMap().entries.map((entry) {
                                    return Container(
                                      width: 8, height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentImageIndex == entry.key ? AppColors.primary : Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                  ),

                  // Bilgiler
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        const SizedBox(height: 8),
                        Row(children: [const Icon(Icons.location_on, size: 16), const SizedBox(width: 8), Text(widget.event.location)]),
                        const SizedBox(height: 20),
                        
                        // Kategori Gösterimi (Ekledim)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.event.category, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        ),
                        
                        const SizedBox(height: 20),
                        const Text("Not:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.event.description, style: const TextStyle(fontSize: 16)),
                        
                        const SizedBox(height: 40),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _deleteEvent,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text("Anıyı Sil", style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}