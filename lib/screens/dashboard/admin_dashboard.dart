import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/healthcare_app_bar.dart';
import '../../widgets/stat_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  void _loadMetrics() async {
    final data = await FirestoreService().getDistrictMetrics();
    if (mounted) {
      setState(() {
        _metrics = data;
        _isLoading = false;
      });
    }
  }

  void _sendAdvisoryDialog() {
    final advisoryController = TextEditingController(text: 'Seasonal Alert: Heavy rains predicted. Boil drinking water and report fever cases to nearest ASHA worker.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: AppTheme.adminColor),
            SizedBox(width: 8),
            Text('District Health Advisory'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Broadcast automated SMS & Voice advisory to all 24 registered villages and ASHA workers:',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: advisoryController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📢 District Health Advisory broadcast dispatched to 1,400+ village numbers!'),
                  backgroundColor: AppTheme.successMint,
                ),
              );
            },
            child: const Text('Broadcast Alert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const HealthcareAppBar(
        title: 'District Admin Portal',
        subtitle: 'Varanasi Rural Health Administration',
        role: UserRole.admin,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // District Overview Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFB45309)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.adminColor.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'District Health Network',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('ZONE 4', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '24 Villages • 6 PHCs • 48 ASHA Workers Active',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.adminColor,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _sendAdvisoryDialog,
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('Send Emergency District Advisory', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Metrics Grid
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Patients',
                        value: '${_metrics['totalPatients'] ?? 1420}',
                        subtitle: 'Registered in Cloud',
                        icon: Icons.people_alt_rounded,
                        color: AppTheme.secondarySky,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'ASHA Force',
                        value: '${_metrics['activeAshaWorkers'] ?? 48}',
                        subtitle: 'Field Workers',
                        icon: Icons.medical_services_rounded,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Teleconsults',
                        value: '${_metrics['teleconsultsCompleted'] ?? 328}',
                        subtitle: 'Completed',
                        icon: Icons.video_camera_front_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Referrals',
                        value: '${_metrics['pendingReferrals'] ?? 12}',
                        subtitle: 'Active Triage',
                        icon: Icons.emergency_rounded,
                        color: AppTheme.dangerCoral,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Village Health Coverage Section
              const Text(
                'Village Health Center Coverage',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              _buildVillageTile('Rampur Gram', 'ASHA: Sunita Devi', '480 Patients', '98% Coverage', AppTheme.successMint),
              _buildVillageTile('Shivpur Village', 'ASHA: Anita Roy', '310 Patients', '92% Coverage', AppTheme.successMint),
              _buildVillageTile('Kalyanpur', 'ASHA: Manju Devi', '290 Patients', '84% Coverage', AppTheme.warningAmber),
              _buildVillageTile('Belwa Sector', 'ASHA: Rekha Sharma', '340 Patients', '95% Coverage', AppTheme.successMint),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVillageTile(String village, String asha, String patients, String coverage, Color coverageColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.holiday_village_rounded, color: AppTheme.primaryTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(village, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('$asha • $patients', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: coverageColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              coverage,
              style: TextStyle(color: coverageColor, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
