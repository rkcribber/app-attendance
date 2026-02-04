import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const List<Color> themeColors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Color(0xFF1A1A2E), // Dark theme
  ];

  Color _themeColor = Colors.deepPurple;
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadThemeColor();
  }

  Future<void> _loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    int colorIndex = prefs.getInt('themeColorIndex') ?? 0;
    // Ensure color index is within bounds
    if (colorIndex < 0 || colorIndex >= themeColors.length) {
      colorIndex = 0;
    }
    setState(() {
      _themeColor = themeColors[colorIndex];
      _isDarkTheme = colorIndex == themeColors.length - 1; // Last color is dark thgit remote add origin https://github.com/rkcribber/app-attendanceeme
    });
  }

  void updateThemeColor(Color color) {
    setState(() {
      _themeColor = color;
      _isDarkTheme = color == themeColors.last; // Dark theme is the last color
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haaziri',
      theme: _isDarkTheme 
        ? ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueGrey.shade300,
              secondary: Colors.blueGrey.shade200,
              surface: const Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
          )
        : ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: _themeColor),
            useMaterial3: true,
          ),
      home: MyHomePage(
        title: 'Haaziri',
        onThemeChanged: updateThemeColor,
        themeColors: themeColors,
        currentThemeColor: _themeColor,
      ),
    );
  }
}

// Enum for attendance status
enum AttendanceStatus { none, present, absent, cancelled, bunk }

// Model for location data
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
  });
}

// Model for subject attendance
class SubjectAttendance {
  final String subjectName;
  AttendanceStatus status;
  String? photoPath;
  LocationData? location;

  SubjectAttendance({
    required this.subjectName,
    this.status = AttendanceStatus.none,
    this.photoPath,
    this.location,
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.onThemeChanged,
    required this.themeColors,
    required this.currentThemeColor,
  });

  final String title;
  final Function(Color) onThemeChanged;
  final List<Color> themeColors;
  final Color currentThemeColor;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime selectedDate = DateTime.now();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  // Store attendance data by date
  final Map<String, List<SubjectAttendance>> _attendanceData = {};

  // Subject names - now editable and persistent
  List<String> subjectNames = [
    'Subject 1',
    'Subject 2',
    'Subject 3',
    'Subject 4',
    'Subject 5',
  ];

