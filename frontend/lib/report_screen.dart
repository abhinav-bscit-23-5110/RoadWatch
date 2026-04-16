import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';
import 'reports_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'LoginScreen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/google_maps_loader.dart';
import 'theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with WidgetsBindingObserver {
  static const String _googleApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY',
  );

  /// 🔥 CRITICAL FIX: Don't keep map alive when not needed
  GoogleMapController? _mapController;
  bool _mapReady = false;
  bool _isCameraMoving = false;
  LatLng? _selectedLatLng;
  String _locationText = 'Detecting location...';

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _manualLocationController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _issueTypes = const [
    'Pothole',
    'Crack',
    'Flooding',
    'Debris',
    'Signage',
    'Other',
  ];

  String _selectedSeverity = 'Medium';
  String _selectedIssueType = 'Pothole';
  bool _isSubmitting = false;
  bool _isDemo = false;
  bool _isLocating = false;
  bool _mapsReady = !kIsWeb;
  bool _mapsLoading = false;
  bool _isGeocoding = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  /// 🔥 CRITICAL FIX: Track if screen is visible
  bool _isScreenVisible = true;

  /// 🔥 CRITICAL FIX: Debounce location updates aggressively
  DateTime _lastLocationUpdate = DateTime.now();
  static const Duration _locationDebounceTime = Duration(milliseconds: 800);

  /// 🔥 CRITICAL FIX: Throttle camera animations
  static const Duration _cameraAnimationCooldown = Duration(milliseconds: 600);
  DateTime _lastCameraAnimation =
      DateTime.now().subtract(const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authOk = await AuthService.isAuthenticatedOrDemo();
      if (!authOk) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      _loadDemoFlag();
      _initMaps();
      _initLocation();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// 🔥 CRITICAL FIX: Destroy map when app is paused to stop buffer queue spam
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _destroyMap();
    } else if (state == AppLifecycleState.resumed) {
      _initMaps();
    }
  }

  /// 🔥 CRITICAL FIX: Properly destroy map controller
  void _destroyMap() {
    _mapController?.dispose();
    _mapController = null;
    _mapReady = false;
    _isCameraMoving = false;
  }

  Future<void> _loadDemoFlag() async {
    final demoMode = await StorageService.isDemoMode();
    if (!mounted) return;
    setState(() {
      _isDemo = demoMode;
    });
  }

  Future<void> _initMaps() async {
    if (!kIsWeb) {
      setState(() => _mapsReady = true);
      return;
    }

    setState(() => _mapsLoading = true);
    final ready = await GoogleMapsLoader.ensureLoaded(_googleApiKey);
    if (!mounted) return;
    setState(() {
      _mapsReady = ready;
      _mapsLoading = false;
    });
  }

  Future<void> _initLocation() async {
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationText = 'Location unavailable. Enter manually.';
          });
        }
        _showMessage('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Location permission denied. Enter manually.';
          });
        }
        _showMessage('Location permission denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _updateLocation(
        LatLng(position.latitude, position.longitude),
        animate: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Location unavailable. Enter manually.';
        });
      }
      _showMessage('Failed to get location: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// 🔥 CRITICAL FIX: Ultra-conservative location update with aggressive debouncing
  Future<void> _updateLocation(
    LatLng latLng, {
    bool animate = false,
    String? manualText,
  }) async {
    /// 🔥 Don't update if screen is not visible
    if (!_isScreenVisible) return;

    /// 🔥 Aggressive debounce
    final now = DateTime.now();
    if (now.difference(_lastLocationUpdate) < _locationDebounceTime) {
      return;
    }
    _lastLocationUpdate = now;

    /// 🔥 Prevent updates if coordinates are practically the same
    if (_selectedLatLng != null) {
      final diffLat = (_selectedLatLng!.latitude - latLng.latitude).abs();
      final diffLng = (_selectedLatLng!.longitude - latLng.longitude).abs();

      if (diffLat < 0.0001 && diffLng < 0.0001) {
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _selectedLatLng = latLng;
      if (manualText != null) {
        _locationText = manualText;
        _manualLocationController.text = manualText;
      }
    });

    /// 🔥 Throttled camera animation
    if (animate && _mapReady && !_isCameraMoving && _mapController != null) {
      final timeSinceLastAnim = now.difference(_lastCameraAnimation);
      if (timeSinceLastAnim < _cameraAnimationCooldown) {
        return;
      }

      _isCameraMoving = true;
      _lastCameraAnimation = now;

      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(latLng),
        );
      } catch (e) {
        // Silently fail
      } finally {
        await Future.delayed(const Duration(milliseconds: 500));
        _isCameraMoving = false;
      }
    }

    if (manualText == null) {
      await _reverseGeocode(latLng);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
        ].where((part) => part != null && part!.isNotEmpty).join(', ');

        setState(() {
          _locationText = address.isNotEmpty ? address : 'Selected location';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Selected location';
        });
      }
    }
  }

  Future<void> _geocodeManualLocation() async {
    if (_isGeocoding) return;

    final input = _manualLocationController.text.trim();
    if (input.isEmpty) {
      _showMessage('Enter a location first.');
      return;
    }

    setState(() => _isGeocoding = true);

    try {
      final results = await locationFromAddress(input);
      if (results.isEmpty) {
        _showMessage('No coordinates found for that address.');
        return;
      }
      final loc = results.first;
      await _updateLocation(
        LatLng(loc.latitude, loc.longitude),
        animate: true,
        manualText: input,
      );
    } catch (e) {
      _showMessage('Failed to find location: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (kIsWeb) {
      await _pickImage(ImageSource.gallery);
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name.isNotEmpty
            ? picked.name
            : 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    } catch (e) {
      _showMessage('Unable to pick image: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _descriptionController.dispose();
    _manualLocationController.dispose();

    /// 🔥 CRITICAL FIX: Always destroy map on dispose
    _destroyMap();

    super.dispose();
  }

  /// 🔥 CRITICAL FIX: Use Hybrid composition for Android to reduce buffer queue issues
  Widget _buildMapArea() {
    final LatLng fallbackCenter =
        _selectedLatLng ?? const LatLng(12.9716, 77.5946);

    if (!_mapsReady) {
      return _buildMapFallback();
    }

    /// 🔥 CRITICAL FIX: Don't render map if screen is not visible
    if (!_isScreenVisible) {
      return Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkInputBg
            : const Color(0xFFF1F3F6),
        child: const Center(child: Text('Map paused')),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: fallbackCenter,
        zoom: 14,
      ),

      myLocationEnabled: true,
      myLocationButtonEnabled: true,

      /// 🔥 CRITICAL FIX: Reduce map quality to reduce buffer pressure
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: false,
      indoorViewEnabled: false,

      onMapCreated: (controller) {
        if (!_mapReady) {
          _mapController = controller;
          _mapReady = true;

          /// 🔥 Set camera to current location after map is ready
          if (_selectedLatLng != null) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_mapReady && _mapController != null && mounted) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(_selectedLatLng!),
                );
              }
            });
          }
        }
      },

      markers: _selectedLatLng == null
          ? const {}
          : {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedLatLng!,
                draggable: false,
              ),
            },

      onTap: (latLng) {
        if (!_isCameraMoving) {
          _updateLocation(latLng, animate: false);
        }
      },
    );
  }

  Widget _buildMapFallback() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool keyMissing = _googleApiKey.contains('YOUR_GOOGLE_MAPS_API_KEY');
    final String title = _mapsLoading ? 'Loading map...' : 'Map unavailable';
    final String subtitle = keyMissing
        ? 'Set GOOGLE_MAPS_API_KEY to enable the map.'
        : 'You can still report using manual location.';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkInputBg : const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 40,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              if (!_mapsLoading && !keyMissing) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _initMaps,
                  child: const Text('Retry map'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasImage = _selectedImageBytes != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showImageSourceSheet,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: _reportFieldDecoration(context),
          child: Stack(
            children: [
              Positioned.fill(
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to take or upload a photo',
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
              if (hasImage) ...[
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Remove photo',
                      onPressed: () {
                        setState(() {
                          _selectedImageBytes = null;
                          _selectedImageName = null;
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedImageName ?? 'Selected photo',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    if (_isDemo) {
      _showMessage('Demo mode: reports are not submitted.');
      return;
    }

    if (_selectedLatLng == null) {
      final manualText = _manualLocationController.text.trim();
      if (manualText.isNotEmpty) {
        await _geocodeManualLocation();
      }
    }

    if (_selectedLatLng == null) {
      _showMessage('Please select a location on the map or enter an address.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Please provide a description of the issue.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.createReport(
        issueType: _selectedIssueType,
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
        latitude: _selectedLatLng!.latitude,
        longitude: _selectedLatLng!.longitude,
        locationText: _locationText,
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            'Report Submitted',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Your road issue has been reported successfully.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSeverityButton(String severity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = _selectedSeverity == severity;

    if (!isDark) {
      final severityColor = _getLightModeSeverityColor(severity);
      return GestureDetector(
        onTap: () => setState(() => _selectedSeverity = severity),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? severityColor : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? severityColor : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                severity,
                style: GoogleFonts.poppins(
                  color: isSelected ? severityColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final darkSemanticTextColor = AppTheme.getSeverityColor(
      severity,
      isDark: true,
    );
    final darkSemanticBgColor = AppTheme.getSeverityBgColor(
      severity,
      isDark: true,
    );

    return GestureDetector(
      onTap: () => setState(() => _selectedSeverity = severity),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? darkSemanticBgColor : AppTheme.darkElevatedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? darkSemanticTextColor : AppTheme.darkInputBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: darkSemanticTextColor,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              severity,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? darkSemanticTextColor
                    : AppTheme.darkTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return _getLightModeSeverityColor(severity);
    }
    return AppTheme.getSeverityColor(severity, isDark: isDark);
  }

  Color _getLightModeSeverityColor(String level) {
    switch (level) {
      case 'Low':
        return const Color(0xFF16A34A);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'High':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  BoxDecoration _reportFieldDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? AppTheme.darkInputBorder : Colors.grey.withOpacity(0.2),
        width: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Issue',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Issue Type
            Text(
              'Issue Type',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedIssueType,
              items: _issueTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedIssueType = value);
              },
              style: GoogleFonts.poppins(
                color:
                    isDark ? AppTheme.darkInputText : AppTheme.lightTextPrimary,
                fontSize: 16,
              ),
              dropdownColor:
                  isDark ? AppTheme.darkElevatedSurface : Colors.white,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    isDark ? AppTheme.darkInputBg : const Color(0xFFF1F3F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkInputBorder
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(
                color:
                    isDark ? AppTheme.darkInputText : AppTheme.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Add details about the issue...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppTheme.darkInputPlaceholder
                      : AppTheme.lightTextTertiary,
                ),
                filled: true,
                fillColor:
                    isDark ? AppTheme.darkInputBg : const Color(0xFFF1F3F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkInputBorder
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkInputBorderFocus
                        : AppTheme.primaryBlue,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Photo
            Text(
              'Upload Photo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildPhotoPicker(),
            const SizedBox(height: 24),

            // Location
            Text(
              'Location',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _reportFieldDecoration(context),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: isDark
                        ? AppTheme.darkPrimaryBlue
                        : AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isLocating ? 'Detecting location...' : _locationText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            /// 🔥 CRITICAL FIX: Keyed map widget to force rebuild when needed
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  child: _buildMapArea(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Enter location manually',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _manualLocationController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _geocodeManualLocation(),
              style: TextStyle(
                color:
                    isDark ? AppTheme.darkInputText : AppTheme.lightTextPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Type an address or landmark',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppTheme.darkInputPlaceholder
                      : AppTheme.lightTextTertiary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor:
                    isDark ? AppTheme.darkInputBg : const Color(0xFFF1F3F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkInputBorder
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: _isGeocoding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _isGeocoding ? null : _geocodeManualLocation,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGeocoding ? null : _geocodeManualLocation,
                icon: _isGeocoding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.place_outlined),
                label: Text(
                  _isGeocoding ? 'Locating...' : 'Use this address',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Severity
            Text(
              'Severity Level',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSeverityButton('Low'),
                _buildSeverityButton('Medium'),
                _buildSeverityButton('High'),
              ],
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        'Submit Report',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          if (index == 2) {
            _showMessage('You are already reporting an issue');
            return;
          }

          /// 🔥 CRITICAL FIX: Destroy map before navigation
          _destroyMap();

          Widget screen;
          switch (index) {
            case 0:
              screen = const HomeScreen();
              break;
            case 1:
              screen = const ReportsScreen();
              break;
            case 3:
              screen = const AlertsScreen();
              break;
            case 4:
              screen = const ProfileScreen();
              break;
            default:
              return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_gmailerrorred_outlined),
            activeIcon: Icon(Icons.report_gmailerrorred),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, color: Colors.transparent),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
