import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/services/id_ocr_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/bookings/presentation/providers/new_booking_providers.dart';
import 'package:rooms/src/features/customers/data/repositories/supabase_customer_repository.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';

/// Page for entering guest information with tabs for each guest
class BookingGuestsPage extends ConsumerStatefulWidget {
  const BookingGuestsPage({super.key});

  @override
  ConsumerState<BookingGuestsPage> createState() => _BookingGuestsPageState();
}

class _BookingGuestsPageState extends ConsumerState<BookingGuestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<GlobalKey<_GuestFormState>> _formKeys = [];

  @override
  void initState() {
    super.initState();
    final guestCount = ref.read(newBookingProvider).guestCount;
    _tabController = TabController(length: guestCount, vsync: this);
    _initFormKeys(guestCount);
  }

  void _initFormKeys(int count) {
    _formKeys.clear();
    for (int i = 0; i < count; i++) {
      _formKeys.add(GlobalKey<_GuestFormState>());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(newBookingProvider);

    // Update tab controller if guest count changes
    if (_tabController.length != bookingState.guestCount) {
      _tabController.dispose();
      _tabController = TabController(
        length: bookingState.guestCount,
        vsync: this,
      );
      _initFormKeys(bookingState.guestCount);
    }

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Guest Information'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: bookingState.guestCount > 3,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.grey400,
          tabs: List.generate(
            bookingState.guestCount,
            (index) => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Guest ${index + 1}'),
                  if (bookingState.guests.length > index &&
                      bookingState.guests[index] != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          bookingState.guestCount,
          (index) => _GuestForm(
            key: _formKeys.length > index ? _formKeys[index] : null,
            guestIndex: index,
            existingGuest: bookingState.guests.length > index
                ? bookingState.guests[index]
                : null,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(bookingState),
    );
  }

  Widget _buildBottomBar(NewBookingState state) {
    final filledCount = state.guests.where((g) => g != null).length;
    final allFilled = filledCount == state.guestCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Compact progress indicator
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      value: state.guestCount > 0
                          ? filledCount / state.guestCount
                          : 0,
                      backgroundColor: AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation(
                        allFilled ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$filledCount/${state.guestCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: allFilled
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Done button
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: allFilled ? () => Navigator.pop(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grey300,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  allFilled ? 'Done' : 'Fill all',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual guest form
class _GuestForm extends ConsumerStatefulWidget {
  final int guestIndex;
  final Customer? existingGuest;

  const _GuestForm({super.key, required this.guestIndex, this.existingGuest});

  @override
  ConsumerState<_GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends ConsumerState<_GuestForm>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();

  Gender _selectedGender = Gender.male;
  IdType _selectedIdType = IdType.aadhar;
  bool _isSaving = false;
  bool _isSaved = false;

  // OCR related
  final IdOcrService _ocrService = IdOcrService();
  bool _isProcessingOcr = false;
  String? _idImagePath;

  // Guest search related
  final _searchController = TextEditingController();
  List<Customer> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingGuest != null) {
      final guest = widget.existingGuest!;
      _nameController.text = guest.name;
      _phoneController.text = guest.phone;
      _emailController.text = guest.email ?? '';
      _idNumberController.text = guest.idNumber;
      _ageController.text = guest.age?.toString() ?? '';
      _addressController.text = guest.address ?? '';
      _selectedGender = guest.gender;
      _selectedIdType = guest.idType;
      _isSaved = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _searchGuests(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final hotel = ref.read(currentHotelProvider);
      if (hotel == null) return;

      final repo = ref.read(supabaseCustomerRepositoryProvider);
      final results = await repo.searchCustomers(hotel.hotelId, query);

      setState(() {
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _populateFromGuest(Customer guest) {
    setState(() {
      _nameController.text = guest.name;
      _phoneController.text = guest.phone;
      _emailController.text = guest.email ?? '';
      _idNumberController.text = guest.idNumber;
      _ageController.text = guest.age?.toString() ?? '';
      _addressController.text = guest.address ?? '';
      _selectedGender = guest.gender;
      _selectedIdType = guest.idType;
      _searchController.clear();
      _searchResults = [];
      _showSearchResults = false;
    });
  }

  Future<void> _saveGuest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final hotel = ref.read(currentHotelProvider);
      if (hotel == null) throw Exception('No hotel selected');

      final customer = Customer(
        id: widget.existingGuest?.id ?? '',
        hotelId: hotel.hotelId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        gender: _selectedGender,
        idType: _selectedIdType,
        idNumber: _idNumberController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        createdAt: widget.existingGuest?.createdAt ?? DateTime.now(),
      );

      // Save to database
      final repo = ref.read(supabaseCustomerRepositoryProvider);
      Customer savedCustomer;

      if (widget.existingGuest != null && widget.existingGuest!.id.isNotEmpty) {
        // Update existing
        await repo.updateCustomer(customer);
        savedCustomer = customer;
      } else {
        // Create new
        savedCustomer = await repo.createCustomer(customer);
      }

      // Update booking state
      ref
          .read(newBookingProvider.notifier)
          .setGuest(widget.guestIndex, savedCustomer);

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guest ${widget.guestIndex + 1} saved'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSaved)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Guest information saved',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isSaved = false),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ),

            // Guest Search Section - Only show if not already saved
            if (!_isSaved) ...[
              _buildGuestSearchSection(),
              const SizedBox(height: 16),
            ],

            // Personal Details Section
            _buildSectionCard(
              title: 'Personal Details',
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _ageController,
                        label: 'Age',
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildGenderSelector(),
              ],
            ),
            const SizedBox(height: 16),

            // ID Details Section
            _buildSectionCard(
              title: 'ID Details',
              children: [
                _buildIdTypeSelector(),
                const SizedBox(height: 16),
                _buildIdScanSection(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _idNumberController,
                  label: '${_selectedIdType.displayName} Number',
                  icon: Icons.badge,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                if (_idImagePath != null) ...[
                  const SizedBox(height: 12),
                  _buildIdImagePreview(),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Address Section
            _buildSectionCard(
              title: 'Address (Optional)',
              children: [
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveGuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved
                      ? AppColors.primary
                      : AppColors.black,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isSaved ? 'Update' : 'Save',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Returning Guest?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _searchGuests,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or email...',
              hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
              prefixIcon: Icon(
                Icons.person_search,
                color: AppColors.grey500,
                size: 20,
              ),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.grey500),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _showSearchResults = false;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          if (_showSearchResults && _searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: AppColors.grey200),
                itemBuilder: (context, index) {
                  final guest = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: guest.gender == Gender.male
                            ? AppColors.info.withValues(alpha: 0.15)
                            : AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          guest.name.isNotEmpty
                              ? guest.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: guest.gender == Gender.male
                                ? AppColors.info
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      guest.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      guest.phone,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.grey400,
                    ),
                    onTap: () => _populateFromGuest(guest),
                  );
                },
              ),
            ),
          ],
          if (_searchController.text.length >= 2 &&
              !_isSearching &&
              _searchResults.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'No matching guests found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.grey600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(fontSize: 12, color: AppColors.grey600),
        ),
        const SizedBox(height: 8),
        Row(
          children: Gender.values.map((gender) {
            final isSelected = _selectedGender == gender;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: gender != Gender.values.last ? 8 : 0,
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedGender = gender),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.black : AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        gender.displayName,
                        style: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIdTypeSelector() {
    return DropdownButtonFormField<IdType>(
      initialValue: _selectedIdType,
      decoration: InputDecoration(
        labelText: 'ID Type',
        prefixIcon: const Icon(Icons.credit_card, color: AppColors.grey600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: IdType.values.map((type) {
        return DropdownMenuItem(value: type, child: Text(type.displayName));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedIdType = value);
        }
      },
    );
  }

  Widget _buildIdScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scan ID Document (Optional)',
          style: TextStyle(fontSize: 12, color: AppColors.grey600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessingOcr
                    ? null
                    : () => _processIdScan(ImageSource.camera),
                icon: _isProcessingOcr
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt, size: 18),
                label: const Text('Scan ID'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.grey400),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessingOcr
                    ? null
                    : () => _processIdScan(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.grey400),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _processIdScan(ImageSource source) async {
    setState(() => _isProcessingOcr = true);

    try {
      final result = await _ocrService.pickAndExtract(source: source);

      if (result.success && result.idNumber != null) {
        setState(() {
          _idImagePath = result.imagePath;
          _idNumberController.text = result.idNumber!;
          // Auto-select ID type if detected
          if (result.idType != null) {
            _selectedIdType = _mapIdType(result.idType!);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result.idType ?? 'ID'} number extracted: ${result.idNumber}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Store the image even if OCR failed
        if (result.imagePath != null) {
          setState(() => _idImagePath = result.imagePath);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.imagePath != null
                  ? AppColors.warning
                  : AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingOcr = false);
    }
  }

  IdType _mapIdType(String idType) {
    switch (idType.toLowerCase()) {
      case 'aadhaar':
      case 'aadhar':
        return IdType.aadhar;
      case 'pan':
        return IdType.other; // PAN is not in IdType enum, use other
      case 'passport':
        return IdType.passport;
      case 'driving license':
        return IdType.drivingLicense;
      case 'voter id':
        return IdType.voterId;
      default:
        return IdType.other;
    }
  }

  Widget _buildIdImagePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.image, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ID document captured',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _idImagePath = null),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Remove', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
