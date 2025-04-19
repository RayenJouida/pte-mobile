import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pte_mobile/screens/labmanager/lab_request.dart';
import 'package:pte_mobile/theme/theme.dart';

class HomeLabScreen extends StatelessWidget {
  const HomeLabScreen({Key? key}) : super(key: key);

  void _navigateToLabRequest(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => LabRequestsScreen()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColorScheme.surfaceVariant,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Lab Control Hub',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: lightColorScheme.onPrimary,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      lightColorScheme.primary,
                      lightColorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      'Manage Your Virtualization Labs',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: lightColorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Actions
                _buildQuickActionsCard(context),
                const SizedBox(height: 16),

                // Lab Status
                Row(
                  children: [
                    Expanded(child: _buildStatusCard(
                      icon: Icons.check_circle,
                      title: 'Active Labs',
                      count: 5,
                      color: Colors.green,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatusCard(
                      icon: Icons.hourglass_empty,
                      title: 'Pending Requests',
                      count: 3,
                      color: Colors.orange,
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats
                _buildStatsCard(),
                const SizedBox(height: 24),

                // Footer
                Center(
                  child: Text(
                    'Powered by Prologic',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: lightColorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: lightColorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _navigateToLabRequest(context),
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('Request New Lab'),
              style: FilledButton.styleFrom(
                backgroundColor: lightColorScheme.primary,
                foregroundColor: lightColorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                minimumSize: const Size(double.infinity, 56),
              ),
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: lightColorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lab Stats',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: lightColorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Labs', '12', Icons.computer),
                _buildStatItem('Uptime', '99.9%', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: lightColorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: lightColorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: lightColorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 450.ms).scale();
  }
}
