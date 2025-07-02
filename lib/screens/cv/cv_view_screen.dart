import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pte_mobile/models/cv/education.dart';
import 'package:pte_mobile/models/cv/certification.dart';
import 'package:pte_mobile/models/cv/experience.dart';
import 'package:pte_mobile/models/cv/skill.dart';
import 'package:pte_mobile/models/cv/language.dart';
import 'package:pte_mobile/models/cv/project.dart';
import '../../theme/theme.dart';

class CvViewScreen extends StatelessWidget {
  final String userId;
  final String token;
  final String summary;
  final List<Education> educations;
  final List<Experience> experiences;
  final List<Certification> certifications;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Project> projects;

  const CvViewScreen({
    Key? key,
    required this.userId,
    required this.token,
    required this.summary,
    required this.educations,
    required this.experiences,
    required this.certifications,
    required this.skills,
    required this.languages,
    required this.projects,
  }) : super(key: key);

  Future<void> _downloadAsPdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text('Curriculum Vitae', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            if (summary.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text('Summary')),
              pw.Paragraph(text: summary),
              pw.SizedBox(height: 10),
            ],
            if (educations.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text('Education')),
              ...educations.map((edu) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(edu.establishment, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${edu.diploma}, ${edu.section}'),
                  pw.Text('${edu.yearStart.year}${edu.present ? ' - Present' : ' - ${edu.yearEnd?.year ?? ''}'}'),
                  pw.SizedBox(height: 10),
                ],
              )).toList(),
            ],
            if (experiences.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text('Experience')),
              ...experiences.map((exp) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(exp.company, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(exp.job),
                  pw.Text('${exp.start.year}${exp.present ? ' - Present' : ' - ${exp.end?.year ?? ''}'}'),
                  pw.Text(exp.taskDescription),
                  pw.SizedBox(height: 10),
                ],
              )).toList(),
            ],
            if (certifications.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text('Certifications')),
              ...certifications.map((cert) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(cert.domaine, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${cert.credential} (${cert.date.year})'),
                  pw.SizedBox(height: 10),
                ],
              )).toList(),
            ],
            if (skills.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text('Skills')),
              ...skills.map((skill) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${skill.name}: Level ${skill.level}'),
                  pw.SizedBox(height: 5),
                ],
              )).toList(),
            ],
            if (languages.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text('Languages')),
              ...languages.map((lang) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${lang.name}: Level ${lang.level}'),
                  pw.SizedBox(height: 5),
                ],
              )).toList(),
            ],
            if (projects.isNotEmpty) ...[
              pw.Header(level: 1, child: pw.Text('Projects')),
              ...projects.map((proj) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(proj.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${proj.organization} (${proj.date.year})'),
                  pw.Text(proj.description),
                  pw.SizedBox(height: 10),
                ],
              )).toList(),
            ],
          ];
        },
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'cv_$userId.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View CV', style: TextStyle(color: lightColorScheme.onPrimary)),
        backgroundColor: lightColorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: lightColorScheme.onPrimary),
            onPressed: () => _downloadAsPdf(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Curriculum Vitae', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightColorScheme.primary)),
            const SizedBox(height: 20),
            if (summary.isNotEmpty) ...[
              Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightColorScheme.primary)),
              const SizedBox(height: 8),
              Text(summary, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],
            if (educations.isNotEmpty) ...[
              Text('Education', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightColorScheme.primary)),
              const SizedBox(height: 8),
              ...educations.map((edu) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(edu.establishment, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${edu.diploma}, ${edu.section}'),
                      Text('${edu.yearStart.year}${edu.present ? ' - Present' : ' - ${edu.yearEnd?.year ?? ''}'}'),
                    ],
                  ),
                ),
              )).toList(),
              const SizedBox(height: 20),
            ],
            if (experiences.isNotEmpty) ...[
              Text('Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightColorScheme.primary)),
              const SizedBox(height: 8),
              ...experiences.map((exp) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exp.company, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(exp.job),
                      Text('${exp.start.year}${exp.present ? ' - Present' : ' - ${exp.end?.year ?? ''}'}'),
                      Text(exp.taskDescription),
                    ],
                  ),
                ),
              )).toList(),
              const SizedBox(height: 20),
            ],
            if (certifications.isNotEmpty) ...[
              Text('Certifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightColorScheme.primary)),
              const SizedBox(height: 8),
              ...certifications.map((cert) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cert.domaine, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${cert.credential} (${cert.date.year})'),
                    ],
                  ),
                ),
              )).toList(),
              const SizedBox(height: 20),
            ],
            if (skills.isNotEmpty) ...[
              Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightColorScheme.primary)),
              const SizedBox(height: 8),
              ...skills.map((skill) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${skill.name}: Level ${skill.level}'),
                ),
              )).toList(),
              const SizedBox(height: 20),
            ],
            if (languages.isNotEmpty) ...[
              Text('Languages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightColorScheme.primary)),
              const SizedBox(height: 8),
              ...languages.map((lang) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${lang.name}: Level ${lang.level}'),
                ),
              )).toList(),
              const SizedBox(height: 20),
            ],
            if (projects.isNotEmpty) ...[
              Text('Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightColorScheme.primary)),
              const SizedBox(height: 8),
              ...projects.map((proj) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(proj.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${proj.organization} (${proj.date.year})'),
                      Text(proj.description),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }
}