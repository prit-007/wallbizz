import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';
import '../models/wallpaper.dart';
import '../services/download_service.dart';
import '../services/downloads_service.dart';
import '../services/supabase_service.dart';
import '../services/wallpaper_actions.dart';
import '../utils/color_utils.dart';
import '../widgets/specs_card.dart';
import '../widgets/network_image.dart';
import 'wallpaper_editor_screen.dart';

class DetailScreen extends StatefulWidget {
  final Wallpaper wallpaper;

  const DetailScreen({super.key, required this.wallpaper});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isWishlisted = false;
  final TransformationController _transformController = TransformationController();

  Wallpaper get wallpaper => widget.wallpaper;

  @override
  void initState() {
    super.initState();
    _checkDownloadState();
    _checkWishlist();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _checkDownloadState() {
    if (!kIsWeb) setState(() => _isDownloaded = DownloadsService.isDownloaded(wallpaper.wallhavenId));
  }

  Future<void> _checkWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final inList = await SupabaseService.instance.isInWishlist(user.id, wallpaper.id);
      if (mounted) setState(() => _isWishlisted = inList);
    } catch (_) {}
  }

  void _onHeartTap() {
    WallpaperActions.handleHeartTap(
      context,
      wallpaper,
      onComplete: () => setState(() => _isWishlisted = !_isWishlisted),
    );
  }

  void _resetZoom() => _transformController.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final ambientColor = ColorUtils.hexToColor(wallpaper.primaryColor);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(ambientColor.withValues(alpha: 0.6), BlendMode.srcOver),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 1.5,
                height: MediaQuery.of(context).size.height * 1.5,
                child: Transform.translate(
                  offset: Offset(-MediaQuery.of(context).size.width * 0.25, -MediaQuery.of(context).size.height * 0.25),
                  child: NetworkImageWidget(imageUrl: wallpaper.urlFull, fit: BoxFit.cover),
                ),
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                stops: const [0.2, 1.0],
              ),
            ),
          ),

          GestureDetector(
            onDoubleTap: () {
              if (_transformController.value != Matrix4.identity()) {
                _resetZoom();
              } else {
                _transformController.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
              }
            },
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(child: NetworkImageWidget(imageUrl: wallpaper.urlFull, fit: BoxFit.contain)),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.95)],
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _buildFrostedButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFrostedButton(
                  icon: _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: _isWishlisted ? Colors.redAccent : Colors.white,
                  onTap: _onHeartTap,
                ),
                const SizedBox(width: 12),
                _buildFrostedButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () => _shareWallpaper(context),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpecsCard(wallpaper: wallpaper),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : () => _downloadWallpaper(context),
                      icon: _isDownloading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded),
                      label: Text(
                        _isDownloading ? 'DOWNLOADING...' : (_isDownloaded ? 'DOWNLOADED' : 'DOWNLOAD WALLPAPER'),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDownloaded ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.white.withValues(alpha: _isDownloaded ? 0.1 : 0.3)),
                      ),
                    ),
                  ),

                  if (!kIsWeb) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _setWallpaper(context),
                        icon: const Icon(Icons.wallpaper_rounded, color: Colors.white),
                        label: Text(
                          'SET AS WALLPAPER',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ambientColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic).fade(),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedButton({required IconData icon, required VoidCallback onTap, Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadWallpaper(BuildContext context) async {
    if (_isDownloaded || _isDownloading) return;
    final imageUrl = kIsWeb ? BackendConfig.proxyImageUrl(wallpaper.urlFull) : wallpaper.urlFull;
    final progress = ValueNotifier<double>(0.0);
    final fileName = DownloadService.fileNameFromUrl(wallpaper.urlFull);
    setState(() => _isDownloading = true);
    showGlassmorphismProgress(context, progress);

    try {
      await DownloadService.downloadImage(imageUrl: imageUrl, fileName: fileName, onProgress: (p) => progress.value = p);
      if (!kIsWeb) await DownloadsService.downloadAndSave(wallpaper);
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() { _isDownloading = false; _isDownloaded = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Download complete!'), backgroundColor: Colors.black.withValues(alpha: 0.9)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void showGlassmorphismProgress(BuildContext context, ValueNotifier<double> progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => PopScope(
        canPop: false,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: progress,
                    builder: (_, value, _) => SizedBox(
                      width: 80, height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: value > 0 ? value : null,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(ColorUtils.hexToColor(wallpaper.primaryColor)),
                          ),
                          Center(
                            child: value > 0
                                ? Text('${(value * 100).toInt()}%', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                                : Icon(Icons.cloud_download_rounded, color: Colors.white.withValues(alpha: 0.8), size: 32),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutCubic),
                  const SizedBox(height: 24),
                  Text('DOWNLOADING', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white))
                    .animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 4),
                  Text(wallpaper.resolution.replaceAll('x', ' \u00d7 '), style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)))
                    .animate().fade(duration: 400.ms, delay: 180.ms),
                ],
              ),
            ).animate().fade(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }

  void _setWallpaper(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WallpaperEditorScreen(localPath: '', urlFull: wallpaper.urlFull, primaryColor: wallpaper.primaryColor, resolution: wallpaper.resolution, width: wallpaper.width, height: wallpaper.height),
    ));
  }

  void _shareWallpaper(BuildContext context) {
    Share.share('Check out this wallpaper from Wallbizz!\n${wallpaper.urlFull}', subject: 'Wallbizz Wallpapers');
  }
}
