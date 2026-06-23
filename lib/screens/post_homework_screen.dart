import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:school_connect/screens/homewokr_list_screen.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class PostHomeworkScreen extends StatefulWidget {
  const PostHomeworkScreen({super.key});

  @override
  State<PostHomeworkScreen> createState() => _PostHomeworkScreenState();
}

class _PostHomeworkScreenState extends State<PostHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final cloudinary = CloudinaryPublic('dkjsza6pw', 'ml_default', cache: false);

  String? teacherClass;
  String? selectedSubject;
  DateTime? assignedDate;
  DateTime? dueDate;
  bool isLoading = false;

  List<PlatformFile> pickedFiles = [];
  final List<String> subjects = [
    "Mathematics",
    "Physics",
    "Chemistry",
    "Biology",
    "English",
    "Urdu",
    "Computer Science",
    "History",
    "Islamiyat"
  ];

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            teacherClass = doc.data()?['class'] ?? "N/A";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true, // Web ke liye zaroori
    );

    if (result != null) {
      List<PlatformFile> validFiles = [];
      for (var file in result.files) {
        if (file.size <= 10 * 1024 * 1024) {
          validFiles.add(file);
        }
      }
      setState(() => pickedFiles.addAll(validFiles));
    }
  }

  Future<void> _pickDate(bool isAssigned) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isAssigned) {
          assignedDate = picked;
        } else {
          dueDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Homework"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: "View My Homework",
            onPressed: () {
              // Yahan apni 'TeacherHomeworkListScreen' ka naam likhein
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TeacherHomeworkListScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("Class Information", Icons.school),
                    _buildReadOnlyField(
                        "Assigned Class", teacherClass ?? "Loading..."),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                          labelText: "Select Subject *",
                          border: OutlineInputBorder()),
                      items: subjects
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedSubject = val),
                      validator: (val) => val == null ? "Required" : null,
                    ),
                    const SizedBox(height: 25),
                    _sectionHeader("Homework Details", Icons.assignment),
                    TextFormField(
                      maxLength: 100,
                      controller: _titleController,
                      decoration: const InputDecoration(
                          labelText: "Homework Title *",
                          border: OutlineInputBorder()),
                      validator: (val) =>
                          (val?.isEmpty ?? true) ? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: "Description / Instructions",
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                            child: _buildDateInput(
                                "Assigned Date",
                                assignedDate,
                                () => _pickDate(true),
                                () => setState(() => assignedDate = null))),
                        const SizedBox(width: 15),
                        Expanded(
                            child: _buildDateInput(
                                "Due Date",
                                dueDate,
                                () => _pickDate(false),
                                () => setState(() => dueDate = null))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _sectionHeader("Attachment (Optional)", Icons.attach_file),
                    DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        color: Colors.blue.shade300,
                        strokeWidth: 2,
                        dashPattern: const [6, 3],
                        radius: const Radius.circular(8),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        color: Colors.blue.shade50,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cloud_upload_outlined,
                                    size: 40, color: Colors.blue),
                                const SizedBox(width: 10),
                                const Expanded(
                                    child: Text(
                                        "Upload File\nPDF, Image, (Max 10MB)",
                                        style: TextStyle(fontSize: 12))),
                                OutlinedButton.icon(
                                    onPressed: _pickFile,
                                    icon: const Icon(Icons.upload),
                                    label: const Text("Choose File")),
                              ],
                            ),
                            ...pickedFiles.map((f) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.insert_drive_file,
                                        color: Colors.blue),
                                    title: Text(f.name,
                                        overflow: TextOverflow.ellipsis),
                                    trailing: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () => setState(
                                            () => pickedFiles.remove(f))),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18)),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"))),
                        const SizedBox(width: 15),
                        Expanded(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[900],
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18)),
                                onPressed: _submitForm,
                                child: const Text("Post Homework",
                                    style: TextStyle(color: Colors.white)))),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(children: [
          Icon(icon, color: Colors.blue[900]),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
        ]));
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[100]));
  }

  Future<void> _submitForm() async {
    // 1. Validation check
    if (!_formKey.currentState!.validate()) return;
    if (selectedSubject == null || assignedDate == null || dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields!")));
      return;
    }
    if (pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please attach at least one file!")));
      return;
    }

    setState(() => isLoading = true);

    try {
      List<String> uploadedFileUrls = [];

      // Cloudinary configuration (Unsigned preset 'homework_images' use kar rahe hain)
      final cloudinary =
          CloudinaryPublic('dkjsza6pw', 'homework_images', cache: false);

      for (var file in pickedFiles) {
        CloudinaryResponse response;

        if (kIsWeb) {
          // WEB KE LIYE: Base64 string use karein
          String base64Str = base64Encode(file.bytes!);

          // Data URI format purane versions ke liye behtareen hai
          response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              "data:application/octet-stream;base64,$base64Str",
              identifier: file.name,
              resourceType: CloudinaryResourceType.Auto,
            ),
          );
        } else {
          // MOBILE KE LIYE: File path use karein
          response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              file.path!,
              resourceType: CloudinaryResourceType.Auto,
            ),
          );
        }
        uploadedFileUrls.add(response.secureUrl);
      }

      // 2. Firestore mein data store karein
      await FirebaseFirestore.instance.collection('homework').add({
        'title': _titleController.text,
        'description': _descController.text,
        'class': teacherClass,
        'subject': selectedSubject,
        'assignedDate': assignedDate,
        'dueDate': dueDate,
        'attachments': uploadedFileUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'teacherId': FirebaseAuth.instance.currentUser?.uid,
      });

      // 3. Form reset karein
      setState(() {
        _titleController.clear();
        _descController.clear();
        pickedFiles.clear();
        assignedDate = null;
        dueDate = null;
        selectedSubject = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Homework Posted Successfully!"),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Upload Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDateInput(
      String label, DateTime? date, VoidCallback onTap, VoidCallback onClear) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
            date == null
                ? "Select Date"
                : DateFormat('dd MMM yyyy').format(date),
            style: TextStyle(color: date == null ? Colors.grey : Colors.black)),
      ),
    );
  }
}
