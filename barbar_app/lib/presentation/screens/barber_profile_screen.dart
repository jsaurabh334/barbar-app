import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/barber_repository.dart';
import '../bloc/barber_profile/barber_profile_bloc.dart';
import '../bloc/barber_profile/barber_profile_event.dart';
import '../bloc/barber_profile/barber_profile_state.dart';
import '../widgets/glass_card.dart';

class BarberProfileScreen extends StatefulWidget {
  final BarberRepository barberRepository;
  const BarberProfileScreen({super.key, required this.barberRepository});

  @override
  State<BarberProfileScreen> createState() => _BarberProfileScreenState();
}

class _BarberProfileScreenState extends State<BarberProfileScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  final _shopImageController = TextEditingController();
  final _amenitiesController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isHomeServiceAvailable = false;
  bool _isLoading = false;
  // Multi-image management
  List<String> _shopImages = [];      // Already uploaded URLs
  List<File> _pendingImageFiles = []; // Files picked but not uploaded yet
  bool _isUploadingImages = false;
  // Location
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<BarberProfileBloc>().add(FetchBarberProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _expController.dispose();
    _shopImageController.dispose();
    _amenitiesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _populateForm(Map<String, dynamic> profile) {
    _nameController.text = (profile['shop_name'] as String?) ?? '';
    _descController.text = (profile['shop_description'] as String?) ?? '';
    _addressController.text = (profile['address'] as String?) ?? '';
    _cityController.text = (profile['city'] as String?) ?? '';
    _stateController.text = (profile['state'] as String?) ?? '';
    _pincodeController.text = (profile['pincode'] as String?) ?? '';
    _phoneController.text = (profile['phone'] as String?) ?? '';
    _altPhoneController.text = (profile['alternate_phone'] as String?) ?? '';
    _emailController.text = (profile['email'] as String?) ?? '';
    _expController.text = (profile['experience_years']?.toString()) ?? '0';
    _shopImageController.text = (profile['shop_image'] as String?) ?? '';
    _amenitiesController.text = ((profile['amenities'] as List<dynamic>?) ?? []).join(', ');
    _tagsController.text = ((profile['tags'] as List<dynamic>?) ?? []).join(', ');
    _isHomeServiceAvailable = (profile['is_home_service_available'] as bool?) ?? false;
    _latitude = (profile['latitude'] as num?)?.toDouble();
    _longitude = (profile['longitude'] as num?)?.toDouble();
    // Load shop_images array
    final rawImages = (profile['shop_images'] as List<dynamic>?) ?? [];
    _shopImages = rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    // Also add shop_image (single) if not already in list
    final singleImg = (profile['shop_image'] as String?) ?? '';
    if (singleImg.isNotEmpty && !_shopImages.contains(singleImg)) {
      _shopImages.insert(0, singleImg);
    }
  }

  void _save() {
    context.read<BarberProfileBloc>().add(UpdateBarberProfile({
      'shop_name': _nameController.text,
      'shop_description': _descController.text,
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
      'phone': _phoneController.text,
      'alternate_phone': _altPhoneController.text,
      'email': _emailController.text,
      'experience_years': int.tryParse(_expController.text) ?? 0,
      'shop_image': _shopImages.isNotEmpty ? _shopImages.first : '',
      'shop_images': _shopImages,
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
      'amenities': _amenitiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'is_home_service_available': _isHomeServiceAvailable,
    }));
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final picked = await _picker.pickMultiImage(imageQuality: 75);
        if (picked.isNotEmpty) {
          setState(() {
            _pendingImageFiles.addAll(picked.map((x) => File(x.path)));
          });
          await _uploadPendingImages();
        }
      } else {
        final picked = await _picker.pickImage(source: source, imageQuality: 75);
        if (picked != null) {
          setState(() => _pendingImageFiles.add(File(picked.path)));
          await _uploadPendingImages();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _uploadPendingImages() async {
    if (_pendingImageFiles.isEmpty) return;
    setState(() => _isUploadingImages = true);
    try {
      final urls = await widget.barberRepository.uploadShopImages(_pendingImageFiles);
      setState(() {
        _shopImages.addAll(urls);
        _pendingImageFiles.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${urls.length} photo(s) uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
      setState(() => _pendingImageFiles.clear());
    } finally {
      if (mounted) setState(() => _isUploadingImages = false);
    }
  }

  Future<void> _pickCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location/GPS'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied'), backgroundColor: AppColors.error),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Enable from settings.'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location captured: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SHOP PROFILE')),
      body: BlocConsumer<BarberProfileBloc, BarberProfileState>(
        listener: (context, state) {
          if (state is BarberProfileLoaded) {
            _isLoading = false;
            _populateForm(state.profile);
          } else if (state is BarberProfileLoading) {
            _isLoading = true;
          } else if (state is BarberProfileSuccess) {
            _isLoading = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          } else if (state is BarberProfileFailure) {
            _isLoading = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is BarberProfileLoading && _nameController.text.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('SHOP INFORMATION', Icons.store),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildField('Shop Name', _nameController, Icons.tag),
                      _buildField('Description', _descController, Icons.description, maxLines: 3),
                      _buildField('Address', _addressController, Icons.location_on),
                      Row(
                        children: [
                          Expanded(child: _buildField('City', _cityController, Icons.location_city)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField('State', _stateController, Icons.map)),
                        ],
                      ),
                      _buildField('Pincode', _pincodeController, Icons.mail),
                      const SizedBox(height: 8),
                      // ---- Location section ----
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_latitude != null && _longitude != null) ? AppColors.success : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  size: 16,
                                  color: (_latitude != null) ? AppColors.success : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    (_latitude != null && _longitude != null)
                                        ? 'Location Set ✓  (${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)})'
                                        : 'Shop location not set — customers won\'t find you on map!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (_latitude != null) ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                ),
                                icon: _isGettingLocation
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : const Icon(Icons.my_location, size: 16),
                                label: Text(
                                  _isGettingLocation ? 'Getting Location...' : 'Use My Current Location',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: _isGettingLocation ? null : _pickCurrentLocation,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ---- End location section ----
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('BUSINESS', Icons.business),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildField('Experience (years)', _expController, Icons.work_history, keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('CONTACT', Icons.phone),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildField('Phone', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                      _buildField('Alternate Phone', _altPhoneController, Icons.phone, keyboardType: TextInputType.phone),
                      _buildField('Email', _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('EXTRA DETAILS', Icons.star),
                      const SizedBox(height: 8),

                      // ---- Multi-image section ----
                      const Text('Shop Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      // Uploaded images preview
                      if (_shopImages.isNotEmpty || _pendingImageFiles.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Uploaded
                              ..._shopImages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final url = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          url,
                                          width: 110, height: 120, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 110, height: 120,
                                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                                            child: const Icon(Icons.image_not_supported, color: AppColors.textMuted),
                                          ),
                                        ),
                                      ),
                                      if (index == 0)
                                        Positioned(
                                          left: 4, top: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                            child: const Text('Cover', style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      Positioned(
                                        right: 4, top: 4,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _shopImages.removeAt(index)),
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              // Pending (uploading)
                              ..._pendingImageFiles.map((f) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(f, width: 110, height: 120, fit: BoxFit.cover),
                                    ),
                                    Container(
                                      width: 110, height: 120,
                                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
                                      child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Buttons: Gallery + Camera
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: _isUploadingImages
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                  : const Icon(Icons.photo_library, size: 18),
                              label: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: _isUploadingImages ? null : () => _pickImages(ImageSource.gallery),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: _isUploadingImages ? null : () => _pickImages(ImageSource.camera),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'First photo is used as cover image on customer map.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      // ---- End multi-image section ----

                      _buildField('Amenities (Comma separated)', _amenitiesController, Icons.wifi),
                      _buildField('Tags (Comma separated)', _tagsController, Icons.local_offer),
                      SwitchListTile(
                        title: const Text('Home Service Available', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Allow customers to book home visits', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _isHomeServiceAvailable,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isHomeServiceAvailable = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: const Text('SAVE PROFILE'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
