import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'map_picker_screen.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  
  static const List<String> _countryList = [
    'Türkiye', 'ABD', 'Almanya', 'Andorra', 'Arjantin', 'Arnavutluk', 'Avustralya', 'Avusturya', 'Azerbaycan',
    'Bahamalar', 'Bahreyn', 'Bangladeş', 'Belçika', 'Birleşik Arap Emirlikleri', 'Birleşik Krallık', 'Bosna Hersek',
    'Brezilya', 'Bulgaristan', 'Cezayir', 'Çekya', 'Çin', 'Danimarka', 'Dominik Cumhuriyeti', 'Ekvador', 'Endonezya',
    'Ermenistan', 'Estonya', 'Fas', 'Fiji', 'Filipinler', 'Filistin', 'Finlandiya', 'Fransa', 'Güney Afrika',
    'Güney Kore', 'Gürcistan', 'Hırvatistan', 'Hindistan', 'Hollanda', 'Irak', 'İngiltere', 'İran', 'İrlanda',
    'İspanya', 'İsrail', 'İsveç', 'İsviçre', 'İtalya', 'İzlanda', 'Japonya', 'Kamboçya', 'Kamerun', 'Kanada',
    'Karadağ', 'Katar', 'Kazakistan', 'Kıbrıs', 'Kırgızistan', 'Kolombiya', 'Kosova', 'Kosta Rika', 'Kuveyt',
    'Kuzey Kore', 'Kuzey Makedonya', 'Küba', 'Letonya', 'Libya', 'Litvanya', 'Lübnan', 'Lüksemburg', 'Macaristan',
    'Madagaskar', 'Malezya', 'Malta', 'Meksika', 'Mısır', 'Moğolistan', 'Moldova', 'Monako', 'Nikaragua', 'Nijerya',
    'Norveç', 'Özbekistan', 'Pakistan', 'Panama', 'Paraguay', 'Peru', 'Polonya', 'Portekiz', 'Romanya', 'Rusya',
    'Sırbistan', 'Singapur', 'Slovakya', 'Slovenya', 'Sri Lanka', 'Suriye', 'Suudi Arabistan', 'Şili', 'Tacikistan',
    'Tayland', 'Tayvan', 'Tunus', 'Türkmenistan', 'Ukrayna', 'Umman', 'Uruguay', 'Ürdün', 'Venezuela', 'Vietnam',
    'Yemen', 'Yeni Zelanda', 'Yunanistan', 'Diğer'
  ];

  static const List<String> _turkeyCities = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya', 'Artvin', 'Aydın', 'Balıkesir',
    'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır',
    'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay',
    'Isparta', 'Mersin', 'İstanbul', 'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir', 'Kocaeli',
    'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu',
    'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Şanlıurfa',
    'Uşak', 'Van', 'Yozgat', 'Zonguldak', 'Aksaray', 'Bayburt', 'Karaman', 'Kırıkkale', 'Batman', 'Şırnak', 'Bartın',
    'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis', 'Osmaniye', 'Düzce'
  ];

  TextEditingController _countryController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  bool _isSearchingLocation = false;
  LatLng? _selectedLocation; 
  
  final List<String> _categories = ['Sinema', 'Piknik', 'Tiyatro', 'Gezi', 'Yürüyüş', 'Kutlama', 'Yemek'];
  String _selectedCategory = 'Gezi';

  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadAllCategories();
  }

  Future<void> _loadAllCategories() async {
    final dynamicCategories = await _dbService.getAllCategories();
    setState(() {
      for (var cat in dynamicCategories) {
        if (!_categories.contains(cat)) {
          _categories.add(cat);
        }
      }
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      requestFullMetadata: false,
      maxWidth: 800, 
      imageQuality: 60,
    );
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("En fazla 5 fotoğraf seçilebilir.")));
        }
      });
    }
  }

  void _showSearchResultsDialog(List<dynamic> results) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final place = results[index];
          final name = place['name'] ?? 'Bilinmeyen Konum';
          final desc = place['display_name'] ?? '';
          return ListTile(
            leading: const Icon(Icons.location_on, color: AppColors.primary),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedLocation = LatLng(double.parse(place['lat']), double.parse(place['lon']));
                _locationController.text = name;
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum işaretlendi!"), backgroundColor: AppColors.primaryDark));
            },
          );
        },
      ),
    );
  }

  Future<void> _autoFindLocation() async {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Önce bir mekan adı yazın.")));
      return;
    }
    
    setState(() => _isSearchingLocation = true);
    
    String query = _locationController.text;
    if (_cityController.text.isNotEmpty) query += ", ${_cityController.text}";
    if (_countryController.text.isNotEmpty) query += ", ${_countryController.text}";

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'MemoryStationApp/1.0'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // --- ÇÖZÜM: Artık tek sonuç olsa bile otomatik atanmayacak, direkt liste açılacak. ---
          _showSearchResultsDialog(data); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu isme ait koordinat bulunamadı.")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arama başarısız.")));
    } finally {
      setState(() => _isSearchingLocation = false);
    }
  }

  void _showAddCategoryDialog() {
    TextEditingController newCatController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Kategori"),
        content: TextField(
          controller: newCatController,
          decoration: const InputDecoration(hintText: "Kategori adı giriniz"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              if (newCatController.text.isNotEmpty) {
                setState(() {
                  _categories.add(newCatController.text);
                  _selectedCategory = newCatController.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("En az 1 fotoğraf seçmelisin.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> eventData = {
        'title': _titleController.text,
        'location': _locationController.text, 
        'description': _descController.text,
        'date': _selectedDate,
        'category': _selectedCategory,
        'type': 'memory',
        'latitude': _selectedLocation?.latitude,
        'longitude': _selectedLocation?.longitude,
      };

      await _dbService.addEventWithImages(eventData, _selectedImages);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Anı Ekle", style: TextStyle(color: AppColors.textMain)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      body: Container(
        decoration: AppTheme.mainGradientDecoration,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary, width: 1),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, color: AppColors.primary),
                                Text("Ekle", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }
                      final image = _selectedImages[index - 1];
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: FileImage(File(image.path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2, right: 12,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(index - 1)),
                              child: const CircleAvatar(backgroundColor: Colors.red, radius: 10, child: Icon(Icons.close, size: 12, color: Colors.white)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildTextField(_titleController, "Başlık", Icons.edit, isRequired: false),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
                        child: Autocomplete<String>(
                          initialValue: const TextEditingValue(text: 'Türkiye'),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) return _countryList;
                            return _countryList.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (String selection) {
                            setState(() {}); 
                          },
                          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                            _countryController = controller;
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(hintText: "Ülke", border: InputBorder.none, prefixIcon: Icon(Icons.public, size: 20)),
                              onChanged: (v) => setState(() {}),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
                        child: Autocomplete<String>(
                          initialValue: const TextEditingValue(text: 'Ankara'),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (_countryController.text.toLowerCase() != 'türkiye') {
                              return const Iterable<String>.empty();
                            }
                            if (textEditingValue.text.isEmpty) return _turkeyCities;
                            return _turkeyCities.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                            _cityController = controller;
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(hintText: "Şehir", border: InputBorder.none, prefixIcon: Icon(Icons.location_city, size: 20)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText: "Mekan Adı (Örn: Galata Kulesi)",
                            prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: _isSearchingLocation 
                          ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: const Icon(Icons.search, color: AppColors.primary), onPressed: () { FocusScope.of(context).unfocus(); _autoFindLocation(); }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: () async {
                    final LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => MapPickerScreen(initialLocation: _selectedLocation),
                      ),
                    );
                    
                    if (result != null) {
                      setState(() {
                        _selectedLocation = result;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                      border: _selectedLocation != null ? Border.all(color: AppColors.primary, width: 1.5) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedLocation != null ? Icons.map : Icons.add_location_alt, 
                          color: _selectedLocation != null ? AppColors.primary : Colors.grey
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedLocation != null 
                              ? "Konum İşaretlendi"
                              : "Haritada Konum İşaretle (İsteğe Bağlı)",
                            style: TextStyle(
                              fontSize: 16, 
                              color: _selectedLocation != null ? AppColors.primary : Colors.grey[600],
                              fontWeight: _selectedLocation != null ? FontWeight.bold : FontWeight.normal
                            ),
                          ),
                        ),
                        if (_selectedLocation != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedLocation = null),
                            child: const Icon(Icons.close, color: Colors.red),
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                const Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          selectedColor: AppColors.primary,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = cat);
                          },
                        ),
                      )),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text("Yeni"),
                        onPressed: _showAddCategoryDialog,
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                 Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Bu anı hakkında bir şeyler yaz...",
                      prefixIcon: Icon(Icons.description, color: AppColors.primary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                 InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate.isBefore(DateTime(2024, 12, 7)) ? DateTime(2024, 12, 7) : _selectedDate,
                      firstDate: DateTime(2024, 12, 7),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('d MMMM yyyy', 'tr').format(_selectedDate),
                          style: const TextStyle(fontSize: 16, color: AppColors.textMain),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Kaydet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isRequired = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextFormField(
        controller: controller,
        validator: isRequired ? (val) => val!.isEmpty ? 'Boş bırakılamaz' : null : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}