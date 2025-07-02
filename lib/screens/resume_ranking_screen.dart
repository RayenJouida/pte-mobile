// screens/resume_ranking_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../services/ai_service.dart';

class ResumeRankingScreen extends StatefulWidget {
  const ResumeRankingScreen({super.key});

  @override
  State<ResumeRankingScreen> createState() => _ResumeRankingScreenState();
}

class _ResumeRankingScreenState extends State<ResumeRankingScreen> {
  List<File> selectedResumes = [];
  String jobDescription = '';
  bool isLoading = false;
  List<List<dynamic>>? rankingData;

  Future<void> pickResumes() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedResumes.addAll(result.paths.map((path) => File(path!)));
        selectedResumes = selectedResumes.toSet().toList();
      });
    }
  }

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toUpperCase();
  }

  Future<void> runRanking() async {
    if (selectedResumes.isEmpty || jobDescription.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select resumes and enter job description'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      rankingData = null;
    });

    final uploadSuccess = await AIService.uploadResumes(selectedResumes);
    if (uploadSuccess) {
      final candidates = await AIService.processJobDescription(jobDescription);
      if (candidates.isNotEmpty) {
        final List<List<dynamic>> tableData = [];
        tableData.add([
          'Rank',
          'Name',
          'Similarity Score',
          'Phone',
          'Email',
          'Skills',
        ]);
        for (final c in candidates) {
          tableData.add([
            c['rank'] ?? '',
            c['name'] ?? '',
            c['similarity_score'] ?? 0.0,
            c['phone'] ?? '',
            c['email'] ?? '',
            (c['skills'] as List<dynamic>).join(', '),
          ]);
        }
        setState(() {
          rankingData = tableData;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No candidates returned by AI service'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to upload resumes'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  Widget _buildMatchQualityChip(num score) {
    String label;
    Color bgColor;
    Color textColor;
    IconData icon;
    
    if (score > 0.04) {
      label = 'Excellent';
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.star;
    } else if (score > 0.02) {
      label = 'Good';
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.star_half;
    } else {
      label = 'Fair';
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.star_border;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '${score.toStringAsFixed(3)} ($label)',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDataTable() {
    if (rankingData == null || rankingData!.isEmpty) return const SizedBox();

    final headers = rankingData!.first;
    final rows = rankingData!.skip(1);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quality Legend
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match Quality Scale:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Excellent (>0.04)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_half, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Good (0.021-0.04)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_border, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Fair (≤0.02)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 80,
                ),
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  columns: headers
                      .map((h) => DataColumn(
                            label: Text(h.toString()),
                          ))
                      .toList(),
                  rows: rows
                      .map((row) => DataRow(
                            cells: row.asMap().entries.map((entry) {
                              final index = entry.key;
                              final cell = entry.value;
                              if (index == 2 && cell is num) {
                                return DataCell(_buildMatchQualityChip(cell));
                              }
                              return DataCell(Text(cell.toString()));
                            }).toList(),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Ranking'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File Upload Section
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Resumes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: pickResumes,
                        icon: const Icon(Icons.add),
                        label: const Text('Select Files'),
                      ),
                    ),
                    if (selectedResumes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${selectedResumes.length} file(s) selected:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => setState(() => selectedResumes.clear()),
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...selectedResumes.map((file) {
                              final fileName = _getFileName(file.path);
                              final extension = _getFileExtension(fileName);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        extension,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedResumes.remove(file);
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Job Description Section
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Job Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 6,
                      onChanged: (val) => jobDescription = val,
                      decoration: InputDecoration(
                        hintText: 'Enter the job description here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : runRanking,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Processing...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Run AI Ranking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            // Results Section
            if (rankingData != null && rankingData!.length > 1) ...[
              const SizedBox(height: 24),
              Text(
                'Ranking Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              buildDataTable(),
            ],
          ],
        ),
      ),
    );
  }
}