import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb için
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
  final DatabaseService _dbService = DatabaseService();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late String _selectedCategory;

  final List<String> _categories = ['Sinema', 'Piknik', 'Tiyatro', 'Gezi', 'Yürüyüş', 'Kutlama', 'Yemek', 'Diğer'];

  List<Map<String, dynamic>> _images = [];
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _locationController = TextEditingController(text: widget.event.location);
    _descController = TextEditingController(text: widget.event.description);
    _selectedDate = widget.event.date;
    _selectedCategory = widget.event.category;
    
    _loadImages();
  }

  void _loadImages() async {
    try {
      var images = await _dbService.getImagesWithIds(widget.event.id);
      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 60,
    );

    if (image != null) {
      setState(() => _isSaving = true);
      await _dbService.addPhotoToAlbum(widget.event.id, image);
      _loadImages();
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePhoto(String photoId) async {
    setState(() => _isSaving = true);
    await _dbService.deletePhotoFromAlbum(widget.event.id, photoId);
    _loadImages();
    setState(() => _isSaving = false);
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // TASK 1: Tarih değişikliği burada veritabanına gönderiliyor.
      // Firestore, 'date' alanı değiştiğinde timeline sorgusunu otomatik günceller.
      await _dbService.updateEvent(widget.event.id, {
        'title': _titleController.text,
        'location': _locationController.text,
        'description': _descController.text,
        'date': _selectedDate, 
        'category': _selectedCategory,
      });
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Değişiklikler kaydedildi!")),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  void _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Silinsin mi?"),
        content: const Text("Bu anı ve fotoğrafları kalıcı olarak silinecek."),
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

  void _toggleEdit() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() => _isEditing = true);
    }
  }

  // Tarih seçici yardımcı fonksiyonu
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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
                  // --- GALERİ ALANI ---
                  SizedBox(
                    height: 350,
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          children: [
                            if (_images.isEmpty)
                              Container(
                                color: Colors.grey[200],
                                child: const Center(child: Text("Fotoğraf Yok")),
                              )
                            else
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _images.length,
                                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                                itemBuilder: (context, index) {
                                  final imgData = _images[index];
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: AppTheme.glowShadow,
                                          image: DecorationImage(
                                            image: MemoryImage(base64Decode(imgData['data'])),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (_isEditing)
                                        Positioned(
                                          top: 10, right: 20,
                                          child: GestureDetector(
                                            onTap: () => _deletePhoto(imgData['id']),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                              child: const Icon(Icons.delete, color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            
                            if (_isEditing)
                              Positioned(
                                bottom: 20, right: 20,
                                child: FloatingActionButton(
                                  mini: true,
                                  onPressed: _addNewPhoto,
                                  backgroundColor: AppColors.primary,
                                  child: const Icon(Icons.add_a_photo, color: Colors.white),
                                ),
                              ),
                            
                            if (!_isEditing && _images.length > 1)
                              Positioned(
                                bottom: 10, left: 0, right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _images.asMap().entries.map((entry) {
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

                  // --- BİLGİLER ALANI ---
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık ve Düzenle/Kaydet Butonu
                        Row(
                          children: [
                            Expanded(
                              child: _isEditing
                                ? TextFormField(
                                    controller: _titleController,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain),
                                    decoration: const InputDecoration(hintText: "Başlık"),
                                  )
                                : Text(
                                    _titleController.text,
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain),
                                  ),
                            ),
                            IconButton(
                              onPressed: _toggleEdit,
                              icon: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(_isEditing ? Icons.save : Icons.edit, color: AppColors.primary),
                            )
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Tarih ve Kategori
                        Row(
                          children: [
                            // TASK 1: Tarih Düzenleme Butonu
                            InkWell(
                              onTap: _isEditing ? _pickDate : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: _isEditing 
                                  ? BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(8))
                                  : null,
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: _isEditing ? AppColors.primary : Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('d MMMM yyyy', 'tr').format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 16, 
                                        color: _isEditing ? AppColors.primary : Colors.grey,
                                        fontWeight: _isEditing ? FontWeight.bold : FontWeight.normal
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const Spacer(),
                            
                            _isEditing
                              ? DropdownButton<String>(
                                  value: _categories.contains(_selectedCategory) ? _selectedCategory : 'Diğer',
                                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                  onChanged: (val) => setState(() => _selectedCategory = val!),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                                  child: Text(_selectedCategory, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
                                ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            _isEditing
                              ? Expanded(child: TextFormField(controller: _locationController))
                              : Expanded(child: Text(_locationController.text, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        const Text("Not:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _isEditing
                          ? TextFormField(controller: _descController, maxLines: 4)
                          : Text(_descController.text, style: const TextStyle(fontSize: 16, height: 1.5)),
                        
                        const SizedBox(height: 40),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _deleteEvent,
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text("Anıyı Sil", style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _toggleEdit,
                                icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
                                label: Text(
                                  _isEditing ? "Kaydet" : "Düzenle",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
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