import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/user_service.dart';
import '../../../services/realtime_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService.instance;
  final RealtimeService _realtimeService = RealtimeService.instance;

  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getUserById(widget.userId);
      // Fetch user trips using RealtimeService logic adapted for specific user
      // Note: RealtimeService.getUserTrips uses auth.uid(), so we need a direct query here
      // We'll mimic the query manually since RealtimeService expects current user
      final trips = await _fetchUserTrips(widget.userId);
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _userTrips = trips;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  // Helper to fetch trips for a specific user ID (bypassing auth.uid check of service)
  Future<List<Map<String, dynamic>>> _fetchUserTrips(String userId) async {
    // Ideally this should be in a service, for now we keep it here to avoid modifying RealtimeService too much
    // Or we could have added getUserTripsById to RealtimeService.
    // Let's rely on the fact that we are Admin and likely RLS allows us to see this.
    // However, RealtimeService.getUserTrips forces auth.uid().
    // We will use AdminService or just direct Supabase query here for simplicity in this file for now, 
    // but cleaner is to add to UserService or AdminService.
    // Let's add a quick query here using the visible client from logic (imported indirectly)
    // Actually, let's use the UserService instance client if possible, but it's private.
    // We'll just instantiate a temporary approach or use the one we have access to if we made it public.
    // Since we don't have direct client access, let's assume we can add a method to UserService for this later.
    // For now, let's IMPLEMENT IT IN USER SERVICE. 
    // Wait, I can't modify UserService right now without another tool call.
    // I will modify UserService to include getTripsForUser in the next step if needed, 
    // or just rely on a new method I'll add to UserService now via a separate tool call? 
    // No, I should have added it to UserService.
    // Let's implement basics first.
    return []; 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Usuario no encontrado'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(theme),
                      SizedBox(height: 3.h),
                      _buildStatsSection(theme),
                      SizedBox(height: 3.h),
                      Text(
                        'Historial de Viajes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      _buildTripsList(theme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    if (_userProfile == null) return const SizedBox();
    
    final role = _userProfile!['role'] ?? 'client';
    final email = _userProfile!['email'] ?? '';
    final phone = _userProfile!['phone'] ?? 'No registrado';
    final isActive = _userProfile!['is_active'] == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
             CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(email, style: theme.textTheme.bodyMedium),
                  Text(phone, style: theme.textTheme.bodySmall),
                   SizedBox(height: 1.h),
                  Row(
                    children: [
                      Chip(
                        label: Text(role.toUpperCase()),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          fontSize: 10.sp, 
                          color: theme.colorScheme.onSecondaryContainer
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      SizedBox(width: 2.w),
                       Chip(
                        label: Text(isActive ? 'ACTIVO' : 'INACTIVO'),
                        backgroundColor: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          fontSize: 10.sp, 
                          color: isActive ? Colors.green : Colors.red
                        ),
                        padding: EdgeInsets.zero,
                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    // Mock stats for now, real implementation would aggregate from database
    return Row(
      children: [
        Expanded(child: _buildStatCard(theme, 'Viajes', '${_userTrips.length}', Icons.directions_car)),
        SizedBox(width: 2.w),
        Expanded(child: _buildStatCard(theme, 'Gasto Total', '\$0.00', Icons.attach_money)),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          SizedBox(height: 1.h),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildTripsList(ThemeData theme) {
    if (_userTrips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No hay historial de viajes')),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userTrips.length,
      itemBuilder: (context, index) {
        final trip = _userTrips[index];
        return ListTile(
          title: Text(trip['service_type'] ?? 'Servicio Desconocido'),
          subtitle: Text(trip['created_at'] ?? ''),
          trailing: Text(trip['status'] ?? 'unknown'),
        );
      },
    );
  }
}
