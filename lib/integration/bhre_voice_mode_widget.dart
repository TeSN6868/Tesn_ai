import 'package:flutter/material.dart';

import 'bhre_voice_conversation_controller.dart';

class BhreVoiceModeWidget extends StatefulWidget {
  final BhreVoiceConversationController controller;

  const BhreVoiceModeWidget({super.key, required this.controller});

  @override
  State<BhreVoiceModeWidget> createState() => _BhreVoiceModeWidgetState();
}

class _BhreVoiceModeWidgetState extends State<BhreVoiceModeWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (widget.controller.isEnabled) {
      await widget.controller.stop();
    } else {
      await widget.controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final enabled = controller.isEnabled;

    String status;

    if (!enabled) {
      status = 'Bree OFF • Mode teks';
    } else if (controller.isListening) {
      status = 'Bree ON • Mendengarkan';
    } else if (controller.isThinking) {
      status = 'Bree ON • Memproses';
    } else if (controller.isSpeaking) {
      status = 'Bree ON • Berbicara';
    } else if (controller.error != null) {
      status = 'Bree • Perlu perhatian';
    } else {
      status = 'Bree ON';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _toggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFF0B5ED7).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF0B5ED7).withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                size: 20,
                color: enabled
                    ? const Color(0xFF0B5ED7)
                    : const Color(0xFF17324D),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? const Color(0xFF0B5ED7)
                      : const Color(0xFF17324D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BhreVoiceAssistantCard extends StatelessWidget {
  final BhreVoiceConversationController controller;

  const BhreVoiceAssistantCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final enabled = controller.isEnabled;

    if (!enabled) {
      return const SizedBox.shrink();
    }

    final String status;
    final IconData icon;

    if (controller.isListening) {
      status = 'Aku mendengarkan...';
      icon = Icons.mic_rounded;
    } else if (controller.isThinking) {
      status = 'Aku sedang memproses...';
      icon = Icons.psychology_rounded;
    } else if (controller.isSpeaking) {
      status = 'Bree sedang berbicara...';
      icon = Icons.volume_up_rounded;
    } else {
      status = 'Bree siap.';
      icon = Icons.assistant_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B5ED7), Color(0xFF6FAED1), Color(0xFFF5FAFD)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 5),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            child: Icon(icon, color: const Color(0xFF0B5ED7), size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bree',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (controller.lastTranscript.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '“${controller.lastTranscript}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
