import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../theme/app_theme.dart';

class InputBar extends StatefulWidget {
  final Function(String) onSend;
  final Function(XFile image, String? caption) onImageSend;

  const InputBar({super.key, required this.onSend, required this.onImageSend});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _speech = SpeechToText();
  final _imagePicker = ImagePicker();

  bool _hasText = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  XFile? _capturedImage;
  Uint8List? _capturedThumb;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });

    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ── Speech ──────────────────────────────────────────────────────────────────

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
          if (_isListening && mounted) {
            setState(() => _isListening = false);
            _pulseController.stop();
            _pulseController.reset();
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    _textController.clear();

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _stopAndSend();
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_IN',
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );

    if (_speech.isListening && mounted) {
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopAndSend() {
    _speech.stop();
    _pulseController.stop();
    _pulseController.reset();
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _textController.clear();
    }
    if (mounted) setState(() => _isListening = false);
  }

  // ── Camera ──────────────────────────────────────────────────────────────────

  Future<void> _captureImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    );
    _setPickedImage(file);
  }

  Future<void> _pickFromGallery() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    _setPickedImage(file);
  }

  Future<void> _setPickedImage(XFile? file) async {
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _capturedImage = file;
      _capturedThumb = bytes;
    });
  }

  void _clearImage() {
    setState(() {
      _capturedImage = null;
      _capturedThumb = null;
    });
  }

  Future<void> _showImageOptionsSheet() async {
    final colorScheme = context.colorScheme;

    await material.showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetImageOption(
                  label: 'Camera',
                  icon: Icons.camera_alt_rounded,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _captureImage();
                  },
                ),
                const Gap(8),
                _SheetImageOption(
                  label: 'Upload',
                  icon: Icons.photo_library_rounded,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Send ────────────────────────────────────────────────────────────────────

  void _handleSend() {
    if (_isListening) {
      _stopAndSend();
      return;
    }

    final text = _textController.text.trim();

    if (_capturedImage != null) {
      widget.onImageSend(_capturedImage!, text.isEmpty ? null : text);
      _textController.clear();
      _clearImage();
      return;
    }

    if (text.isEmpty) return;
    widget.onSend(text);
    _textController.clear();
  }

  bool get _canSend => _hasText || _isListening || _capturedImage != null;

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isListening ? AppTheme.red.withValues(alpha: 0.6) : colorScheme.border,
          width: _isListening ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // ── Text input / listening indicator ────────────────────────────
          Stack(
            children: [
              TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                placeholder: Text(
                  _isListening
                      ? 'Listening...'
                      : 'Type a message or ask about your\nspending...',
                  style: AppTheme.bodyText.copyWith(
                    color: _isListening
                        ? AppTheme.red.withValues(alpha: 0.7)
                        : colorScheme.mutedForeground,
                    height: 1.5,
                  ),
                ),
                style: AppTheme.bodyText.copyWith(color: colorScheme.foreground),
                border: const Border(),
                onSubmitted: (_) => _handleSend(),
              ),

              Positioned(
                top: 10,
                right: 12,
                child: AnimatedOpacity(
                  opacity: _isListening ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withValues(
                            alpha: 0.15 + 0.1 * _pulseController.value,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.red.withValues(
                                  alpha: 0.5 + 0.5 * _pulseController.value,
                                ),
                              ),
                            ),
                            const Gap(5),
                            Text(
                              'REC',
                              style: AppTheme.caption.copyWith(
                                fontSize: 10,
                                color: AppTheme.red,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // ── Image preview strip (shown when a photo is captured) ───────
          if (_capturedThumb != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _capturedThumb!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Photo attached',
                      style: AppTheme.caption.copyWith(
                        color: colorScheme.mutedForeground,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.foreground.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colorScheme.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Divider ────────────────────────────────────────────────────
          Container(
            height: 1,
            color: colorScheme.border,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // ── Bottom action row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? AppTheme.red.withValues(
                                  alpha: 0.12 + 0.08 * _pulseController.value,
                                )
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            size: 24,
                            color: _isListening ? AppTheme.red : colorScheme.foreground,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(8),
                _IconBtn(
                  icon: Icons.image_outlined,
                  onTap: _showImageOptionsSheet,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _canSend ? _handleSend : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _canSend
                          ? colorScheme.foreground
                          : colorScheme.foreground.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: colorScheme.background,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(icon, size: 24, color: context.colorScheme.foreground),
        ),
      ),
    );
  }
}

class _SheetImageOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SheetImageOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.colorScheme.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.colorScheme.foreground),
            const Gap(10),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                color: context.colorScheme.foreground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