  // Profile data
  String _profileName = '';
  String _profileContact = '';
  String _profileEmail = '';
  String _profileCollege = '';
  String _profileAdmissionNo = '';
  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    _loadSubjectNames();
    _loadProfileData();
  }

  // Load profile data from persistent storage
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileName = prefs.getString('profileName') ?? '';
      _profileContact = prefs.getString('profileContact') ?? '';
      _profileEmail = prefs.getString('profileEmail') ?? '';
      _profileCollege = prefs.getString('profileCollege') ?? '';
      _profileAdmissionNo = prefs.getString('profileAdmissionNo') ?? '';
      _profilePicturePath = prefs.getString('profilePicturePath');
    });
  }

  // Save profile data to persistent storage
  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileName', _profileName);
    await prefs.setString('profileContact', _profileContact);
    await prefs.setString('profileEmail', _profileEmail);
    await prefs.setString('profileCollege', _profileCollege);
    await prefs.setString('profileAdmissionNo', _profileAdmissionNo);
    if (_profilePicturePath != null) {
      await prefs.setString('profilePicturePath', _profilePicturePath!);
    }
  }

  // Save theme color to persistent storage
  Future<void> _saveThemeColor(int colorIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColorIndex', colorIndex);
  }

  // College options
  static const List<String> collegeOptions = ['LSR', 'KNC', 'JIIT', 'SRCC'];

  // Validate email format
  bool _isValidEmail(String email) {
    if (email.isEmpty) return true; // Allow empty
    final pattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.(com|edu|gov\.edu|gov\.in)$');
    return pattern.hasMatch(email);
  }

  // Validate contact number (exactly 10 digits)
  bool _isValidContact(String contact) {
    if (contact.isEmpty) return true; // Allow empty
    final pattern = RegExp(r'^\d{10}$');
    return pattern.hasMatch(contact);
  }

  // Show profile popup
  void _showProfilePopup() {
    final nameController = TextEditingController(text: _profileName);
    final contactController = TextEditingController(text: _profileContact);
    final emailController = TextEditingController(text: _profileEmail);
    final admissionController = TextEditingController(text: _profileAdmissionNo);
    String? tempProfilePicture = _profilePicturePath;
    String? selectedCollege = _profileCollege.isNotEmpty ? _profileCollege : null;
    String? contactError;
    String? emailError;
    int selectedThemeColorIndex = widget.themeColors.indexOf(widget.currentThemeColor);
    if (selectedThemeColorIndex < 0) selectedThemeColorIndex = 0;
    final int originalThemeColorIndex = selectedThemeColorIndex;

    showDialog(
      context: context,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (didPop, result) {
          // If dialog is closed without saving, revert to original color
          if (didPop && result != true) {
            widget.onThemeChanged(widget.themeColors[originalThemeColorIndex]);
          }
        },
        child: StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          // Revert to original color
                          widget.onThemeChanged(widget.themeColors[originalThemeColorIndex]);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: () async {
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              // Copy to app documents for persistence
                              final appDir = await getApplicationDocumentsDirectory();
                              final fileName = 'profile_picture.jpg';
                              final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
                              setDialogState(() {
                                tempProfilePicture = savedImage.path;
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.deepPurple.shade100,
                                backgroundImage: tempProfilePicture != null
                                    ? FileImage(File(tempProfilePicture!))
                                    : null,
                                child: tempProfilePicture == null
                                    ? const Icon(Icons.face, size: 50, color: Colors.deepPurple)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to change photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name Field
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Contact Field with validation
                        TextField(
                          controller: contactController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value.isNotEmpty && !_isValidContact(value)) {
                                contactError = 'Must be exactly 10 digits';
                              } else {
                                contactError = null;
                              }
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: const OutlineInputBorder(),
                            counterText: '',
                            errorText: contactError,
                            helperText: 'Enter 10 digit mobile number',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Email Field with validation
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value.isNotEmpty && !_isValidEmail(value)) {
                                emailError = 'Must end with .com, .edu, .gov.edu, or .gov.in';
                              } else {
                                emailError = null;
                              }
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: const OutlineInputBorder(),
                            errorText: emailError,
                            helperText: 'e.g. name@college.edu',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // College Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: selectedCollege,
                          decoration: const InputDecoration(
                            labelText: 'College Name',
                            prefixIcon: Icon(Icons.school_outlined),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select your college'),
                          items: collegeOptions.map((college) {
                            return DropdownMenuItem(
                              value: college,
                              child: Text(college),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCollege = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Admission Number Field
                        TextField(
                          controller: admissionController,
                          decoration: const InputDecoration(
                            labelText: 'Admission Number',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Theme Color Selector
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'App Theme Color',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tap to preview, save to keep',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: widget.themeColors.asMap().entries.map((entry) {
                            final index = entry.key;
                            final color = entry.value;
                            final isSelected = selectedThemeColorIndex == index;
                            final isDarkThemeColor = index == widget.themeColors.length - 1;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedThemeColorIndex = index;
                                });
                                // Preview the theme immediately
                                widget.onThemeChanged(color);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? (isDarkThemeColor ? Colors.white : Colors.black) : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isDarkThemeColor
                                    ? Icon(
                                        isSelected ? Icons.check : Icons.dark_mode,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : (isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                                        : null),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Validate before saving
                        final contact = contactController.text.trim();
                        final email = emailController.text.trim();
                        
                        if (contact.isNotEmpty && !_isValidContact(contact)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact number must be exactly 10 digits'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (email.isNotEmpty && !_isValidEmail(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email must end with .com, .edu, .gov.edu, or .gov.in'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _profileName = nameController.text.trim();
                          _profileContact = contact;
                          _profileEmail = email;
                          _profileCollege = selectedCollege ?? '';
                          _profileAdmissionNo = admissionController.text.trim();
                          _profilePicturePath = tempProfilePicture;
                        });
                        await _saveProfileData();
                        
                        // Save and apply theme color
                        await _saveThemeColor(selectedThemeColorIndex);
                        widget.onThemeChanged(widget.themeColors[selectedThemeColorIndex]);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile saved successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // Load subject names from persistent storage
  Future<void> _loadSubjectNames() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSubjects = prefs.getStringList('subjectNames');
    if (savedSubjects != null && savedSubjects.isNotEmpty) {
      setState(() {
        subjectNames = savedSubjects;
      });
    }
    _initializeDateAttendance(selectedDate);
    setState(() {
      _isLoading = false;
    });
  }

  // Save subject names to persistent storage
  Future<void> _saveSubjectNames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subjectNames', subjectNames);
  }

  // Edit a subject name
  void _editSubjectName(int index) {
    final controller = TextEditingController(text: subjectNames[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subject Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final oldName = subjectNames[index];
                  subjectNames[index] = controller.text.trim();
                  // Update attendance data for all dates
                  _attendanceData.forEach((dateKey, attendanceList) {
                    for (var attendance in attendanceList) {
                      if (attendance.subjectName == oldName) {
                        // We need to create a new SubjectAttendance since subjectName is final
                        final idx = attendanceList.indexOf(attendance);
                        attendanceList[idx] = SubjectAttendance(
                          subjectName: controller.text.trim(),
                          status: attendance.status,
                          photoPath: attendance.photoPath,
                          location: attendance.location,
                        );
                      }
                    }
                  });
                });
                _saveSubjectNames();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subject name updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Add a new subject
  void _addSubject() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject Name',
            hintText: 'Enter subject name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  subjectNames.add(controller.text.trim());
                  // Add to all existing attendance data
                  _attendanceData.forEach((dateKey, attendanceList) {
                    attendanceList.add(SubjectAttendance(
                      subjectName: controller.text.trim(),
                    ));
                  });
                });
                _saveSubjectNames();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Subject "${controller.text.trim()}" added!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Delete a subject
  void _deleteSubject(int index) {
    final subjectName = subjectNames[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "$subjectName"?\n\nThis will remove all attendance records for this subject.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                subjectNames.removeAt(index);
                // Remove from all attendance data
                _attendanceData.forEach((dateKey, attendanceList) {
                  attendanceList.removeWhere((a) => a.subjectName == subjectName);
                });
              });
              _saveSubjectNames();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Subject "$subjectName" deleted!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Show subject management bottom sheet
  void _showSubjectManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manage Subjects',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: subjectNames.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(subjectNames[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.pop(context);
                            _editSubjectName(index);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteSubject(index);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _addSubject();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Subject'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _initializeDateAttendance(DateTime date) {
    String dateKey = _getDateKey(date);
    if (!_attendanceData.containsKey(dateKey)) {
      _attendanceData[dateKey] = subjectNames
          .map((name) => SubjectAttendance(subjectName: name))
          .toList();
    }
  }

  List<SubjectAttendance> get currentDayAttendance {
    String dateKey = _getDateKey(selectedDate);
    _initializeDateAttendance(selectedDate);
    return _attendanceData[dateKey]!;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _initializeDateAttendance(picked);
      });
    }
  }

  Future<LocationData?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Try to get address from coordinates
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        }
      } catch (e) {
        // Address lookup failed, but we still have coordinates
        address = null;
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _takePhoto(int subjectIndex) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) {
      // Get GPS location when taking photo
      final location = await _getCurrentLocation();
      
      setState(() {
        currentDayAttendance[subjectIndex].photoPath = photo.path;
        currentDayAttendance[subjectIndex].location = location;
      });

      // Show confirmation with location
      if (mounted && location != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo saved with GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery(int subjectIndex) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (photo != null) {
      // Get GPS location when selecting photo
      final location = await _getCurrentLocation();
      
      setState(() {
        currentDayAttendance[subjectIndex].photoPath = photo.path;
        currentDayAttendance[subjectIndex].location = location;
      });

      // Show confirmation with location
      if (mounted && location != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo saved with GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _setAttendanceStatus(int subjectIndex, AttendanceStatus status) {
    setState(() {
      currentDayAttendance[subjectIndex].status = status;
    });
  }

  void _showPhotoOptions(int subjectIndex) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(subjectIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(subjectIndex);
                },
              ),
              if (currentDayAttendance[subjectIndex].photoPath != null)
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('View Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _viewPhoto(subjectIndex);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _viewPhoto(int subjectIndex) {
    final photoPath = currentDayAttendance[subjectIndex].photoPath;
    if (photoPath != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(currentDayAttendance[subjectIndex].subjectName),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Image.file(
                File(photoPath),
                fit: BoxFit.contain,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Show Overall Attendance Calculator
  void _showOverallAttendanceCalculator() {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();
    bool hasCalculated = false;
    
    // Stats variables
    Map<String, Map<String, int>> subjectStats = {};
    int totalPresent = 0;
    int totalAbsent = 0;
    int totalBunk = 0;
    int totalCancelled = 0;
    int totalClasses = 0;
    double overallPercentage = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          
          // Function to calculate attendance
          void calculateAttendance() {
            // Reset stats
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            subjectStats = {};
            totalPresent = 0;
            totalAbsent = 0;
            totalBunk = 0;
            totalCancelled = 0;
            totalClasses = 0;

            // Initialize subject stats
            for (var subjectName in subjectNames) {
              subjectStats[subjectName] = {
                'present': 0,
                'absent': 0,
                'bunk': 0,
                'cancelled': 0,
                'total': 0,
              };
            }

            // Iterate through all dates in range
            for (DateTime date = startDate;
                date.isBefore(endDate.add(const Duration(days: 1)));
                date = date.add(const Duration(days: 1))) {
              String dateKey = DateFormat('yyyy-MM-dd').format(date);
              if (_attendanceData.containsKey(dateKey)) {
                for (var attendance in _attendanceData[dateKey]!) {
                  if (subjectStats.containsKey(attendance.subjectName)) {
                    switch (attendance.status) {
                      case AttendanceStatus.present:
                        subjectStats[attendance.subjectName]!['present'] =
                            subjectStats[attendance.subjectName]!['present']! + 1;
                        totalPresent++;
                        subjectStats[attendance.subjectName]!['total'] =
                            subjectStats[attendance.subjectName]!['total']! + 1;
                        totalClasses++;
                        break;
                      case AttendanceStatus.absent:
                        subjectStats[attendance.subjectName]!['absent'] =
                            subjectStats[attendance.subjectName]!['absent']! + 1;
                        totalAbsent++;
                        subjectStats[attendance.subjectName]!['total'] =
                            subjectStats[attendance.subjectName]!['total']! + 1;
                        totalClasses++;
                        break;
                      case AttendanceStatus.bunk:
                        subjectStats[attendance.subjectName]!['bunk'] =
                            subjectStats[attendance.subjectName]!['bunk']! + 1;
                        totalBunk++;
                        subjectStats[attendance.subjectName]!['total'] =
                            subjectStats[attendance.subjectName]!['total']! + 1;
                        totalClasses++;
                        break;
                      case AttendanceStatus.cancelled:
                        subjectStats[attendance.subjectName]!['cancelled'] =
                            subjectStats[attendance.subjectName]!['cancelled']! + 1;
                        totalCancelled++;
                        break;
                      case AttendanceStatus.none:
                        break;
                    }
                  }
                }
              }
            }

            overallPercentage = totalClasses > 0
                ? (totalPresent / totalClasses) * 100
                : 0;

            setModalState(() {
              hasCalculated = true;
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Overall Attendance',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Range Selection
                        const Text(
                          'Select Date Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2024),
                                    lastDate: endDate,
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      startDate = picked;
                                      hasCalculated = false; // Reset calculation when date changes
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(startDate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: endDate,
                                    firstDate: startDate,
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      endDate = picked;
                                      hasCalculated = false; // Reset calculation when date changes
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(endDate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Calculate Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: calculateAttendance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.calculate),
                            label: Text(
                              hasCalculated ? 'Recalculate' : 'Calculate Attendance',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Show results only after calculation
                        if (hasCalculated) ...[
                          // Overall Summary Card
                          Card(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text(
                                    'Overall Attendance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${overallPercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: overallPercentage >= 75
                                              ? Colors.green
                                              : overallPercentage >= 50
                                                  ? Colors.orange
                                                  : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$totalPresent present out of $totalClasses classes',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildOverallStat('Present', totalPresent, Colors.green),
                                      _buildOverallStat('Absent', totalAbsent, Colors.red),
                                      _buildOverallStat('Bunk', totalBunk, Colors.purple),
                                      _buildOverallStat('Cancelled', totalCancelled, Colors.orange),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Per Subject Breakdown
                          const Text(
                            'Subject-wise Attendance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...subjectNames.map((subjectName) {
                            final stats = subjectStats[subjectName]!;
                            final total = stats['total']!;
                            final present = stats['present']!;
                            final percentage = total > 0 ? (present / total) * 100 : 0.0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          subjectName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: percentage >= 75
                                                ? Colors.green
                                                : percentage >= 50
                                                    ? Colors.orange
                                                    : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: total > 0 ? present / total : 0,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation(
                                          percentage >= 75
                                              ? Colors.green
                                              : percentage >= 50
                                                  ? Colors.orange
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'P: ${stats['present']}  A: ${stats['absent']}  B: ${stats['bunk']}  C: ${stats['cancelled']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          'Total: $total classes',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ] else ...[
                          // Placeholder when not calculated
                          Container(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Select date range and tap "Calculate Attendance"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Save as PDF Button (only show after calculation)
                if (hasCalculated)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _saveOverallAttendancePdf(
                          startDate,
                          endDate,
                          subjectStats,
                          totalPresent,
                          totalAbsent,
                          totalBunk,
                          totalCancelled,
                          totalClasses,
                          overallPercentage,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text(
                          'Save Report as PDF',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallStat(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  // Save Overall Attendance as PDF
  Future<void> _saveOverallAttendancePdf(
    DateTime startDate,
    DateTime endDate,
    Map<String, Map<String, int>> subjectStats,
    int totalPresent,
    int totalAbsent,
    int totalBunk,
    int totalCancelled,
    int totalClasses,
    double overallPercentage,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      final pdf = pw.Document();
      final startDateStr = DateFormat('MMM d, yyyy').format(startDate);
      final endDateStr = DateFormat('MMM d, yyyy').format(endDate);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            List<pw.Widget> content = [];

            // Header
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.deepPurple50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OVERALL ATTENDANCE REPORT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Period: $startDateStr - $endDateStr',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    if (_profileName.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Student: $_profileName',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                    if (_profileCollege.isNotEmpty) ...[
                      pw.Text(
                        'College: $_profileCollege',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            );

            content.add(pw.SizedBox(height: 20));

            // Overall Summary
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Overall Attendance: ${overallPercentage.toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: overallPercentage >= 75
                            ? PdfColors.green
                            : overallPercentage >= 50
                                ? PdfColors.orange
                                : PdfColors.red,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '$totalPresent present out of $totalClasses classes',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildPdfStat('Present', totalPresent, PdfColors.green),
                        _buildPdfStat('Absent', totalAbsent, PdfColors.red),
                        _buildPdfStat('Bunk', totalBunk, PdfColors.purple),
                        _buildPdfStat('Cancelled', totalCancelled, PdfColors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            );

            content.add(pw.SizedBox(height: 24));

            // Subject-wise Table
            content.add(
              pw.Text(
                'Subject-wise Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );

            content.add(pw.SizedBox(height: 12));

            // Table
            content.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Subject', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Present', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Absent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Bunk', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...subjectNames.map((subjectName) {
                    final stats = subjectStats[subjectName]!;
                    final total = stats['total']!;
                    final present = stats['present']!;
                    final percentage = total > 0 ? (present / total) * 100 : 0.0;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(subjectName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${stats['present']}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${stats['absent']}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${stats['bunk']}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('$total'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              color: percentage >= 75
                                  ? PdfColors.green
                                  : percentage >= 50
                                      ? PdfColors.orange
                                      : PdfColors.red,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );

            return content;
          },
        ),
      );

      // Save PDF
      final output = await getApplicationDocumentsDirectory();
      final fileName = 'Attendance_Report_${DateFormat('yyyy-MM-dd').format(startDate)}_to_${DateFormat('yyyy-MM-dd').format(endDate)}.pdf';
      final filePath = '${output.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success dialog
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Report Saved!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your attendance report has been saved.'),
              const SizedBox(height: 12),
              Text(
                'File: $fileName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await OpenFile.open(filePath);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                Share.shareXFiles(
                  [XFile(filePath)],
                  subject: 'Attendance Report $startDateStr - $endDateStr',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }  // Calculate statistics
  Map<String, int> _getStatistics() {
    int present = 0;
    int absent = 0;
    int cancelled = 0;
    int bunk = 0;
    int notMarked = 0;

    for (var attendance in currentDayAttendance) {
      switch (attendance.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.cancelled:
          cancelled++;
          break;
        case AttendanceStatus.bunk:
          bunk++;
          break;
        case AttendanceStatus.none:
          notMarked++;
          break;
      }
    }

    return {
      'present': present,
      'absent': absent,
      'cancelled': cancelled,
      'bunk': bunk,
      'notMarked': notMarked,
    };
  }

  String _getStatusTextForPdf(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.cancelled:
        return 'CANCELLED';
      case AttendanceStatus.bunk:
        return 'BUNK';
      case AttendanceStatus.none:
        return 'NOT MARKED';
    }
  }

  PdfColor _getStatusColorForPdf(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return PdfColors.green;
      case AttendanceStatus.absent:
        return PdfColors.red;
      case AttendanceStatus.cancelled:
        return PdfColors.orange;
      case AttendanceStatus.bunk:
        return PdfColors.purple;
      case AttendanceStatus.none:
        return PdfColors.grey;
    }
  }

  Future<void> _saveAttendanceRecord() async {
    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      final pdf = pw.Document();
      final stats = _getStatistics();
      final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(selectedDate);

      // Pre-load all images
      final List<pw.Widget> subjectCards = [];
      for (var subject in currentDayAttendance) {
        subjectCards.add(await _buildSubjectPdfCard(subject));
      }

      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            List<pw.Widget> content = [];

            // Header
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.deepPurple50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MY ATTENDANCE RECORD',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      dateStr,
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            );

            content.add(pw.SizedBox(height: 20));

            // Summary Box
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfStat('Present', stats['present']!, PdfColors.green),
                    _buildPdfStat('Absent', stats['absent']!, PdfColors.red),
                    _buildPdfStat('Cancelled', stats['cancelled']!, PdfColors.orange),
                    _buildPdfStat('Pending', stats['notMarked']!, PdfColors.grey),
                  ],
                ),
              ),
            );

            content.add(pw.SizedBox(height: 24));

            // Section Title
            content.add(
              pw.Text(
                'CLASS DETAILS',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );

            content.add(pw.SizedBox(height: 12));

            // Add pre-built subject cards
            for (var card in subjectCards) {
              content.add(card);
              content.add(pw.SizedBox(height: 16));
            }

            return content;
          },
        ),
      );

      // Save PDF to app documents directory
      final output = await getApplicationDocumentsDirectory();
      final fileName = 'Attendance_${DateFormat('yyyy-MM-dd').format(selectedDate)}.pdf';
      final filePath = '${output.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success dialog with options
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('PDF Saved!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your attendance record has been saved.'),
              const SizedBox(height: 12),
              Text(
                'File: $fileName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Location: ${output.path}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                // Open PDF directly - user can then save from PDF viewer
                await OpenFile.open(filePath);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Share sheet - tap "Save to Files" and choose "On My iPhone/iPad"
                Share.shareXFiles(
                  [XFile(filePath)],
                  subject: 'Attendance Record - $dateStr',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share/Save'),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text('Failed to save PDF: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  pw.Widget _buildPdfStat(String label, int count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 40,
          height: 40,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              count.toString(),
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<pw.Widget> _buildSubjectPdfCard(SubjectAttendance subject) async {
    List<pw.Widget> cardContent = [];

    // Subject header with status
    cardContent.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.only(
            topLeft: pw.Radius.circular(8),
            topRight: pw.Radius.circular(8),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              subject.subjectName,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _getStatusColorForPdf(subject.status),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                _getStatusTextForPdf(subject.status),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Photo proof section
    if (subject.photoPath != null) {
      try {
        final imageFile = File(subject.photoPath!);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          final image = pw.MemoryImage(imageBytes);

          cardContent.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Photo Proof:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(image, height: 200, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
            ),
          );
        } else {
          cardContent.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(
                'Photo file not found',
                style: const pw.TextStyle(color: PdfColors.red),
              ),
            ),
          );
        }
      } catch (e) {
        cardContent.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text(
              'Photo could not be loaded: $e',
              style: const pw.TextStyle(color: PdfColors.red),
            ),
          ),
        );
      }
    } else {
      cardContent.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(
            'No photo proof attached',
            style: const pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // GPS Location section
    if (subject.location != null) {
      cardContent.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(8),
              bottomRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GPS Location:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Latitude: ${subject.location!.latitude.toStringAsFixed(6)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Longitude: ${subject.location!.longitude.toStringAsFixed(6)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (subject.location!.address != null)
                pw.Text(
                  'Address: ${subject.location!.address}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              pw.Text(
                'Captured: ${DateFormat('MMM d, yyyy HH:mm:ss').format(subject.location!.timestamp)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Google Maps: https://maps.google.com/?q=${subject.location!.latitude},${subject.location!.longitude}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: cardContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStatistics();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            onTap: _showProfilePopup,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage: _profilePicturePath != null
                    ? FileImage(File(_profilePicturePath!))
                    : null,
                child: _profilePicturePath == null
                    ? const Icon(Icons.face, color: Colors.deepPurple, size: 28)
                    : null,
              ),
            ),
          ),
        ),
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.auto_stories, size: 30),
              tooltip: 'Manage Subjects',
              onPressed: _showSubjectManagement,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker Card
                Card(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 32, color: Colors.deepPurple),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Date',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 32),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Today's Summary Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Summary",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat('Present', stats['present']!, Colors.green),
                        _buildMiniStat('Absent', stats['absent']!, Colors.red),
                        _buildMiniStat('Cancelled', stats['cancelled']!, Colors.orange),
                        _buildMiniStat('Bunk', stats['bunk']!, Colors.purple),
                        _buildMiniStat('Pending', stats['notMarked']!, Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Subjects Header
            Text(
              "Today's Schedule",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Subject Cards
            ...List.generate(currentDayAttendance.length, (index) {
              final subject = currentDayAttendance[index];
              return _buildSubjectCard(context, subject, index);
            }),

            const SizedBox(height: 20),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Take a photo as proof of your attendance. This helps if your professor marks attendance incorrectly.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveAttendanceRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  'Save & Share as PDF',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Calculate Overall Attendance Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _showOverallAttendanceCalculator,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'Calculate Overall Attendance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectAttendance subject, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subject.subjectName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                // Photo and GPS indicator
                Row(
                  children: [
                    if (subject.location != null)
                      GestureDetector(
                        onTap: () => _showLocationDetails(subject),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'GPS',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (subject.photoPath != null)
                      GestureDetector(
                        onTap: () => _viewPhoto(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Photo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons Row - all 4 buttons with labels
            Row(
              children: [
                Expanded(
                  child: _buildStatusButton(
                    'Present',
                    subject.status == AttendanceStatus.present,
                    Colors.green,
                    () => _setAttendanceStatus(index, AttendanceStatus.present),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'Absent',
                    subject.status == AttendanceStatus.absent,
                    Colors.red,
                    () => _setAttendanceStatus(index, AttendanceStatus.absent),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'Cancelled',
                    subject.status == AttendanceStatus.cancelled,
                    Colors.orange,
                    () => _setAttendanceStatus(index, AttendanceStatus.cancelled),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatusButton(
                    'Bunk',
                    subject.status == AttendanceStatus.bunk,
                    Colors.purple,
                    () => _setAttendanceStatus(index, AttendanceStatus.bunk),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Photo Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showPhotoOptions(index),
                icon: Icon(
                  subject.photoPath != null ? Icons.photo_camera : Icons.add_a_photo,
                ),
                label: Text(
                  subject.photoPath != null ? 'Update Photo Proof' : 'Add Photo Proof',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String label,
    bool isSelected,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showLocationDetails(SubjectAttendance subject) {
    if (subject.location == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('GPS Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${subject.location!.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${subject.location!.longitude.toStringAsFixed(6)}'),
            if (subject.location!.address != null) ...[
              const SizedBox(height: 8),
              Text('Address: ${subject.location!.address}'),
            ],
            const SizedBox(height: 8),
            Text(
              'Captured: ${DateFormat('MMM d, yyyy HH:mm:ss').format(subject.location!.timestamp)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
