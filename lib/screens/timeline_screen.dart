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
  bool _isFilterEnabled = false; 
  List<String> _selectedFilters = []; 
  DateTimeRange? _selectedDateRange;
  
  // --- TASK 2: ZOOM STATE ---
  // 1.0 = Tam boyut (Detaylı kart)
  // 0.4 = En küçük boyut (Kompakt görünüm)
  // Eşik değer: 0.6 (Bunun altı kompakta geçer)
  double _currentScale = 1.0; 
  double _baseScale = 1.0;

  final List<String> _defaultCategories = [
    'Sinema', 'Piknik', 'Tiyatro', 'Gezi', 'Yürüyüş', 'Kutlama', 'Yemek', 'Diğer'
  ];
  Set<String> _allCategories = {};

  @override
  void initState() {
    super.initState();
    _allCategories.addAll(_defaultCategories);
  }

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
                SwitchListTile(
                  title: const Text("Filtreleme"),
                  subtitle: Text(_isFilterEnabled ? "Açık" : "Kapalı"),
                  value: _isFilterEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _isFilterEnabled = val);
                    setStateInternal(() {});
                  },
                ),
                ElevatedButton.icon(
                  onPressed: _isFilterEnabled 
                    ? () {
                        Navigator.pop(context); 
                        _showFilterPanel();     
                      }
                    : null,
                  icon: const Icon(Icons.filter_list),
                  label: const Text("Filtre Ayarlarını Yap"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMain,
                  ),
                ),
                const Divider(),
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

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStatePanel) {
          List<String> categoriesToShow = _allCategories.toList()..sort();

          return Container(
            padding: const EdgeInsets.all(24),
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Filtreleme Seçenekleri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
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
                      setState(() => _selectedDateRange = picked);
                      setStatePanel((){});
                    }
                  },
                ),
                
                const Divider(),
                
                const Text("Kategoriler", style: TextStyle(fontWeight: FontWeight.bold)),
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

  // --- COMPACT VIEW WIDGET (TASK 2) ---
  Widget _buildCompactCard(MemoryEvent event) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            DateFormat('dd.MM.yyyy').format(event.date),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Container(height: 15, width: 2, color: AppColors.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textLight),
        ],
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
                    Text("Memory Station", style: GoogleFonts.pacifico(fontSize: 28, color: AppColors.purpleHeart)),
                    IconButton(
                      onPressed: _showSettingsDialog,
                      icon: const Icon(Icons.settings, color: AppColors.textMain, size: 28),
                    ),
                  ],
                ),
              ),
            ),
            
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
              // TASK 2: GESTURE DETECTOR ILE ZOOM (SCALE) ALGILAMA
              child: GestureDetector(
                onScaleStart: (details) {
                  _baseScale = _currentScale;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    // Zoom seviyesini 0.4 ile 1.0 arasında tutuyoruz
                    _currentScale = (_baseScale * details.scale).clamp(0.4, 1.0);
                  });
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getEvents(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text("Hata oluştu"));
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;

                    for (var doc in docs) {
                      final map = doc.data() as Map<String, dynamic>;
                      if (map['category'] != null) {
                        _allCategories.add(map['category']);
                      }
                    }
                    
                    final data = docs.where((doc) {
                      if (!_isFilterEnabled) return true;
                      final map = doc.data() as Map<String, dynamic>;
                      final category = map['category'] ?? 'Diğer';
                      final date = (map['date'] as Timestamp).toDate();
                      bool categoryMatch = _selectedFilters.isEmpty || _selectedFilters.contains(category);
                      bool dateMatch = true;
                      if (_selectedDateRange != null) {
                        dateMatch = date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                                    date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                      }
                      return categoryMatch && dateMatch;
                    }).toList();

                    if (data.isEmpty) return const Center(child: Text("Anı bulunamadı."));

                    // Zoom durumuna göre görünüm değişimi
                    bool isCompact = _currentScale < 0.6;

                    return ListView.builder(
                      // Zoom yaptıkça liste paddingini de ayarlayalım ki ferahlasın veya sıkışsın
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10 * _currentScale),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final event = MemoryEvent.fromFirestore(data[index]);
                        
                        return TimelineTile(
                          alignment: TimelineAlign.manual,
                          lineXY: 0.15,
                          isFirst: index == 0,
                          isLast: index == data.length - 1,
                          indicatorStyle: IndicatorStyle(
                            // TASK 2: Kalpler birbirine yaklaşacak
                            // Zoom azaldıkça width ve padding küçülür
                            width: isCompact ? 16 : 28 * _currentScale, 
                            color: AppColors.background,
                            padding: EdgeInsets.all(isCompact ? 2 : 4 * _currentScale),
                            iconStyle: IconStyle(
                              color: AppColors.purpleHeart,
                              iconData: Icons.favorite,
                              // Zoom out yapınca ikon da küçülsün
                              fontSize: isCompact ? 12 : 20 * _currentScale,
                            ),
                          ),
                          // Çizgi kalınlığı da incelsin
                          beforeLineStyle: LineStyle(color: AppColors.timelineLine, thickness: isCompact ? 1 : 3 * _currentScale),
                          
                          endChild: GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context, 
                              isScrollControlled: true, 
                              backgroundColor: Colors.transparent, 
                              builder: (_) => MemoryDetailView(event: event)
                            ),
                            // TASK 2: Zoom level'a göre Widget değişimi
                            child: isCompact 
                              ? _buildCompactCard(event) // 0.6'nın altındaysa Kompakt
                              : Transform.scale(
                                  // 0.6 üzerindeyse normal kart ama biraz scale etkisi verelim
                                  scale: _currentScale < 0.8 ? 0.95 : 1.0, 
                                  child: MemoryCard(event: event)
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
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