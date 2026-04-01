import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/api_service.dart';

class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({super.key});

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen>
    with SingleTickerProviderStateMixin {
  static const _modeChannel = MethodChannel('com.expensetracker/quickcapture');

  final _imagePicker = ImagePicker();
  final _speech = SpeechToText();

  bool _isListening = false;
  bool _isSending = false;
  bool _speechAvailable = false;

  Uint8List? _imageBytes;
  String? _imageMime;
  String _transcribedText = '';

  String _statusText = 'Choose an action';

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
    _initSpeech();
    _checkLaunchMode();
  }

  Future<void> _checkLaunchMode() async {
    try {
      final mode = await _modeChannel.invokeMethod<String>('getLaunchMode');
      if (!mounted || mode == null || mode.isEmpty) return;
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (mode == 'camera') {
        _capturePhoto();
      } else if (mode == 'mic') {
        _toggleMic();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          if (_isListening && mounted) {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  void _close() {
    SystemNavigator.pop();
  }

  Future<void> _capturePhoto() async {
    setState(() => _statusText = 'Opening camera...');
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (file == null || !mounted) {
      setState(() => _statusText = 'Choose an action');
      return;
    }

    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageMime = file.mimeType ?? 'image/jpeg';
      _transcribedText = '';
      _statusText = 'Photo ready — tap send';
    });
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    setState(() {
      _imageBytes = null;
      _transcribedText = '';
      _statusText = 'Listening...';
    });

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _transcribedText = result.recognizedWords;
            if (result.finalResult && _transcribedText.trim().isNotEmpty) {
              _isListening = false;
              _statusText = 'Ready — tap send';
            }
          });
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
    }
  }

  bool get _canSend =>
      !_isSending && (_imageBytes != null || _transcribedText.trim().isNotEmpty);

  Future<void> _send() async {
    if (!_canSend) return;

    setState(() {
      _isSending = true;
      _statusText = 'Sending...';
    });

    try {
      dynamic data;
      if (_imageBytes != null) {
        data = await ApiService.postMultipart(
          '/chat/image',
          imageBytes: _imageBytes!,
          mimeType: _imageMime ?? 'image/jpeg',
        );
      } else {
        data = await ApiService.post(
          '/chat/message',
          {'message': _transcribedText.trim()},
        );
      }

      final reply = data['reply'] as String? ?? 'Done';
      final expense = data['expense'];

      if (mounted) {
        setState(() {
          _statusText = expense != null ? 'Expense added!' : reply;
          _isSending = false;
          _imageBytes = null;
          _transcribedText = '';
        });

        await Future.delayed(const Duration(seconds: 2));
        _close();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Error — try from the app';
          _isSending = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        _close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _close,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141415),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF27272A)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                          border: Border.all(
                            color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SpendWise',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),

                      if (_imageBytes != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      if (_transcribedText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _transcribedText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            color: const Color(0xFFFF5722),
                            onTap: _isSending ? null : _capturePhoto,
                          ),
                          _ActionButton(
                            icon: _isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            label: _isListening ? 'Stop' : 'Mic',
                            color: _isListening
                                ? const Color(0xFFE53935)
                                : const Color(0xFF14B8A6),
                            onTap: _isSending ? null : _toggleMic,
                          ),
                          _ActionButton(
                            icon: Icons.send_rounded,
                            label: 'Send',
                            color: _canSend
                                ? Colors.white
                                : const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                            onTap: _canSend ? _send : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: _close,
                        child: Text(
                          'Tap outside to close',
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF).withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: enabled ? 0.15 : 0.05),
              border: Border.all(
                color: color.withValues(alpha: enabled ? 0.3 : 0.1),
              ),
            ),
            child: Center(
              child: Icon(icon, size: 24, color: color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: enabled ? 0.8 : 0.3),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
