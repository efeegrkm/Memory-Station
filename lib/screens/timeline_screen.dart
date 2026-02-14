import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/memory_event.dart';
import '../widgets/memory_card.dart';
import '../widgets/memory_detail_view.dart';
import '../services/database_service.dart';
import 'add_event_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  // --- FİLTRELEME DURUMLARI ---
  bool _isFilterEnabled = false; // Toggle
  List<String> _selectedFilters = []; 
  DateTimeRange? _selectedDateRange;
  
  // Veritabanından gelen kategorileri burada tutacağız (Dinamik Liste)
  Set<String> _dynamicCategories = {};

  // Ayarlar Dialogu (Toggle ve Buton)
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateInternal) {
          return AlertDialog(
            title: const Text("Ayarlar"),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Filtreleme Toggle
                SwitchListTile(
                  title: const Text("Filtreleme"),
                  subtitle: Text(_isFilterEnabled ? "Açık" : "Kapalı"),
                  value: _isFilterEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _isFilterEnabled = val); // Ana ekranı güncelle
                    setStateInternal(() {}); // Dialog'u güncelle
                  },
                ),
                
                // 2. Filtre Ayarları Butonu (Toggle kapalıysa disable olur)
                ElevatedButton.icon(
                  onPressed: _isFilterEnabled 
                    ? () {
                        Navigator.pop(context); // Ayarları kapat
                        _showFilterPanel();     // Paneli aç
                      }
                    : null, // Kapalıysa tıklanamaz
                  icon: const Icon(Icons.filter_list),
                  label: const Text("Filtre Ayarlarını Yap"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMain,
                  ),
                ),
                const Divider(),
                // Veritabanı Temizle
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("Verileri Sıfırla", style: TextStyle(color: Colors.red)),
                  onTap: () async {
                     final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Dikkat!"),
                          content: const Text("Tüm anılar silinecek. Geri alınamaz."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sil")),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _dbService.clearDatabase();
                        if (mounted) Navigator.pop(context);
                      }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text("Çıkış"),
                  onTap: () => exit(0),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Filtreleme Paneli (BottomSheet)
  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStatePanel) {
          
          // Eğer veritabanı boşsa veya henüz yüklenmediyse varsayılanları göster
          List<String> categoriesToShow = _dynamicCategories.isEmpty 
              ? ['Gezi', 'Sinema', 'Yemek', 'Diğer'] 
              : _dynamicCategories.toList();

          return Container(
            padding: const EdgeInsets.all(24),
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Filtreleme Seçenekleri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // Tarih Aralığı Seçimi
                const Text("Tarih Aralığı", style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.date_range, color: AppColors.primary),
                  title: Text(_selectedDateRange == null 
                      ? "Tarih Aralığı Seçilmedi" 
                      : "${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}"
                  ),
                  trailing: _selectedDateRange != null 
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() {
                        _selectedDateRange = null;
                        setStatePanel((){});
                      })) 
                    : null,
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked); // Ana ekranı güncelle
                      setStatePanel((){}); // Paneli güncelle
                    }
                  },
                ),
                
                const Divider(),
                
                // Kategoriler (Dinamik Liste)
                const Text("Kategoriler (Mevcut Anılardan)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: categoriesToShow.map((cat) {
                    bool isSelected = _selectedFilters.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.accent,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedFilters.add(cat);
                          } else {
                            _selectedFilters.remove(cat);
                          }
                        });
                        setStatePanel((){});
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: AppTheme.mainGradientDecoration,
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Memory Station", style: GoogleFonts.pacifico(fontSize: 28, color: AppColors.primaryDark)),
                    IconButton(
                      onPressed: _showSettingsDialog,
                      icon: const Icon(Icons.favorite, color: AppColors.primary, size: 30),
                    ),
                  ],
                ),
              ),
            ),
            
            // Eğer Filtreleme Açıksa Bilgi Çubuğu Göster
            if (_isFilterEnabled)
              Container(
                width: double.infinity,
                color: AppColors.primary.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    "Filtreleme Aktif: ${_selectedFilters.isEmpty ? 'Tüm Kategoriler' : '${_selectedFilters.length} Kategori'} | ${_selectedDateRange != null ? 'Tarih Sınırlı' : 'Tüm Zamanlar'}",
                    style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
                  ),
                ),
              ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _dbService.getEvents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Hata oluştu"));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;

                  // --- KATEGORİLERİ DİNAMİK OLARAK TOPLA ---
                  // Gelen tüm dökümanların kategorilerini bir havuza atıyoruz
                  Set<String> loadedCategories = {};
                  for (var doc in docs) {
                    final map = doc.data() as Map<String, dynamic>;
                    if (map['category'] != null) {
                      loadedCategories.add(map['category']);
                    }
                  }
                  // Bunu global değişkene atayalım ki filtre panelinde gözüksün
                  _dynamicCategories = loadedCategories;
                  
                  // --- FİLTRELEME MANTIĞI ---
                  final data = docs.where((doc) {
                    if (!_isFilterEnabled) return true; // Filtre kapalıysa hepsini göster
                    
                    final map = doc.data() as Map<String, dynamic>;
                    final category = map['category'] ?? 'Diğer';
                    final date = (map['date'] as Timestamp).toDate();

                    // 1. Kategori Kontrolü
                    bool categoryMatch = _selectedFilters.isEmpty || _selectedFilters.contains(category);
                    
                    // 2. Tarih Kontrolü
                    bool dateMatch = true;
                    if (_selectedDateRange != null) {
                      dateMatch = date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                                  date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                    }

                    return categoryMatch && dateMatch;
                  }).toList();

                  if (data.isEmpty) return const Center(child: Text("Filtrelere uygun anı bulunamadı."));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final event = MemoryEvent.fromFirestore(data[index]);
                      return TimelineTile(
                        alignment: TimelineAlign.manual,
                        lineXY: 0.15,
                        isFirst: index == 0,
                        isLast: index == data.length - 1,
                        indicatorStyle: IndicatorStyle(width: 28, color: AppColors.background, padding: const EdgeInsets.all(4), iconStyle: IconStyle(color: AppColors.primary, iconData: Icons.favorite)),
                        beforeLineStyle: const LineStyle(color: AppColors.timelineLine, thickness: 3),
                        endChild: GestureDetector(
                          onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => MemoryDetailView(event: event)),
                          child: MemoryCard(event: event),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEventScreen())),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text("Anı Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}