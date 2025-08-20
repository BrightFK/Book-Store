import 'dart:io';

import 'package:book_store/main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- STATE VARIABLES ---
  final _profileBox = Hive.box('user_profile');
  bool _isEditing = false;
  bool _isLoading = true; // <-- CHANGED: To show loading indicator initially

  // <-- CHANGED: Controllers for all new fields
  final _nameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // <-- CHANGED: Now fetches from Supabase
  Future<void> _loadProfileData() async {
    // Load local image path from Hive
    if (!kIsWeb) {
      _imagePath = _profileBox.get('imagePath');
    }

    // Fetch profile from Supabase
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Populate controllers with fetched data
      _nameController.text = data['display_name'] ?? '';
      _addressLine1Controller.text = data['address_line1'] ?? '';
      _addressLine2Controller.text = data['address_line2'] ?? '';
      _cityController.text = data['city'] ?? '';
      _stateController.text = data['state'] ?? '';
      _postalCodeController.text = data['postal_code'] ?? '';
      _countryController.text = data['country'] ?? '';
    } catch (e) {
      // Handle case where profile doesn't exist yet or other errors
      _nameController.text = 'Your Name';
      // All other fields will be empty
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    // ... (This function remains unchanged)
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picking is not supported on the web version.'),
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Your Photo',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Crop Your Photo',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imagePath = croppedFile.path;
        });
      }
    }
  }

  // <-- CHANGED: Now saves to Supabase
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    // Save local image path to Hive
    if (_imagePath != null && !kIsWeb) {
      _profileBox.put('imagePath', _imagePath!);
    }

    // Save profile data to Supabase
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').upsert({
        'id': userId,
        'display_name': _nameController.text.trim(),
        'address_line1': _addressLine1Controller.text.trim(),
        'address_line2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'country': _countryController.text.trim(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile Saved!')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Don't show button while loading
          if (!_isLoading)
            TextButton(
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              child: Text(_isEditing ? 'Save' : 'Edit'),
            ),
        ],
      ),
      // <-- CHANGED: Handle initial loading state
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
          ? _buildEditView()
          : _buildDisplayView(),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildDisplayView() {
    final userEmail = supabase.auth.currentUser?.email ?? 'No email found';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAvatar(),
          const SizedBox(height: 24),
          Text(
            _nameController.text,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            userEmail,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Divider(),
          _buildSectionHeader('Shipping Address'),
          _buildInfoTile(
            Icons.home_outlined,
            'Address',
            '${_addressLine1Controller.text}\n${_addressLine2Controller.text}',
          ),
          _buildInfoTile(
            Icons.location_city_outlined,
            'City',
            _cityController.text,
          ),
          _buildInfoTile(
            Icons.map_outlined,
            'State / Postal Code',
            '${_stateController.text} / ${_postalCodeController.text}',
          ),
          _buildInfoTile(
            Icons.public_outlined,
            'Country',
            _countryController.text,
          ),
          const SizedBox(height: 16),
          const Divider(),
          _buildSectionHeader('Payment Methods'),
          // This is a placeholder as storing real payment info is complex and requires a provider like Stripe
          const ListTile(
            leading: Icon(Icons.credit_card),
            title: Text('Payment Method'),
            subtitle: Text('Visa ending in **** 1234'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditView() {
    final userEmail = supabase.auth.currentUser?.email ?? 'No email found';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(onTap: _pickImage, child: _buildAvatar()),
          const SizedBox(height: 8),
          const Text(
            'Tap picture to change',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Display Name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: userEmail,
              filled: true,
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Shipping Address'),
          TextFormField(
            controller: _addressLine1Controller,
            decoration: const InputDecoration(labelText: 'Address Line 1'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine2Controller,
            decoration: const InputDecoration(
              labelText: 'Address Line 2 (Optional)',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(labelText: 'Postal Code'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildAvatar() {
    ImageProvider? backgroundImage;
    if (!kIsWeb && _imagePath != null) {
      backgroundImage = FileImage(File(_imagePath!));
    }
    return CircleAvatar(
      radius: 60,
      backgroundImage: backgroundImage,
      child: backgroundImage == null
          ? const Icon(Icons.person, size: 60)
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    if (subtitle.trim().isEmpty ||
        subtitle.trim() == '\n' ||
        subtitle.trim() == '/') {
      return const SizedBox.shrink(); // Don't show tile if info is missing
    }
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
