import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickalert/quickalert.dart';
import 'package:pte_mobile/models/virtualization_env.dart';
import 'package:pte_mobile/services/virtualization_env_service.dart';
import 'package:pte_mobile/theme/theme.dart';

class RequesterInfoScreen extends StatelessWidget {
  final VirtualizationEnv request;

  const RequesterInfoScreen({Key? key, required this.request}) : super(key: key);

  Future<void> _handleAccept(BuildContext context) async {
    print('Starting accept request for ID: ${request.id}');
    try {
      await VirtualizationEnvService().acceptLabRequest(request.id, {});
      print('Accept request successful for ID: ${request.id}');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success',
        text: 'Request accepted successfully!',
        confirmBtnColor: lightColorScheme.primary,
        onConfirmBtnTap: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context, true); // Return to LabRequestsScreen
        },
      );
    } catch (e) {
      print('Accept request failed for ID: ${request.id}, Error: $e');
      String errorMessage = 'Failed to accept request';
      if (e.toString().contains('Failed to accept lab request')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: errorMessage,
        confirmBtnColor: lightColorScheme.primary,
      );
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Decline Request',
      text: 'Are you sure you want to decline this request?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      confirmBtnColor: lightColorScheme.primary,
      onConfirmBtnTap: () async {
        Navigator.pop(context); // Close dialog
        print('Starting decline request for ID: ${request.id}');
        try {
          await VirtualizationEnvService().declineLabRequest(request.id);
          print('Decline request successful for ID: ${request.id}');
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'Success',
            text: 'Request declined successfully!',
            confirmBtnColor: lightColorScheme.primary,
            onConfirmBtnTap: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to LabRequestsScreen
            },
          );
        } catch (e) {
          print('Decline request failed for ID: ${request.id}, Error: $e');
          String errorMessage = 'Failed to decline request';
          if (e.toString().contains('Failed to decline lab request')) {
            errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error',
            text: errorMessage,
            confirmBtnColor: lightColorScheme.primary,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColorScheme.surfaceVariant,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20, left: 16, right: 16),
            decoration: BoxDecoration(
              color: lightColorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: lightColorScheme.onPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Request Details',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: lightColorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance back button
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    title: 'Requester Details',
                    children: [
                      _buildInfoRow('Name', '${request.firstName} ${request.lastName}'),
                      _buildInfoRow('Email', request.email),
                      _buildInfoRow('Department', request.departement),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideY(delay: 300.ms),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    title: 'Lab Request Details',
                    children: [
                      _buildInfoRow('Lab Type', request.type),
                      _buildInfoRow('RAM', '${request.ram} GB'),
                      _buildInfoRow('Disk', '${request.disk} GB'),
                      _buildInfoRow('Processor', request.processor),
                      _buildInfoRow('Goals', request.goals),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideY(delay: 400.ms),
                  if (request.status.toLowerCase() == 'pending') ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleAccept(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lightColorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Accept',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: lightColorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleDecline(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lightColorScheme.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Decline',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: lightColorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms).slideY(delay: 500.ms),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: lightColorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: lightColorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: lightColorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: lightColorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}