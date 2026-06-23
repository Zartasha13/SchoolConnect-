import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Report: ${reportData['month']}",
          style: const TextStyle(
            color: Colors.white, // Text color white
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            const Color(0xFF1746A2), // Apne main blue color ke sath
        iconTheme: const IconThemeData(
          color: Colors.white, // Back button color white
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailCard("Academic Performance", [
              _buildRow("Overall:", reportData['overallPerformance']),
              _buildRow("Homework:", reportData['homeworkCompletion']),
              _buildRow("Participation:", reportData['classParticipation']),
            ]),
            const SizedBox(height: 20),
            _buildDetailCard("Attendance", [
              _buildRow("Total Days:", reportData['totalDays'].toString()),
              _buildRow("Present:", reportData['presentDays'].toString()),
              _buildRow("Absent:", reportData['absentDays'].toString()),
            ]),
            const SizedBox(height: 20),
            _buildDetailCard("Teacher Remarks", [
              Text(reportData['remarks'] ?? "No remarks added."),
            ]),
            const SizedBox(height: 20),
            if (reportData['attachmentUrls'] != null &&
                (reportData['attachmentUrls'] as List).isNotEmpty)
              _buildDetailCard("Attachments", [
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: (reportData['attachmentUrls'] as List).map((url) {
                    return GestureDetector(
                      onTap: () {
                        // Image par click karne par full screen view open karne ke liye
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    FullScreenImage(imageUrl: url)));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider(),
        ...children,
      ]),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
            ]));
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
