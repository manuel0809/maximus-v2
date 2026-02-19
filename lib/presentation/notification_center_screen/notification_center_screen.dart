import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/notification_card_widget.dart';
import './widgets/notification_filter_chip_widget.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> filteredNotifications = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String selectedFilter = 'all';
  String searchQuery = '';
  int unreadCount = 0;

  List<Map<String, String>> get filters => [
    {'id': 'all', 'labelKey': 'all_notifications'},
    {'id': 'booking_status', 'labelKey': 'bookings_notifications'},
    {'id': 'driver_assigned', 'labelKey': 'driver_notifications'},
    {'id': 'trip_completed', 'labelKey': 'trips_notifications'},
    {'id': 'promotion', 'labelKey': 'promotions'},
    {'id': 'unread', 'labelKey': 'unread'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _notificationService.unsubscribe();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => isLoading = true);
      final data = await _notificationService.getNotifications();
      setState(() {
        notifications = data;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar notificaciones: $e')),
        );
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      setState(() => unreadCount = count);
    } catch (e) {
      // Silent fail
    }
  }

  void _subscribeToNotifications() {
    _notificationService.subscribeToNotifications((notification) {
      setState(() {
        notifications.insert(0, notification);
        _applyFilters();
        unreadCount++;
      });
    });
  }

  Future<void> _refreshNotifications() async {
    setState(() => isRefreshing = true);
    await _loadNotifications();
    await _loadUnreadCount();
    setState(() => isRefreshing = false);
  }

  void _applyFilters() {
    filteredNotifications = notifications.where((notification) {
      // Apply type filter
      if (selectedFilter != 'all' && selectedFilter != 'unread') {
        if (notification['type'] != selectedFilter) return false;
      }

      // Apply unread filter
      if (selectedFilter == 'unread') {
        if (notification['is_read'] == true) return false;
      }

      // Apply search filter
      if (searchQuery.isNotEmpty) {
        final title = (notification['title'] ?? '').toLowerCase();
        final body = (notification['body'] ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();
        if (!title.contains(query) && !body.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      setState(() {
        final index = notifications.indexWhere(
          (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          notifications[index]['is_read'] = true;
          notifications[index]['read_at'] = DateTime.now().toIso8601String();
        }
        _applyFilters();
        if (unreadCount > 0) unreadCount--;
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      setState(() {
        for (var notification in notifications) {
          notification['is_read'] = true;
          notification['read_at'] = DateTime.now().toIso8601String();
        }
        _applyFilters();
        unreadCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      setState(() {
        notifications.removeWhere((n) => n['id'] == notificationId);
        _applyFilters();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notificación eliminada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          appBar: CustomAppBar(
            title: localization.translate('notifications'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: _markAllAsRead,
                tooltip: localization.translate('mark_all_read'),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Filter Chips
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filters.map((filter) {
                        return Padding(
                          padding: EdgeInsets.only(right: 2.w),
                          child: NotificationFilterChipWidget(
                            label: localization.translate(filter['labelKey']!),
                            isSelected: selectedFilter == filter['id'],
                            onTap: () {
                              setState(() {
                                selectedFilter = filter['id']!;
                                _applyFilters();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Search bar
                Container(
                  padding: EdgeInsets.all(3.w),
                  color: theme.colorScheme.primary,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _applyFilters();
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar notificaciones...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.primary.withAlpha(179),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.primary.withAlpha(179),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.primary.withAlpha(38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.5.h,
                      ),
                    ),
                  ),
                ),

                // Notifications list
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : filteredNotifications.isEmpty
                      ? _buildEmptyState(theme.colorScheme)
                      : RefreshIndicator(
                          onRefresh: _refreshNotifications,
                          color: theme.colorScheme.primary,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            itemCount: filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notification = filteredNotifications[index];
                              return NotificationCardWidget(
                                notification: notification,
                                onTap: () {
                                  if (notification['is_read'] == false) {
                                    _markAsRead(notification['id']);
                                  }
                                },
                                onDelete: () {
                                  _deleteNotification(notification['id']);
                                },
                                onMarkAsRead: () {
                                  _markAsRead(notification['id']);
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: colorScheme.onSurface.withAlpha(77),
          ),
          SizedBox(height: 2.h),
          Text(
            selectedFilter == 'unread'
                ? 'No hay notificaciones sin leer'
                : 'No hay notificaciones',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Las notificaciones aparecerán aquí',
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withAlpha(102),
            ),
          ),
        ],
      ),
    );
  }
}
