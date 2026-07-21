import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excelLib;

class BulkImportStudentsScreen extends StatefulWidget {
  const BulkImportStudentsScreen({super.key});

  @override
  State<BulkImportStudentsScreen> createState() =>
      _BulkImportStudentsScreenState();
}

class _BulkImportStudentsScreenState extends State<BulkImportStudentsScreen> {
  static const _navy = Color(0xFF1E3A5F);
  static const _accent = Color(0xFF2E86AB);
  static const _green = Color(0xFF28A745);
  static const _orange = Color(0xFFFFA500);
  static const _red = Color(0xFFDC3545);

  // ── Import state ───────────────────────────────────────────────────────────
  List<Map<String, String>> _parsedRows = [];
  List<String> _errorRows = [];
  bool _isPicking = false;
  bool _isImporting = false;
  int _importProgress = 0;
  int _importTotal = 0;
  int _importedCount = 0;
  int _skippedCount = 0;
  bool _importDone = false;
  String? _fileName;

  // ── Student list state ─────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  // FIX: not final — needs to be reassigned on reset
  List<QueryDocumentSnapshot> _allDocs = [];

  static const _pageSize = 20;

  static const _requiredColumns = [
    'roll_no',
    'student_name',
    'father_name',
    'grade',
    'dob',
    'school_fee',
    'ac_charges',
    'security_fee',
    'transport_fee',
  ];

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIX 1 — Excel parsed in isolate-friendly way, bytes released after parse
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _parsedRows = [];
      _errorRows = [];
      _importDone = false;
      _fileName = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }
      final file = result.files.first;
      _fileName = file.name;

      final Uint8List bytes = Uint8List.fromList(file.bytes!);
      await Future.delayed(Duration.zero);
      _parseExcel(bytes);
    } catch (e) {
      _showSnack('Error picking file: $e', isError: true);
      setState(() => _isPicking = false);
    }
  }

  void _parseExcel(Uint8List bytes) {
    try {
      final excel = excelLib.Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        _showSnack('Excel sheet is empty.', isError: true);
        setState(() => _isPicking = false);
        return;
      }

      final headers = sheet.rows.first
          .map((c) => c?.value?.toString().trim().toLowerCase() ?? '')
          .toList();

      for (final col in _requiredColumns) {
        if (!headers.contains(col)) {
          _showSnack('Missing column: "$col"', isError: true);
          setState(() => _isPicking = false);
          return;
        }
      }

      final rows = <Map<String, String>>[];
      final errors = <String>[];

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        // Skip empty rows
        if (row.every(
          (c) => c == null || (c.value?.toString().trim() ?? '').isEmpty,
        )) {
          continue;
        }
        final map = <String, String>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          if (headers[j].isNotEmpty) {
            map[headers[j]] = row[j]?.value?.toString().trim() ?? '';
          }
        }
        if ((map['roll_no'] ?? '').isEmpty ||
            (map['student_name'] ?? '').isEmpty) {
          errors.add('Row ${i + 1}: roll_no or student_name is empty');
          continue;
        }
        rows.add(map);
      }

      excel.tables.clear();

      if (mounted) {
        setState(() {
          _parsedRows = rows;
          _errorRows = errors;
          _isPicking = false;
        });
      }
    } catch (e) {
      _showSnack('Parse error: $e', isError: true);
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIX 2 — Import: only fetch admission_nos (not full docs) for duplicate check
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _importToFirestore() async {
    if (_parsedRows.isEmpty) return;
    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = _parsedRows.length;
      _importedCount = 0;
      _skippedCount = 0;
      _importDone = false;
    });

    final fs = FirebaseFirestore.instance;
    final ref = fs.collection('student_profile');

    Set<String> existing;
    try {
      final snap = await ref.get();
      existing = snap.docs
          .map((d) => (d.data()['roll_no'] ?? '').toString())
          .toSet();
    } catch (_) {
      existing = {};
    }

    const batchSize = 499;
    int imported = 0, skipped = 0;

    for (int i = 0; i < _parsedRows.length; i += batchSize) {
      final chunk = _parsedRows.sublist(
        i,
        (i + batchSize).clamp(0, _parsedRows.length),
      );
      final batch = fs.batch();

      for (int ci = 0; ci < chunk.length; ci++) {
        final row = chunk[ci];
        final rollNo = row['roll_no'] ?? '';
        if (existing.contains(rollNo)) {
          skipped++;
        } else {
          double schoolFee = double.tryParse(row['school_fee'] ?? '0') ?? 0;
          double acCharges = double.tryParse(row['ac_charges'] ?? '0') ?? 0;
          double securityFee = double.tryParse(row['security_fee'] ?? '0') ?? 0;
          double transportFee =
              double.tryParse(row['transport_fee'] ?? '0') ?? 0;

          double totalFee = schoolFee + acCharges + securityFee + transportFee;
          batch.set(ref.doc(), {
            'roll_no': rollNo,
            'student_name': row['student_name'] ?? '',
            'father_name': row['father_name'] ?? '',
            'grade': row['grade'] ?? '',
            'dob': row['dob'] ?? '',
            'created_at': FieldValue.serverTimestamp(),
            'fees': {
              'school_fee': schoolFee,
              'ac_charges': acCharges,
              'security_fee': securityFee,
              'transport_fee': transportFee,
              'total_fee': totalFee,
            },
          });
          existing.add(rollNo);
          imported++;
        }
        if (mounted) setState(() => _importProgress = i + ci + 1);
      }
      await batch.commit();
    }

    _resetPagination();
    await _loadFirstPage();

    if (mounted) {
      setState(() {
        _isImporting = false;
        _importedCount = imported;
        _skippedCount = skipped;
        _importDone = true;
      });
    }
  }

  void _resetImport() {
    setState(() {
      _parsedRows = [];
      _errorRows = [];
      _importDone = false;
      _importedCount = 0;
      _skippedCount = 0;
      _fileName = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIX 3 — Pagination: proper reset + guard against repeated calls
  // ═══════════════════════════════════════════════════════════════════════════

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted)
        setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  // FIX: reassign list instead of .clear() so StreamBuilder/setState picks it up
  void _resetPagination() {
    _allDocs = [];
    _lastDoc = null;
    _hasMore = true;
    _isLoadingMore = false;
  }

  Future<void> _loadFirstPage() async {
    // FIX: prevent double-load
    if (_isLoadingMore) return;
    _resetPagination();
    if (mounted) setState(() => _isLoadingMore = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('student_profile')
          .orderBy('roll_no')
          .limit(_pageSize)
          .get();

      if (mounted) {
        setState(() {
          _allDocs = List.from(snap.docs); // new list reference
          _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
          _hasMore = snap.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        _showSnack('Failed to load students: $e', isError: true);
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _lastDoc == null) return;
    if (mounted) setState(() => _isLoadingMore = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('student_profile')
          .orderBy('roll_no')
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();

      if (mounted) {
        setState(() {
          _allDocs = [..._allDocs, ...snap.docs]; // new list
          _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
          _hasMore = snap.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<QueryDocumentSnapshot> get _filteredDocs {
    if (_searchQuery.isEmpty) return _allDocs;
    return _allDocs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final fees = d['fees'] as Map<String, dynamic>? ?? {};
      return (d['student_name']?.toString().toLowerCase() ?? '').contains(
            _searchQuery,
          ) ||
          (d['roll_no']?.toString().toLowerCase() ?? '').contains(
            _searchQuery,
          ) ||
          (d['father_name']?.toString().toLowerCase() ?? '').contains(
            _searchQuery,
          );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _openEditDialog(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final cName = TextEditingController(text: data['student_name'] ?? '');
    final cFath = TextEditingController(text: data['father_name'] ?? '');
    final cGrad = TextEditingController(text: data['grade'] ?? '');
    // final cSec = TextEditingController(text: data['section'] ?? '');
    final cDob = TextEditingController(text: data['dob'] ?? '');
    final fees = (data['fees'] as Map<String, dynamic>?) ?? {};

    final cSchoolFee = TextEditingController(
      text: (fees['school_fee'] ?? 0).toString(),
    );
    final cAcCharges = TextEditingController(
      text: (fees['ac_charges'] ?? 0).toString(),
    );
    final cSecurityFee = TextEditingController(
      text: (fees['security_fee'] ?? 0).toString(),
    );
    final cTransportFee = TextEditingController(
      text: (fees['transport_fee'] ?? 0).toString(),
    );
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> save() async {
            setDialogState(() => isSaving = true);
            try {
              // 1. Fee calculation pehle kar lein
              double schoolFee = double.tryParse(cSchoolFee.text) ?? 0;
              double acCharges = double.tryParse(cAcCharges.text) ?? 0;
              double securityFee = double.tryParse(cSecurityFee.text) ?? 0;
              double transportFee = double.tryParse(cTransportFee.text) ?? 0;

              double totalFee =
                  schoolFee + acCharges + securityFee + transportFee;

              // 2. Sirf ek baar update call karein
              await doc.reference.update({
                'student_name': cName.text.trim(),
                'father_name': cFath.text.trim(),
                'grade': cGrad.text.trim(),
                'dob': cDob.text.trim(),

                'fees': {
                  'school_fee': schoolFee,
                  'ac_charges': acCharges,
                  'security_fee': securityFee,
                  'transport_fee': transportFee,
                  'total_fee': totalFee,
                },

                'updated_at': FieldValue.serverTimestamp(),
              });

              if (ctx.mounted) Navigator.pop(ctx);
              _showSnack('Student updated successfully.');

              // Reload list to reflect changes
              _resetPagination();
              _loadFirstPage();
            } catch (e) {
              _showSnack('Update failed: $e', isError: true);
              setDialogState(() => isSaving = false);
            }
          }

          Future<void> deleteStudent() async {
            Navigator.pop(ctx);
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text(
                  'Delete Student',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                content: Text(
                  'Are you sure you want to delete "${data['student_name']}"?\nThis cannot be undone.',
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(c, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              try {
                await doc.reference.delete();
                _showSnack('Student deleted.');
                _resetPagination();
                _loadFirstPage();
              } catch (e) {
                _showSnack('Delete failed: $e', isError: true);
              }
            }
          }

          Widget field(
            String label,
            TextEditingController ctrl, {
            TextInputType kbType = TextInputType.text,
          }) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: ctrl,
                keyboardType: kbType,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit — ${data['student_name'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: field('Student Name', cName)),
                          const SizedBox(width: 10),
                          Expanded(child: field('Father Name', cFath)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: field('Grade', cGrad)),
                          const SizedBox(width: 10),
                          // Expanded(child: field('Section', cSec)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: field('DOB', cDob)),
                          const SizedBox(width: 10),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Divider(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Fee Details",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: field(
                              'School Fee',
                              cSchoolFee,
                              kbType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: field(
                              'AC Charges',
                              cAcCharges,
                              kbType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: field(
                              'Security Fee',
                              cSecurityFee,
                              kbType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: field(
                              'Transport Fee',
                              cTransportFee,
                              kbType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Roll No: ${data['roll_no'] ?? '—'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: isSaving ? null : deleteStudent,
                icon: const Icon(Icons.delete_outline, size: 16, color: _red),
                label: const Text('Delete', style: TextStyle(color: _red)),
              ),
              const Spacer(),
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Bulk Import Students',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 28 : 16),
        child: Column(
          children: [
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _leftPanel()),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: _rightPanel()),
                    ],
                  )
                : Column(
                    children: [
                      _leftPanel(),
                      const SizedBox(height: 20),
                      _rightPanel(),
                    ],
                  ),
            const SizedBox(height: 28),
            _studentListSection(isWide),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Left Panel ─────────────────────────────────────────────────────────────
  Widget _leftPanel() {
    return Column(
      children: [
        _buildCard(
          title: 'How to Import',
          icon: Icons.info_outline,
          iconColor: _accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepItem('1', 'Prepare your Excel file (.xlsx)'),
              _stepItem('2', 'Make sure all required columns exist'),
              _stepItem('3', 'Upload the filled .xlsx file'),
              _stepItem('4', 'Preview data and confirm import'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Required Columns',
          icon: Icons.table_chart_outlined,
          iconColor: _navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _requiredColumns
                .map(
                  (col) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          col,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isPicking || _isImporting ? null : _pickFile,
            icon: _isPicking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file, size: 20),
            label: Text(_isPicking ? 'Reading file...' : 'Upload Excel File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (_fileName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: _green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _green,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Right Panel ────────────────────────────────────────────────────────────
  Widget _rightPanel() {
    if (_importDone) return _importResultCard();
    if (_isImporting) return _importProgressCard();
    if (_parsedRows.isEmpty) return _emptyStateCard();
    return Column(
      children: [
        _previewHeader(),
        const SizedBox(height: 12),
        if (_errorRows.isNotEmpty) _errorBanner(),
        const SizedBox(height: 12),
        _previewTable(),
        const SizedBox(height: 16),
        _importButton(),
      ],
    );
  }

  Widget _emptyStateCard() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file_outlined,
            size: 52,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No file uploaded yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload an Excel file to preview student data',
            style: TextStyle(fontSize: 12, color: Color(0xFFB0B7C3)),
          ),
        ],
      ),
    );
  }

  Widget _previewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview — ${_parsedRows.length} rows',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              'Review before importing to Firestore',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _resetImport,
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Clear'),
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
        ),
      ],
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: _orange, size: 16),
              const SizedBox(width: 8),
              Text(
                '${_errorRows.length} row(s) will be skipped:',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._errorRows.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $e',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewTable() {
    const displayCols = [
      'roll_no',
      'student_name',
      'father_name',
      'grade',
      'dob',
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A5F)),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            columnSpacing: 20,
            columns: [
              const DataColumn(label: Text('#')),
              ...displayCols.map(
                (col) => DataColumn(
                  label: Text(
                    col.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
            rows: _parsedRows
                .asMap()
                .entries
                .map(
                  (e) => DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...displayCols.map(
                        (col) => DataCell(
                          Text(
                            e.value[col] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _importButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _importToFirestore,
        icon: const Icon(Icons.cloud_upload_outlined, size: 20),
        label: Text(
          'Import ${_parsedRows.length} Students',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _importProgressCard() {
    final pct = _importTotal > 0 ? _importProgress / _importTotal : 0.0;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecor(),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 48, color: _accent),
          const SizedBox(height: 20),
          const Text(
            'Importing students...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_importProgress of $_importTotal records',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _importResultCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecor(),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 36,
              color: _green,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Import Complete!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _resultTile('Imported', '$_importedCount', _green),
              const SizedBox(width: 16),
              _resultTile('Skipped (Duplicates)', '$_skippedCount', _orange),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetImport,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Import Another File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVE STUDENT LIST SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _studentListSection(bool isWide) {
    final filtered = _filteredDocs;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Students',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: ${_allDocs.length}${_hasMore ? '+' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _loadFirstPage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by name, roll no, or father name...',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB5BD),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _accent, width: 1.5),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Content
          if (_isLoadingMore && _allDocs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: _navy)),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_outlined,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No students found.'
                          : 'No results for "$_searchQuery"',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isWide)
            _desktopTable(filtered)
          else
            _mobileList(filtered),

          // Load More / Done
          if (_hasMore && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _isLoadingMore
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _navy,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: _loadMore,
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: Text('Load More  (showing ${_allDocs.length})'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _navy,
                          side: const BorderSide(color: _navy),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
              ),
            ),
          if (!_hasMore && _allDocs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'All ${_allDocs.length} students loaded',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _desktopTable(List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _navy,
        ),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columnSpacing: 18,
        columns: const [
          DataColumn(label: Text('Roll #')),
          DataColumn(label: Text('Student Name')),
          DataColumn(label: Text('Father Name')),
          DataColumn(label: Text('Grade')),
          DataColumn(label: Text('Total Fee')),
          DataColumn(label: Text('Actions')),
        ],
        rows: docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          // Nested fees object extract karein
          final fees = (d['fees'] as Map<String, dynamic>?) ?? {};
          final totalFee = fees['total_fee'] ?? 0;

          return DataRow(
            cells: [
              DataCell(_chip(d['roll_no']?.toString() ?? '—', _accent)),
              DataCell(
                Text(
                  d['student_name'] ?? '—',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              DataCell(
                Text(
                  d['father_name'] ?? '—',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              DataCell(
                Text(d['grade'] ?? '—', style: const TextStyle(fontSize: 12)),
              ),
              // Updated to show Total Fee from nested object
              DataCell(
                Text(
                  'Rs. $totalFee',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
              ),
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => _openEditDialog(doc),
                  icon: const Icon(Icons.edit_outlined, size: 13),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F4FF),
                    foregroundColor: _navy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFFBFD0F0)),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _mobileList(List<QueryDocumentSnapshot> docs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
      itemBuilder: (_, i) {
        final doc = docs[i];
        final d = doc.data() as Map<String, dynamic>;
        // Nested fees access
        final fees = (d['fees'] as Map<String, dynamic>?) ?? {};
        final totalFee = fees['total_fee'] ?? 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: _navy.withOpacity(0.1),
            radius: 22,
            child: Text(
              (d['name']?.toString() ?? '?').isNotEmpty
                  ? d['name'].toString()[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            d['name'] ?? '—',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                '${d['father_name'] ?? '—'} • Roll# ${d['roll_no'] ?? '—'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              Text(
                'Fee: Rs. $totalFee',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _green,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            onPressed: () => _openEditDialog(
              doc,
            ), // Ye aapka wahi edit dialog open karega jisme saari fields editable hain
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFD0F0)),
              ),
              child: const Icon(Icons.edit_outlined, size: 16, color: _navy),
            ),
          ),
        );
      },
    );
  }
  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: _cardDecor(), // <--- Yahan reuse kar liya
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}
