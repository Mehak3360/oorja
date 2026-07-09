import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/room_provider.dart';
import '../theme/app_theme.dart';
import 'room_details_screen.dart';
import '../repositories/appliance_repository.dart';
import '../repositories/home_repository.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to rooms as soon as this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<app_auth.AuthProvider>().currentUser!.uid;
      context.read<RoomProvider>().listenToRooms(uid);
    });
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

    return Scaffold(
      backgroundColor: AppTheme.navyBackground,
      appBar: AppBar(title: const Text('Rooms')),
      body: roomProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roomProvider.rooms.isEmpty
              ? Center(
                  child: Text(
                    'No rooms yet.\nTap + to add your first room.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: roomProvider.rooms.length,
                  itemBuilder: (context, index) {
                    final room = roomProvider.rooms[index];
                    return Card(
                      color: AppTheme.cardBackground,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailsScreen(room: room),
                            ),
                          );
                        },
                        onLongPress: () async {
                          await context.read<RoomProvider>().deleteRoom(room.roomId);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FutureBuilder(
                            future: HomeRepository().getHome(
                              context.read<app_auth.AuthProvider>().currentUser!.uid,
                            ),
                            builder: (context, homeSnapshot) {
                              final tariff = homeSnapshot.data?.tariffPerUnit ?? 0;

                              return StreamBuilder<List<dynamic>>(
                                stream: ApplianceRepository().watchAppliances(room.roomId),
                                builder: (context, snapshot) {
                                  final appliances = snapshot.data ?? [];
                                  final count = appliances.length;
                                  final totalUnits = appliances.fold<double>(
                                    0,
                                    (sum, a) => sum + (a.monthlyUnits as double),
                                  );
                                  final totalCost = totalUnits * tariff;

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.meeting_room_outlined,
                                          size: 36, color: AppTheme.primaryBlue),
                                      const SizedBox(height: 12),
                                      Text(
                                        room.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        room.type,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$count appliance${count == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.accentBlue,
                                        ),
                                      ),
                                      Text(
                                        '${totalUnits.toStringAsFixed(1)} units/mo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '₹${totalCost.toStringAsFixed(0)}/mo',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
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