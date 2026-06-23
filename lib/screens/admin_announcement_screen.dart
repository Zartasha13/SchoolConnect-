import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  bool sendToTeachers = false;
  bool sendToStudents = false;
  bool isLoading = false;

  File? attachmentFile;
  final ImagePicker picker = ImagePicker();

  Future<void> pickAttachment() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        attachmentFile = File(picked.path);
      });
    }
  }

  Future<String?> uploadFile(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
          'announcements/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> postAnnouncement() async {
    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Title & Description required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!sendToTeachers && !sendToStudents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select at least one audience"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? fileUrl;
      if (attachmentFile != null) {
        fileUrl = await uploadFile(attachmentFile!);
      }

      await FirebaseFirestore.instance.collection('announcements').add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'teachers': sendToTeachers,
        'students': sendToStudents,
        'attachment': fileUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      titleController.clear();
      descController.clear();
      setState(() {
        attachmentFile = null;
        sendToTeachers = false;
        sendToStudents = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Announcement Posted"),
              backgroundColor: Color(0xFF4CAF50)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xFF166534),
          title: const Text("Post Announcements")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                      labelText: "Title", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: "Description", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Audience *",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select at least one audience",
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    Row(
                      children: [
                        Expanded(
                            child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: sendToTeachers,
                                title: const Text("Teachers"),
                                onChanged: (v) =>
                                    setState(() => sendToTeachers = v!))),
                        Expanded(
                            child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: sendToStudents,
                                title: const Text("Students"),
                                onChanged: (v) =>
                                    setState(() => sendToStudents = v!))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: postAnnouncement,
                        child: const Text("Post Announcement"),
                      ),
              ),
              const Divider(height: 30),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Posted Announcements",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 15),
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300))),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text("Title",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 2,
                              child: Text("Audience",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 2,
                              child: Text("Posted On",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                              flex: 1,
                              child: Text("Actions",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('announcements')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text("No announcements yet"));
                        }
                        final docs = snapshot.data!.docs;
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (c, i) => const Divider(height: 1),
                          itemBuilder: (c, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final docId = docs[i].id;
                            Timestamp? t = data['createdAt'] as Timestamp?;
                            String d = t != null
                                ? "${t.toDate().day}/${t.toDate().month} ${t.toDate().hour}:${t.toDate().minute}"
                                : "N/A";
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text(data['title'] ?? "")),
                                  Expanded(
                                      flex: 2,
                                      child: Row(children: [
                                        if (data['teachers'] == true)
                                          _buildBadge(
                                              "Teachers",
                                              Colors.green.shade50,
                                              Colors.green),
                                        if (data['students'] == true)
                                          _buildBadge("Students",
                                              Colors.blue.shade50, Colors.blue),
                                      ])),
                                  Expanded(
                                      flex: 2,
                                      child: Text(d,
                                          style:
                                              const TextStyle(fontSize: 12))),
                                  Expanded(
                                      flex: 1,
                                      child: Row(children: [
                                        IconButton(
                                            icon: const Icon(Icons.visibility,
                                                color: Colors.green, size: 20),
                                            onPressed: () => showDialog(
                                                context: context,
                                                builder: (ctx) =>
                                                    AlertDialog(
                                                        title:
                                                            Text(data['title']),
                                                        content: Text(data[
                                                            'description']),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      ctx),
                                                              child: const Text(
                                                                  "Close"))
                                                        ]))),
                                        IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red, size: 20),
                                            onPressed: () => FirebaseFirestore
                                                .instance
                                                .collection('announcements')
                                                .doc(docId)
                                                .delete()),
                                      ])),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: textColor.withValues(alpha: 0.5))),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}
