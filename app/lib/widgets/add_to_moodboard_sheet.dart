import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme_config.dart';
import '../models/moodboard.dart';
import '../services/supabase_service.dart';
import 'create_moodboard_dialog.dart';

class AddToMoodboardSheet extends StatefulWidget {
  final String wallpaperId;

  const AddToMoodboardSheet({super.key, required this.wallpaperId});

  @override
  State<AddToMoodboardSheet> createState() => _AddToMoodboardSheetState();
}

class _AddToMoodboardSheetState extends State<AddToMoodboardSheet> {
  List<Moodboard> _moodboards = [];
  Set<String> _alreadyAdded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final boards = await SupabaseService.instance.fetchMoodboards(user.id);
    final added = await SupabaseService.instance.fetchMoodboardItemIds(widget.wallpaperId);

    if (mounted) {
      setState(() {
        _moodboards = boards;
        _alreadyAdded = added;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(Moodboard board) async {
    HapticFeedback.lightImpact();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_alreadyAdded.contains(board.id)) {
      final success = await SupabaseService.instance.removeFromMoodboard(board.id, widget.wallpaperId);
      if (success) {
        setState(() => _alreadyAdded.remove(board.id));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove from moodboard'), behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      final success = await SupabaseService.instance.addToMoodboard(board.id, widget.wallpaperId);
      if (success) {
        setState(() => _alreadyAdded.add(board.id));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add to moodboard'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = context.vivek;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: v.surfaceContainer.withValues(alpha: 0.88),
            border: Border(top: BorderSide(color: v.glassBorder.withValues(alpha: 0.3), width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48, height: 5,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3)),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.5, end: 0),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('ADD TO MOODBOARD', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: cs.onSurface)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      showCreateDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 16, color: cs.primary),
                          const SizedBox(width: 4),
                          Text('NEW', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: cs.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                Padding(padding: const EdgeInsets.all(32), child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2))
              else if (_moodboards.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text('No moodboards found. Tap NEW to create one!', style: GoogleFonts.inter(color: v.onSurfaceSubtle, fontSize: 14)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _moodboards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final board = _moodboards[index];
                      final isAdded = _alreadyAdded.contains(board.id);
                      return GestureDetector(
                        onTap: () => _toggle(board),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: isAdded ? cs.primary.withValues(alpha: 0.15) : v.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isAdded ? cs.primary : v.glassBorder.withValues(alpha: 0.15), width: isAdded ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                color: isAdded ? cs.primary : v.onSurfaceSubtle,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(board.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                                    Text('${board.itemCount} item${board.itemCount == 1 ? '' : 's'}', style: GoogleFonts.inter(fontSize: 12, color: v.onSurfaceSubtle)),
                                  ],
                                ),
                              ),
                              Icon(isAdded ? Icons.remove_rounded : Icons.add_rounded, color: isAdded ? cs.primary : v.onSurfaceSubtle, size: 20),
                            ],
                          ),
                        ),
                      ).animate().fade(duration: 300.ms, delay: (index * 40).ms).slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateMoodboardDialog(onCreate: _createMoodboard),
    );
  }

  Future<void> _createMoodboard(String name) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await SupabaseService.instance.createMoodboard(user.id, name);
    if (mounted) _load();
  }
}
