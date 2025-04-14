import 'package:flutter/material.dart';
import '../../models/virtualization_env.dart';
import '../../services/virtualization_env_service.dart';

class RequesterInfoScreen extends StatelessWidget {
  final VirtualizationEnv request;

  const RequesterInfoScreen({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Requester Info'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              title: 'Lab Request Details',
              children: [
                _buildInfoRow('Lab Type', request.type),
                _buildInfoRow('RAM', '${request.ram} GB'),
                _buildInfoRow('Disk', '${request.disk} GB'),
                _buildInfoRow('Processor', request.processor),
                _buildInfoRow('Goals', request.goals),
              ],
            ),
            SizedBox(height: 24),
            if (request.status == 'Pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await VirtualizationEnvService().acceptLabRequest(request.id, {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Request accepted!')),
                        );
                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to accept request: $e')),
                        );
                      }
                    },
                    child: Text('Accept'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await VirtualizationEnvService().declineLabRequest(request.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Request declined!')),
                        );
                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to decline request: $e')),
                        );
                      }
                    },
                    child: Text('Decline'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}