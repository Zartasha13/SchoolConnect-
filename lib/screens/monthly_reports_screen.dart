import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:typed_data';

class MonthlyReportsScreen extends StatefulWidget {
  const MonthlyReportsScreen({super.key});

  @override
  State<MonthlyReportsScreen> createState() => _MonthlyReportsScreenState();
}

class _MonthlyReportsScreenState extends State<MonthlyReportsScreen> {
  final _formKey = GlobalKey<FormState>();
  final totalDaysController = TextEditingController();
  final presentController = TextEditingController();
  final absentController = TextEditingController();
  final remarksController = TextEditingController();
  final cloudinary =
      CloudinaryPublic('dkjsza6pw', 'monthly_reports', cache: false);
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // State variables
  List<String> classesList = [
    "Class 1",
    "Class 2",
    "Class 3",
    "Class 4",
    "Class 5"
  ];
  String? selectedClass;
  String? selectedStudentId;
  String? selectedStudentName;
  String? selectedMonth;
  String? selectedPerformance;
  String? selectedHomework;
  String? selectedParticipation;

  List<String> classes = [];
  List<QueryDocumentSnapshot> students = [];
  List<XFile> _selectedImages = [];
  bool isLoadingStudents = false;
  bool isSaving = false;
  // Design Constants
  final Color primaryBlue = const Color(0xFF1746A2);
  final Color successGreen = const Color(0xFF166534);

  List<String> getMonthsList() {
    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months;
  }

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .get();

    Set<String> uniqueClasses = {};
    for (var doc in snapshot.docs) {
      if (doc.data() is Map && (doc.data() as Map).containsKey('class')) {
        uniqueClasses.add(doc['class']);
      }
    }

    setState(() {
      classes = uniqueClasses.toList()..sort();
    });
  }

  Future<void> loadStudents(String className) async {
    setState(() {
      isLoadingStudents = true;
      students = [];
      selectedStudentId = null;
    });

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('class', isEqualTo: className)
        .get();

    setState(() {
      students = snapshot.docs;
      isLoadingStudents = false;
    });
  }

  Future<void> sendReport() async {
    // 1. Validation Check
    if (!_formKey.currentState!.validate()) return;

    // Student selection check
    if (selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a student!"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => isSaving = true);

    try {
      List<String> uploadedImageUrls = [];

      for (var image in _selectedImages) {
        final bytes = await image.readAsBytes();

        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromByteData(
            // Try this method
            bytes.buffer.asByteData(),
            identifier: image.name,
            resourceType: CloudinaryResourceType.Image,
            folder: 'monthly_reports',
          ),
        );
        uploadedImageUrls.add(response.secureUrl);
      }

      // 3. Firestore Data Save
      await FirebaseFirestore.instance.collection('monthly_reports').add({
        'studentId': selectedStudentId,
        'studentName': selectedStudentName,
        'class': selectedClass,
        'month': selectedMonth,
        'overallPerformance': selectedPerformance,
        'homeworkCompletion': selectedHomework,
        'classParticipation': selectedParticipation,
        'totalDays': totalDaysController.text,
        'presentDays': presentController.text,
        'absentDays': absentController.text,
        'remarks': remarksController.text,
        'attachmentUrls': uploadedImageUrls, // List of URLs save hogi
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Fields Reset Logic
      _formKey.currentState!.reset();

      totalDaysController.clear();
      presentController.clear();
      absentController.clear();
      remarksController.clear();

      setState(() {
        _selectedImages = []; // Images list clear karein
        selectedClass = null;
        selectedStudentId = null;
        selectedStudentName = null;
        selectedMonth = null;
        selectedPerformance = null;
        selectedHomework = null;
        selectedParticipation = null;
        students = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Monthly Report Sent Successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  final List<PlatformFile> _selectedFiles = [];
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Monthly Reports",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          // Validation sirf button click par hogi
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Student & Report Month"),
              _buildCard([
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: "Select Class", border: OutlineInputBorder()),
                  items: classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedClass = val);
                      loadStudents(val);
                      // validate() hata diya
                    }
                  },
                  validator: (v) => v == null ? "Required" : null,
                ),
                const SizedBox(height: 15),
                isLoadingStudents
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        initialValue: selectedStudentId,
                        decoration: InputDecoration(
                          labelText: "Select Student",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        items: students.map((student) {
                          return DropdownMenuItem(
                            value: student.id,
                            child: Text(
                                "${student['name']} (${student['rollNo']})"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final student =
                                students.firstWhere((s) => s.id == value);
                            setState(() {
                              selectedStudentId = value;
                              selectedStudentName = student['name'];
                            });
                            // validate() hata diya
                          }
                        },
                        validator: (v) =>
                            v == null ? "Please select a student" : null,
                      ),
                const SizedBox(height: 15),
                _buildDropdown("Select Month", getMonthsList(), (val) {
                  setState(() => selectedMonth = val);
                  // validate() hata diya
                }),
              ]),
              _buildSectionTitle("Academic Performance"),
              _buildCard([
                _buildDropdown(
                  "Overall Performance",
                  ["Excellent", "Good", "Average"],
                  (val) => setState(() => selectedPerformance = val),
                ),
                const SizedBox(height: 15),
                _buildDropdown(
                  "Homework Completion",
                  ["Always", "Mostly", "Rarely"],
                  (val) => setState(() => selectedHomework = val),
                ),
                const SizedBox(height: 15),
                _buildDropdown(
                  "Class Participation",
                  ["Active", "Moderate", "Low"],
                  (val) => setState(() => selectedParticipation = val),
                ),
              ]),
              _buildSectionTitle("Attendance & Remarks"),
              _buildCard([
                Row(children: [
                  Expanded(
                      child:
                          _buildTextField("Total Days", totalDaysController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child:
                          _buildTextField("Present Days", presentController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildTextField("Absent Days", absentController)),
                ]),
                const SizedBox(height: 15),
                TextFormField(
                  controller: remarksController,
                  maxLines: 3,
                  decoration: InputDecoration(
                      labelText: "Teacher Remarks",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter remarks' : null,
                ),
              ]),
              const SizedBox(height: 10),
              _buildSectionTitle("Attachments (Optional)"),
              _buildCard([
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text("Select Multiple Images"),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _selectedImages.map((image) {
                    return Stack(
                      children: [
                        FutureBuilder<Uint8List>(
                          future: image.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.data != null) {
                              return Image.memory(snapshot.data!,
                                  width: 80, height: 80, fit: BoxFit.cover);
                            }
                            return const SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator());
                          },
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () =>
                                setState(() => _selectedImages.remove(image)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ]),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text("Draft saved!"))),
                          child: const Text("Save Draft"))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: successGreen,
                          foregroundColor: Colors.white),
                      onPressed: isSaving
                          ? null
                          : () {
                              // Yahan validation trigger hogi
                              if (_formKey.currentState!.validate()) {
                                sendReport();
                              }
                            },
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Send Report"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDropdown(
      String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      // Validation add ki
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select $label' : null,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required'; // Ye error red text mein dikhayega
        }
        return null;
      },
    );
  }
}
