import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  
  // Kategoriler
  final List<String> _categories = ['Sinema', 'Piknik', 'Tiyatro', 'Gezi', 'Yürüyüş', 'Kutlama', 'Yemek'];
  String _selectedCategory = 'Gezi';

  final DatabaseService _dbService = DatabaseService();

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
    // Form validasyonu çağırıyoruz ama artık fieldlar zorunlu değil
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("En az 1 fotoğraf seçmelisin.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> eventData = {
        'title': _titleController.text, // Boş olabilir
        'location': _locationController.text, // Boş olabilir
        'description': _descController.text,
        'date': _selectedDate,
        'category': _selectedCategory,
        'type': 'memory',
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
                // Fotoğraf Alanı
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
                
                // Başlık ve Konum (Zorunluluk Kalktı)
                _buildTextField(_titleController, "Başlık (İsteğe bağlı)", Icons.edit, isRequired: false),
                const SizedBox(height: 12),
                _buildTextField(_locationController, "Konum (İsteğe bağlı)", Icons.location_on, isRequired: false),
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
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
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

  // isRequired parametresi eklendi
  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isRequired = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextFormField(
        controller: controller,
        // Validator artık opsiyonel
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