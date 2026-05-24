import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final bool isReadOnly; 

  const MapPickerScreen({
    super.key, 
    this.initialLocation, 
    this.isReadOnly = false
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> with TickerProviderStateMixin {
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  
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
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearching = false;
  AnimationController? _animController; 

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _animController?.dispose();
    _animController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final Animation<double> animation = CurvedAnimation(parent: _animController!, curve: Curves.fastOutSlowIn);

    _animController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _animController!.forward();
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
              final loc = LatLng(double.parse(place['lat']), double.parse(place['lon']));
              setState(() => _pickedLocation = loc);
              _animatedMapMove(loc, 15.0); 
              FocusScope.of(context).unfocus(); 
            },
          );
        },
      ),
    );
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _isSearching = true);
    
    String query = _searchController.text;
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum bulunamadı.")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arama sırasında hata oluştu.")));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReadOnly ? "Konum Detayı" : "Konum Seç"),
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _pickedLocation);
              },
            )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? const LatLng(39.9334, 32.8597),
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onTap: widget.isReadOnly 
                ? null 
                : (tapPosition, point) {
                    setState(() {
                      _pickedLocation = point;
                    });
                  },
            ),
            children: [
              TileLayer(
                urlTemplate: AppMapStyles.styles[AppMapStyles.currentStyle]!,
                userAgentPackageName: 'com.memorystation.app',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation!,
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on, 
                        color: Colors.red, 
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (!widget.isReadOnly)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.glowShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
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
                        Container(width: 1, height: 30, color: Colors.grey[300]),
                        Expanded(
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
                      ],
                    ),
                    const Divider(height: 1),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Mekan Adı (Örn: Galata Kulesi)",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: _isSearching 
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.search, color: AppColors.primary),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                _searchLocation();
                              },
                            ),
                      ),
                      onSubmitted: (val) {
                        FocusScope.of(context).unfocus();
                        _searchLocation();
                      },
                    ),
                  ],
                ),
              ),
            ),
          
          if (!widget.isReadOnly)
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.glowShadow,
                ),
                child: Text(
                  _pickedLocation == null 
                    ? "Haritaya dokunarak bir konum işaretleyin." 
                    : "İşaretlendi: ${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
              ),
            ),
        ],
      ),
    );
  }
}