import 'package:flutter/material.dart';

class CandidateCard extends StatelessWidget {
  final int rank;
  final String name;
  final String email;
  final String phone;
  final String skills;
  final String score;

  const CandidateCard({
    super.key,
    required this.rank,
    required this.name,
    required this.email,
    required this.phone,
    required this.skills,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#$rank $name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text('$score%'),
                  backgroundColor: _getScoreColor(double.parse(score)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (email.isNotEmpty) _buildInfoRow(Icons.email, email),
            if (phone.isNotEmpty) _buildInfoRow(Icons.phone, phone),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Skills:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(skills),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Flexible(child: Text(text)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green.shade100;
    if (score >= 60) return Colors.blue.shade100;
    if (score >= 40) return Colors.orange.shade100;
    return Colors.red.shade100;
  }
}