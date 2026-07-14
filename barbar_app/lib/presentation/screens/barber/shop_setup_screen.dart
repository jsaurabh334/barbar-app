import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:barbar_app/core/network/websocket_client.dart';
import 'package:barbar_app/domain/repositories/barber_repository.dart';
import 'package:barbar_app/presentation/bloc/shop_setup/shop_setup_bloc.dart';
import 'package:barbar_app/presentation/screens/barber_dashboard_shell.dart';
import 'package:barbar_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:barbar_app/presentation/bloc/auth/auth_event.dart';

class ShopSetupScreen extends StatefulWidget {
  final WebSocketClient webSocketClient;

  const ShopSetupScreen({Key? key, required this.webSocketClient}) : super(key: key);

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  int _currentStep = 0;

  final _shopNameCtrl = TextEditingController();
  final _shopDescCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);

  final _services = <Map<String, dynamic>>[];
  final _serviceNameCtrl = TextEditingController();
  final _servicePriceCtrl = TextEditingController();
  final _serviceDurationCtrl = TextEditingController();
  String? _selectedCategoryId;
  List<dynamic> _cachedCategories = [];

  @override
  void initState() {
    super.initState();
    context.read<ShopSetupBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _shopDescCtrl.dispose();
    _expCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _serviceNameCtrl.dispose();
    _servicePriceCtrl.dispose();
    _serviceDurationCtrl.dispose();
    super.dispose();
  }

  void _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  void _addService() {
    final name = _serviceNameCtrl.text.trim();
    final price = double.tryParse(_servicePriceCtrl.text.trim());
    final duration = int.tryParse(_serviceDurationCtrl.text.trim());
    if (name.isEmpty || price == null || duration == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all service fields and select a category')),
      );
      return;
    }
    setState(() {
      _services.add({
        'name': name,
        'category_id': _selectedCategoryId,
        'price': price,
        'duration_minutes': duration,
        'is_addon': false,
      });
      _serviceNameCtrl.clear();
      _servicePriceCtrl.clear();
      _serviceDurationCtrl.clear();
    });
  }

  void _removeService(int index) {
    setState(() => _services.removeAt(index));
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location service is disabled. Please enable GPS.')),
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
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied. Enable from settings.')),
        );
      }
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _latCtrl.text = pos.latitude.toStringAsFixed(6);
          _lngCtrl.text = pos.longitude.toStringAsFixed(6);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get location. Try again.')),
        );
      }
    }
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_shopNameCtrl.text.trim().isEmpty) return false;
        return true;
      case 1:
        if (_addressCtrl.text.trim().isEmpty ||
            _cityCtrl.text.trim().isEmpty ||
            _stateCtrl.text.trim().isEmpty ||
            _pincodeCtrl.text.trim().isEmpty) return false;
        if (_latCtrl.text.trim().isEmpty || _lngCtrl.text.trim().isEmpty) {
          return false;
        }
        return true;
      case 2:
        return true;
      case 3:
        return _services.isNotEmpty;
      default:
        return true;
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'shop_name': _shopNameCtrl.text.trim(),
      'shop_description': _shopDescCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
      'latitude': double.tryParse(_latCtrl.text.trim()) ?? 0.0,
      'longitude': double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
      'start_time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      'experience_years': int.tryParse(_expCtrl.text.trim()) ?? 0,
      'services': _services,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AuthBloc>().add(LogoutRequested());
          },
        ),
        title: const Text('Set Up Your Shop'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<ShopSetupBloc, ShopSetupState>(
        listener: (context, state) {
          if (state is ShopSetupSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shop created successfully!'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) {
                  final barberRepo = context.read<BarberRepository>();
                  return BarberDashboardShell(
                    webSocketClient: widget.webSocketClient,
                    barberRepository: barberRepo,
                  );
                },
              ),
            );
          } else if (state is ShopSetupFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ShopSetupLoading || state is ShopSetupSubmitting;
          if (state is CategoriesLoaded) {
            _cachedCategories = state.categories;
          }
          final categories = _cachedCategories;

          return Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (!_validateStep(_currentStep)) {
                final msgs = {
                  0: 'Enter shop name',
                  1: 'Fill address fields and set location (use "Use Current Location")',
                  2: 'Set opening & closing timings',
                  3: 'Add at least one service',
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msgs[_currentStep] ?? 'Please fill all required fields')),
                );
                return;
              }
              if (_currentStep < 3) {
                setState(() => _currentStep++);
              } else {
                context.read<ShopSetupBloc>().add(SubmitShop(_buildPayload()));
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            onStepTapped: (step) {
              if (step < _currentStep) setState(() => _currentStep = step);
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (_currentStep < 3)
                      ElevatedButton(
                        onPressed: isLoading ? null : details.onStepContinue,
                        child: const Text('Next'),
                      )
                    else
                      ElevatedButton(
                        onPressed: isLoading ? null : details.onStepContinue,
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create Shop'),
                      ),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Shop Info'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    TextFormField(
                      controller: _shopNameCtrl,
                      decoration: const InputDecoration(labelText: 'Shop Name *', hintText: 'e.g. Premium Barber Shop'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopDescCtrl,
                      decoration: const InputDecoration(labelText: 'Description', hintText: 'Tell customers about your shop'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _expCtrl,
                      decoration: const InputDecoration(labelText: 'Experience (years)', hintText: 'e.g. 5'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Location'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address *', hintText: 'Street, building, area'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(labelText: 'City *'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _stateCtrl,
                          decoration: const InputDecoration(labelText: 'State *'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pincodeCtrl,
                      decoration: const InputDecoration(labelText: 'Pincode *'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Use Current Location'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          controller: _latCtrl,
                          decoration: const InputDecoration(labelText: 'Latitude *'),
                          keyboardType: TextInputType.number,
                          readOnly: true,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _lngCtrl,
                          decoration: const InputDecoration(labelText: 'Longitude *'),
                          keyboardType: TextInputType.number,
                          readOnly: true,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Timings'),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    ListTile(
                      title: const Text('Opening Time'),
                      subtitle: Text(_startTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(true),
                    ),
                    ListTile(
                      title: const Text('Closing Time'),
                      subtitle: Text(_endTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(false),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Services'),
                isActive: _currentStep >= 3,
                state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Category *'),
                        items: categories.map((c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      )
                    else
                      const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          controller: _serviceNameCtrl,
                          decoration: const InputDecoration(labelText: 'Service Name', hintText: 'e.g. Haircut'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextFormField(
                          controller: _servicePriceCtrl,
                          decoration: const InputDecoration(labelText: 'Price (₹)'),
                          keyboardType: TextInputType.number,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _serviceDurationCtrl,
                          decoration: const InputDecoration(labelText: 'Duration (min)'),
                          keyboardType: TextInputType.number,
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addService,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Service'),
                    ),
                    const SizedBox(height: 8),
                    ..._services.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      return Card(
                        child: ListTile(
                          title: Text(s['name'] as String),
                          subtitle: Text('₹${s['price']} · ${s['duration_minutes']} min'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeService(i),
                          ),
                        ),
                      );
                    }),
                    if (_services.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Add at least one service', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
