import 'package:flutter/material.dart';
import 'package:marooneen/models/class_model.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:marooneen/pages/attendance_screen.dart';

class ClassCard extends StatefulWidget {
  const ClassCard({super.key, required this.kelas});
  final ClassModel kelas;

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard> {
  bool _isLoading = false;

  Future<void> _handleAttend() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceScreen(kelas: widget.kelas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(LucideIcons.book, color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.kelas.kelas,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: accentColor4),
                      color: accentColor3,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar, color: accentColor4),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.kelas.tanggal.day}-${widget.kelas.tanggal.month}-${widget.kelas.tanggal.year}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(LucideIcons.blocks, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Pertemuan ke-${widget.kelas.pertemuan}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.kelas.tipeKelas.toLowerCase() == 'online'
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      border: Border.all(
                        color: widget.kelas.tipeKelas.toLowerCase() == 'online'
                            ? Colors.blue
                            : Colors.orange,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.kelas.tipeKelas.toUpperCase(),
                      style: TextStyle(
                        color: widget.kelas.tipeKelas.toLowerCase() == 'online'
                            ? Colors.blue.shade300
                            : Colors.orange.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    widget.kelas.tipeKelas.toLowerCase() == 'online'
                        ? LucideIcons.globe
                        : LucideIcons.pin,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.kelas.tipeKelas.toLowerCase() == 'online'
                        ? "Kelas Online"
                        : widget.kelas.tempat,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(LucideIcons.clock, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    widget.kelas.jam,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ShadButton(
                  decoration: ShadDecoration(
                    shape: BoxShape.rectangle,
                    border: ShadBorder.all(
                      radius: const BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  width: 350,
                  onPressed: _isLoading ? null : _handleAttend,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Attend',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
