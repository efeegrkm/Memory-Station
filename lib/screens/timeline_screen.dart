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
  
  bool _isFilterEnabled = false; 
  List<String> _selectedFilters = []; 
  DateTimeRange? _selectedDateRange;
  
  // ZOOM STATE
  double _currentScale = 1.0; 
  double _baseScale = 1.0;
  bool _showZoomControls = false;

  final List<String> _defaultCategories = [
    'Sinema', 'Piknik', 'Tiyatro', 'Gezi', 'Yürüyüş', 'Kutlama', 'Yemek', 'Diğer'
  ];
  Set<String> _allCategories = {};

  // MİLAT TARİHİ: 7 ARALIK 2024
  final DateTime _milestoneDate = DateTime(2024, 12, 7);

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

  // Kompakt Kart (Zoom < 0.6 veya "Başlangıç" kartı için)
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
          // Başlangıç kartı ise ok işareti koyma
          if (event.type != 'start_point')
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textLight),
        ],
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale + 0.1).clamp(0.4, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale - 0.1).clamp(0.4, 1.0);
    });
  }

  // Tarih karşılaştırma yardımcısı
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
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
                  children: [
                    Expanded(
                      child: Text("Memory Station", style: GoogleFonts.pacifico(fontSize: 28, color: AppColors.purpleHeart)),
                    ),
                    
                    if (_showZoomControls)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _zoomOut,
                              icon: const Icon(Icons.remove, size: 20, color: AppColors.primary),
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              padding: const EdgeInsets.all(8),
                            ),
                            IconButton(
                              onPressed: _zoomIn,
                              icon: const Icon(Icons.add, size: 20, color: AppColors.primary),
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              padding: const EdgeInsets.all(8),
                            ),
                          ],
                        ),
                      ),
                    
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showZoomControls = !_showZoomControls;
                        });
                      },
                      icon: Icon(
                        _showZoomControls ? Icons.search_off : Icons.search,
                        color: AppColors.textMain, 
                        size: 28
                      ),
                    ),
                    
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
              child: GestureDetector(
                onScaleStart: (details) {
                  _baseScale = _currentScale;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _currentScale = (_baseScale * details.scale).clamp(0.4, 1.0);
                  });
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getEvents(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text("Hata oluştu"));
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;

                    // Kategorileri topla
                    for (var doc in docs) {
                      final map = doc.data() as Map<String, dynamic>;
                      if (map['category'] != null) {
                        _allCategories.add(map['category']);
                      }
                    }
                    
                    // --- ÖNEMLİ: VERİ LİSTESİNİ HAZIRLA ---
                    List<MemoryEvent> events = docs.map((doc) => MemoryEvent.fromFirestore(doc)).toList();

                    // Filtreleme uygula
                    events = events.where((event) {
                      if (!_isFilterEnabled) return true;
                      bool categoryMatch = _selectedFilters.isEmpty || _selectedFilters.contains(event.category);
                      bool dateMatch = true;
                      if (_selectedDateRange != null) {
                        dateMatch = event.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                                    event.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                      }
                      return categoryMatch && dateMatch;
                    }).toList();

                    // --- MİLAT NOKTASI MANTIĞI ---
                    // Eğer filtrelenmiş listede 7 Aralık 2024 yoksa, manuel ekle.
                    bool hasMilestone = events.any((e) => isSameDay(e.date, _milestoneDate));
                    
                    if (!hasMilestone) {
                      events.add(MemoryEvent(
                        id: 'milestone_fixed', 
                        title: 'Başlangıç', 
                        location: '', 
                        description: 'Bizim hikayemiz burada başladı...', 
                        date: _milestoneDate, 
                        category: 'Özel', 
                        type: 'start_point' // Özel tip
                      ));
                    }

                    // Tarihe göre sırala (Yeniden eskiye)
                    events.sort((a, b) => b.date.compareTo(a.date));

                    if (events.isEmpty) return const Center(child: Text("Anı bulunamadı."));

                    bool isCompactMode = _currentScale < 0.6;

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(10, 10 * _currentScale, 20, 10 * _currentScale),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final bool isMilestoneEvent = isSameDay(event.date, _milestoneDate);
                        
                        IconData iconData = isMilestoneEvent ? Icons.star : Icons.favorite;
                        Color iconColor = isMilestoneEvent ? Colors.amber : AppColors.purpleHeart;

                        // --- DÜZELTME BURADA ---
                        // copyWith yerine doğrudan LineStyle oluşturuyoruz
                        final LineStyle beforeLineStyle = index == 0 
                          ? LineStyle(
                              thickness: isCompactMode ? 1 : 3 * _currentScale,
                              // Gradient yerine düz renk kullanıyoruz ama şeffaflık veriyoruz
                              color: AppColors.timelineLine.withOpacity(0.3), 
                            )
                          : LineStyle(
                              color: AppColors.timelineLine, 
                              thickness: isCompactMode ? 1 : 3 * _currentScale
                            );
                        // -----------------------

                        final LineStyle afterLineStyle = isMilestoneEvent 
                          ? const LineStyle(thickness: 0, color: Colors.transparent)
                          : LineStyle(color: AppColors.timelineLine, thickness: isCompactMode ? 1 : 3 * _currentScale);

                        return TimelineTile(
                          alignment: TimelineAlign.manual,
                          lineXY: 0.05,
                          isFirst: index == 0,
                          isLast: index == events.length - 1,
                          indicatorStyle: IndicatorStyle(
                            width: isCompactMode ? 16 : (isMilestoneEvent ? 32 : 28) * _currentScale, 
                            color: AppColors.background,
                            padding: EdgeInsets.all(isCompactMode ? 2 : 4 * _currentScale),
                            iconStyle: IconStyle(
                              color: iconColor,
                              iconData: iconData,
                              fontSize: isCompactMode ? 12 : (isMilestoneEvent ? 24 : 20) * _currentScale,
                            ),
                          ),
                          beforeLineStyle: beforeLineStyle,
                          afterLineStyle: afterLineStyle, // Bunu eklemeyi unutmuştuk, şimdi ekledik
                          
                          endChild: GestureDetector(
                            onTap: event.type == 'start_point' 
                              ? null // Tıklanamaz
                              : () => showModalBottomSheet(
                                  context: context, 
                                  isScrollControlled: true, 
                                  backgroundColor: Colors.transparent, 
                                  builder: (_) => MemoryDetailView(event: event)
                                ),
                            child: (event.type == 'start_point')
                              ? _buildCompactCard(event) // Başlangıç her zaman kompakt
                              : (isCompactMode 
                                  ? _buildCompactCard(event) 
                                  : MemoryCard(event: event, scale: _currentScale)
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