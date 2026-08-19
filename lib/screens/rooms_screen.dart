import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/room_provider.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import 'room_details_screen.dart';
import '../repositories/appliance_repository.dart';
import '../repositories/home_repository.dart';
import '../models/appliance_model.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;
      context.read<RoomProvider>().listenToRooms(uid);
    });
  }

  IconData _iconForRoomType(String type) {
    switch (type.toLowerCase()) {
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'bathroom':
        return Icons.bathtub_rounded;
      case 'living room':
        return Icons.weekend_rounded;
      case 'bedroom':
        return Icons.bed_rounded;
      case 'study room':
        return Icons.menu_book_rounded;
      case 'dining room':
        return Icons.dining_rounded;
      case 'utility room':
        return Icons.build_rounded;
      default:
        return Icons.meeting_room_rounded;
    }
  }

  void _showAddRoomDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'Bedroom';
    final roomTypes = [
      'Bedroom', 'Kitchen', 'Living Room', 'Bathroom',
      'Study Room', 'Dining Room', 'Utility Room', 'Custom Room',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: const Text('Add Room', style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: AppTheme.cardBackground,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Room Type'),
                    items: roomTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedType = value!);
                      nameController.text = value!;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Room Name'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;
                    await context.read<RoomProvider>().addRoom(
                          uid,
                          nameController.text.trim(),
                          selectedType,
                        );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Add', style: TextStyle(color: AppTheme.accentBlue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(title: const Text('Rooms')),
      body: roomProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roomProvider.rooms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.meeting_room_outlined, color: AppTheme.textMuted, size: 40),
                        const SizedBox(height: 16),
                        const Text(
                          'No rooms yet',
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the + button to add your first room.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : StreamBuilder<List<ApplianceModel>>(
                  // Fetch every appliance across every room once, so each card can
                  // compute its % share of total home consumption without a separate
                  // query per card.
                  stream: ApplianceRepository().watchAllAppliancesForHome(
                    roomProvider.rooms.map((r) => r.roomId).toList(),
                  ),
                  builder: (context, allApplianceSnapshot) {
                    final allAppliances = allApplianceSnapshot.data ?? [];
                    final homeTotalUnits =
                        allAppliances.fold<double>(0, (sum, a) => sum + a.monthlyUnits);

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: roomProvider.rooms.length,
                      itemBuilder: (context, index) {
                        final room = roomProvider.rooms[index];
                        final color = AppTheme.chartPalette[index % AppTheme.chartPalette.length];

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RoomDetailsScreen(room: room)),
                            );
                          },
                          onLongPress: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                backgroundColor: AppTheme.cardBackground,
                                title: const Text('Delete Room?',
                                    style: TextStyle(color: AppTheme.textPrimary)),
                                content: Text(
                                  'This will delete "${room.name}" and all its appliances. This cannot be undone.',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await context.read<RoomProvider>().deleteRoom(room.roomId);
                            }
                          },
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: FutureBuilder(
                              future: HomeRepository().getHome(uid),
                              builder: (context, homeSnapshot) {
                                final tariff = homeSnapshot.data?.tariffPerUnit ?? 0;

                                return StreamBuilder<List<dynamic>>(
                                  stream: ApplianceRepository().watchAppliances(room.roomId),
                                  builder: (context, snapshot) {
                                    final appliances = snapshot.data ?? [];
                                    final count = appliances.length;
                                    final totalUnits = appliances.fold<double>(
                                        0, (sum, a) => sum + (a.monthlyUnits as double));
                                    final totalCost = totalUnits * tariff;
                                    final shareOfHome =
                                        homeTotalUnits > 0 ? (totalUnits / homeTotalUnits) : 0.0;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.16),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(_iconForRoomType(room.type),
                                                  color: color, size: 22),
                                            ),
                                            const Spacer(),
                                            if (homeTotalUnits > 0)
                                              Text(
                                                '${(shareOfHome * 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          room.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$count appliance${count == 1 ? '' : 's'} · ${totalUnits.toStringAsFixed(0)} u/mo',
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${totalCost.toStringAsFixed(0)}/mo',
                                          style: TextStyle(
                                              color: color, fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 10),
                                        // Share-of-home indicator bar — gives the card real
                                        // information instead of empty space, and lets you see
                                        // at a glance which room is your biggest energy drain.
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: shareOfHome.clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoomDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }
}