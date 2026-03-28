import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  final String userNpm;

  const NotificationScreen({super.key, required this.userNpm});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<String> _readBroadcasts = [];

  @override   
  void initState() {
    super.initState();
    _loadReadBroadcasts();
  }

  Future<void> _loadReadBroadcasts() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _readBroadcasts = prefs.getStringList('readBroadcasts') ?? [];
      });
    }
  }

  Future<void> _markBroadcastAsRead(String docId) async {
    if (_readBroadcasts.contains(docId)) return;
    final prefs = await SharedPreferences.getInstance();
    _readBroadcasts.add(docId);
    await prefs.setStringList('readBroadcasts', _readBroadcasts);
    if (mounted) {
      setState(() {}); // Refresh list
    }
  }

  // ==== FUNCTION UPDATE isRead ====
  Future<void> _markAsRead(String docId, bool currentIsRead) async {
    if (currentIsRead) return; // Jika sudah terbaca, tidak perlu update lagi

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint("Gagal update isRead: $e");
    }
  }

  // ==== FUNCTION BUKA DIALOG & UPDATE ====
  void _openNotificationDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    // 1. Update ke Firestore jika bukan broadcast, Update Local jika broadcast
    if (data['isBroadcast'] == false) {
      _markAsRead(docId, data['isRead'] ?? false);
    } else {
      _markBroadcastAsRead(docId);
    }

    // Tentukan icon & warna
    IconData iconData;
    Color iconColor;
    String diagTitle;

    if (data['isBroadcast'] == true) {
      iconData = Icons.cell_tower; // Ikon khusus broadcast
      iconColor = Colors.purple.shade600;
      diagTitle = 'Detail Broadcast';
    } else if (data['type'] == 'announcement') {
      iconData = Icons.campaign;
      iconColor = Colors.blue.shade600;
      diagTitle = 'Detail Pengumuman';
    } else {
      iconData = Icons.assignment_turned_in;
      iconColor = Colors.green.shade600;
      diagTitle = 'Update Tiket Masalah';
    }

    // 2. Tampilkan Dialog Detail
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(iconData, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  diagTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['isBroadcast'] == true && data['title'] != null) ...[
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                data['message'] ?? 'Tidak ada pesan',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (data['isBroadcast'] == true && data['sender'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Dari: ${data['sender']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          contentPadding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: secondaryColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ==== STREAM 1: NOTIFICATIONS ====
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userNpm', whereIn: [widget.userNpm, 'all'])
            // Kita sorting manual di Dart untuk menghindari requirement Composite Index ribet
            .snapshots(),
        builder: (context, notifSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            // ==== STREAM 2: BROADCASTS ====
            stream: FirebaseFirestore.instance
                .collection('broadcasts')
                .snapshots(),
            builder: (context, broadcastSnapshot) {
              if (notifSnapshot.connectionState == ConnectionState.waiting &&
                  broadcastSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (notifSnapshot.hasError || broadcastSnapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Terjadi kesalahan saat memuat data dari Firestore.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        '${notifSnapshot.error ?? broadcastSnapshot.error}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Gabungkan Data Secara Manual
              List<Map<String, dynamic>> combinedList = [];

              if (notifSnapshot.hasData && notifSnapshot.data != null) {
                for (var doc in notifSnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  data['isBroadcast'] = false;
                  data['docId'] = doc.id;
                  combinedList.add(data);
                }
              }

              if (broadcastSnapshot.hasData && broadcastSnapshot.data != null) {
                for (var doc in broadcastSnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  data['isBroadcast'] = true;
                  data['docId'] = doc.id;
                  data['type'] = 'broadcast';

                  // Periksa apakah broadcast ini sudah ditekan (ada di SharedPreferences)
                  data['isRead'] = _readBroadcasts.contains(doc.id);

                  combinedList.add(data);
                }
              }

              // Sorting descending (terbaru di atas)
              combinedList.sort((a, b) {
                Timestamp? tA = a['timestamp'] as Timestamp?;
                Timestamp? tB = b['timestamp'] as Timestamp?;
                DateTime timeA =
                    tA?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                DateTime timeB =
                    tB?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                return timeB.compareTo(timeA);
              });

              if (combinedList.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada notifikasi.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: combinedList.length,
                itemBuilder: (context, index) {
                  final data = combinedList[index];
                  final docId = data['docId'];
                  final isBroadcast = data['isBroadcast'] == true;
                  final isRead = data['isRead'] ?? false;
                  final notifType = data['type'] ?? 'announcement';

                  // Format Waktu
                  String timeString = '';
                  if (data['timestamp'] != null) {
                    DateTime time = (data['timestamp'] as Timestamp).toDate();
                    timeString =
                        "${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
                  }

                  // Tentukan UI Icon dan text berdasar tipe
                  IconData listIcon;
                  Color iconColor;
                  Color iconBgColor;
                  String listTitle;

                  if (isBroadcast) {
                    listIcon =
                        Icons.cell_tower; // Icon Sinyal / Tower Broadcast
                    iconColor = Colors.purple.shade700;
                    iconBgColor = Colors.purple.withOpacity(0.1);
                    listTitle = data['title'] ?? 'Broadcast Alert';
                  } else if (notifType == 'announcement') {
                    listIcon = Icons.campaign;
                    iconColor = Colors.blue.shade700;
                    iconBgColor = Colors.blue.withOpacity(0.1);
                    listTitle = 'Pengumuman';
                  } else {
                    listIcon = Icons.assignment_turned_in;
                    iconColor = Colors.green.shade700;
                    iconBgColor = Colors.green.withOpacity(0.1);
                    listTitle = 'Update Tiket Masalah';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? Colors.grey.shade200
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            _openNotificationDialog(context, data, docId),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ─── ICON ───
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconBgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  listIcon,
                                  color: iconColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // ─── CONTENT ───
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listTitle,
                                      style: TextStyle(
                                        fontWeight: isRead
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['message'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isRead
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      timeString,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ─── UNREAD INDICATOR ───
                              if (!isRead)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
