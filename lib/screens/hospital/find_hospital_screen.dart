import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/hospital_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class FindHospitalScreen extends StatefulWidget {
  final String? conditionHint;

  const FindHospitalScreen({super.key, this.conditionHint});

  @override
  State<FindHospitalScreen> createState() => _FindHospitalScreenState();
}

class _FindHospitalScreenState extends State<FindHospitalScreen> {
  List<HospitalModel> _allHospitals = [];
  List<HospitalModel> _displayedHospitals = [];
  bool _isLoading = true;
  String? _errorMessage;

  Position? _userPosition;
  bool _hasLocationPermission = false;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Matched', 'Nearest', 'Emergency'

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetchHospitals();
  }

  Future<void> _checkLocationAndFetchHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _hasLocationPermission = LocationService().hasPermission;
      _userPosition = LocationService().currentPosition;

      if (_userPosition == null && _hasLocationPermission) {
        _userPosition = await LocationService().getCurrentLocation();
      }

      final list =
          await FirestoreService().getHospitals(userLocation: _userPosition);

      if (!mounted) return;

      setState(() {
        _allHospitals = list;
        _isLoading = false;
      });

      _applyFiltersAndSearch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load hospitals: $e\nShowing available emergency contacts below.';
      });
    }
  }

  void _requestLocation() async {
    final granted = await LocationService().requestPermission();
    if (!mounted) return;

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Location enabled! Sorting hospitals by distance.'),
          backgroundColor: AppTheme.successMint,
        ),
      );
      _checkLocationAndFetchHospitals();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location permission not granted. Showing all Vizianagaram hospitals.'),
          backgroundColor: AppTheme.primaryTealDark,
        ),
      );
    }
  }

  List<String> _getMatchingSpecialties(String? condition) {
    if (condition == null || condition.trim().isEmpty) return [];
    final lower = condition.toLowerCase();
    final matches = <String>[];

    if (lower.contains('chest') ||
        lower.contains('heart') ||
        lower.contains('cardiac') ||
        lower.contains('గుండె') ||
        lower.contains('ఛాతీ') ||
        lower.contains('सीने')) {
      matches.addAll(['Cardiology', 'Emergency Medicine', 'Critical Care']);
    }

    if (lower.contains('breath') ||
        lower.contains('respiratory') ||
        lower.contains('lungs') ||
        lower.contains('శ్వాస') ||
        lower.contains('सांस')) {
      matches.addAll(['Pulmonology', 'Emergency Medicine', 'General Medicine']);
    }

    if (lower.contains('fever') ||
        lower.contains('cold') ||
        lower.contains('cough') ||
        lower.contains('infection') ||
        lower.contains('జ్వరం') ||
        lower.contains('బుఖార్')) {
      matches.addAll(['General Medicine', 'Pediatrics']);
    }

    if (lower.contains('pregnant') ||
        lower.contains('pregnancy') ||
        lower.contains('maternal') ||
        lower.contains('గర్భిణీ') ||
        lower.contains('ప్రసవ') ||
        lower.contains('गर्भवती')) {
      matches.addAll(['Obstetrics & Gynecology', 'Maternal Health', 'Pediatrics']);
    }

    if (lower.contains('trauma') ||
        lower.contains('fracture') ||
        lower.contains('injury') ||
        lower.contains('bone') ||
        lower.contains('గాయం') ||
        lower.contains('ఫ్రాక్చర్')) {
      matches.addAll(['Orthopedics', 'Trauma & Orthopedics', 'Emergency Medicine']);
    }

    return matches;
  }

  bool _hospitalHasMatchingSpecialty(
      HospitalModel hospital, List<String> matchingSpecs) {
    if (matchingSpecs.isEmpty) return false;
    return hospital.specialists.any((spec) => matchingSpecs.any(
        (match) => spec.toLowerCase().contains(match.toLowerCase())));
  }

  void _applyFiltersAndSearch() {
    final matchingSpecs = _getMatchingSpecialties(widget.conditionHint);

    List<HospitalModel> filtered = List.from(_allHospitals);

    // Search text filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((h) {
        final inName = h.name.toLowerCase().contains(q);
        final inAddress = h.address.toLowerCase().contains(q);
        final inSpecs =
            h.specialists.any((s) => s.toLowerCase().contains(q));
        return inName || inAddress || inSpecs;
      }).toList();
    }

    // Category filter chips
    if (_selectedFilter == 'Matched' && matchingSpecs.isNotEmpty) {
      filtered = filtered
          .where((h) => _hospitalHasMatchingSpecialty(h, matchingSpecs))
          .toList();
    } else if (_selectedFilter == 'Nearest') {
      filtered = filtered
          .where((h) => (h.distanceInKm ?? 999) <= 10.0)
          .toList();
    } else if (_selectedFilter == 'Emergency') {
      filtered = filtered
          .where((h) => h.specialists.any((s) =>
              s.toLowerCase().contains('emergency') ||
              s.toLowerCase().contains('critical') ||
              s.toLowerCase().contains('trauma')))
          .toList();
    }

    setState(() {
      _displayedHospitals = filtered;
    });
  }

  void _onBookToken(HospitalModel hospital) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTealLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.confirmation_num_rounded,
                    color: AppTheme.primaryTeal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OPD Token Booking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        hospital.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.primaryTealDark, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Next Step Preview / తదుపరి దశ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryTealDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Token booking and digital queue management for this facility will be enabled in the next step. You can call the hospital helpline directly in the meantime.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Call Hospital: ${hospital.contactNumber}',
              icon: Icons.phone_in_talk_rounded,
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📞 Calling ${hospital.name} (${hospital.contactNumber})'),
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Close / మూసివేయండి',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchingSpecs = _getMatchingSpecialties(widget.conditionHint);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Find Hospital / ఆసుపత్రులు'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _checkLocationAndFetchHospitals,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Search & Condition Banner
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Condition matching alert banner (if navigated from Symptom Checker)
                  if (widget.conditionHint != null &&
                      widget.conditionHint!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerCoralLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.dangerCoral.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital_rounded,
                              color: AppTheme.dangerCoral, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textPrimary),
                                children: [
                                  const TextSpan(
                                    text: 'Showing facilities for: ',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(
                                    text: widget.conditionHint!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.dangerCoral,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Search input bar
                  TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFiltersAndSearch();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search hospital, area, or specialty...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.primaryTeal, size: 22),
                      filled: true,
                      fillColor: AppTheme.surfaceSecondary,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'All Hospitals (${_allHospitals.length})'),
                        if (matchingSpecs.isNotEmpty)
                          _buildFilterChip('Matched', '⭐ Recommended (${matchingSpecs.first})'),
                        _buildFilterChip('Nearest', '📍 Nearby (< 10km)'),
                        _buildFilterChip('Emergency', '🚨 24/7 Emergency'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Location Permission Notice if location is disabled
            if (_userPosition == null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTealLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppTheme.primaryTealDark, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Location disabled. Showing all Vizianagaram hospitals.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTealDark,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _requestLocation,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Enable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryTealDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Hospital Cards List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryTeal),
                          SizedBox(height: 12),
                          Text(
                            'Loading nearby hospitals from Firestore...',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppTheme.dangerCoral, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.dangerCoral,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  text: 'Retry / మళ్లీ ప్రయత్నించండి',
                                  icon: Icons.refresh_rounded,
                                  onPressed: _checkLocationAndFetchHospitals,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _displayedHospitals.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.local_hospital_outlined,
                                        size: 48, color: AppTheme.textMuted),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No hospitals match your search.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Clear search filter to see all Vizianagaram facilities.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _selectedFilter = 'All';
                                        });
                                        _applyFiltersAndSearch();
                                      },
                                      child: const Text('View All Hospitals'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: _displayedHospitals.length,
                              itemBuilder: (context, index) {
                                final hospital = _displayedHospitals[index];
                                final isMatched = _hospitalHasMatchingSpecialty(
                                    hospital, matchingSpecs);
                                return _buildHospitalCard(hospital, isMatched);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.primaryTeal,
        backgroundColor: AppTheme.surfaceSecondary,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryTeal : AppTheme.borderColor,
          ),
        ),
        onSelected: (val) {
          setState(() {
            _selectedFilter = key;
          });
          _applyFiltersAndSearch();
        },
      ),
    );
  }

  Widget _buildHospitalCard(HospitalModel hospital, bool isSpecialtyMatched) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpecialtyMatched
              ? AppTheme.primaryTeal
              : AppTheme.borderColor,
          width: isSpecialtyMatched ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSpecialtyMatched
                ? AppTheme.primaryTeal.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Ribbon for Matched Specialist
          if (isSpecialtyMatched) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryTeal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'RECOMMENDED FOR YOUR SYMPTOMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Name + Distance badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSpecialtyMatched
                            ? AppTheme.primaryTealLight
                            : AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_hospital_rounded,
                        color: isSpecialtyMatched
                            ? AppTheme.primaryTeal
                            : AppTheme.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (hospital.distanceInKm != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successMintLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.near_me_rounded,
                                          size: 13, color: AppTheme.successMint),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${hospital.distanceInKm!.toStringAsFixed(1)} km away',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.successMint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              const Icon(Icons.verified_rounded,
                                  size: 14, color: AppTheme.primaryTeal),
                              const SizedBox(width: 4),
                              const Text(
                                'Verified Facility',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hospital.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Specialist Chips
                const Text(
                  'Available Specialists / వైద్య నిపుణులు:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: hospital.specialists.map((spec) {
                    final isMatch = _getMatchingSpecialties(widget.conditionHint)
                        .any((m) => spec.toLowerCase().contains(m.toLowerCase()));
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMatch
                            ? AppTheme.primaryTealLight
                            : AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMatch
                              ? AppTheme.primaryTeal
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Text(
                        isMatch ? '⭐ $spec' : spec,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isMatch ? FontWeight.w800 : FontWeight.w500,
                          color: isMatch
                              ? AppTheme.primaryTealDark
                              : AppTheme.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Action Buttons Row: Call Helpline & Book Token
                Row(
                  children: [
                    // Phone Call button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: AppTheme.primaryTeal),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📞 Calling ${hospital.contactNumber}...'),
                              backgroundColor: AppTheme.primaryTeal,
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_rounded, size: 17, color: AppTheme.primaryTeal),
                        label: const Text(
                          'Call',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Book Token Button
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _onBookToken(hospital),
                        icon: const Icon(Icons.confirmation_num_rounded, size: 17),
                        label: const Text(
                          'Book Token',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
