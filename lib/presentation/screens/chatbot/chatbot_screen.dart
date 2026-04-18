import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/chatbot/chatbot_bloc.dart';
import '../../blocs/chatbot/chatbot_event_state.dart';
import '../../blocs/health/health_bloc.dart';
import '../../blocs/prescription/prescription_bloc.dart';
import '../../blocs/health/health_event_state.dart';
import '../../blocs/prescription/prescription_event_state.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Wait 600ms for global Hive Repositories (Prescriptions/Vitals) to finish 
      // loading their offline lists into BLoC state before sniffing them.
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _initializeContextForGemini();
      });
    }
  }

  void _initializeContextForGemini() {
    // Collect the user's latest health and prescription data to inject into Gemini context
    final healthState = context.read<HealthBloc>().state;
    final rxState = context.read<PrescriptionBloc>().state;

    List<Map<String, dynamic>> vitalsJson = [];
    if (healthState is HealthLoaded) {
      vitalsJson = healthState.vitals.map((v) => {
        'date': v.timestamp.toIso8601String(),
        'blood_pressure': '${v.systolic}/${v.diastolic}',
        'blood_sugar': v.bloodSugar,
        'heart_rate': v.heartRate,
      }).toList();
    }

    List<Map<String, dynamic>> rxJson = [];
    if (rxState is SavedPrescriptionsLoaded) {
      rxJson = rxState.prescriptions.map((p) => {
        'doctor_name': p.doctorName,
        'clinic_name': p.clinicName,
        'date_visited': p.savedAt.toIso8601String(),
        'medicines': p.medicineNames,
      }).toList();
    }

    final systemContext = '''
Vitals Data: ${jsonEncode(vitalsJson)}
Prescriptions Data: ${jsonEncode(rxJson)}
''';

    context.read<ChatbotBloc>().add(InitializeChatbotSession(systemContext));
  }

  void _resetContextForGemini() {
    final healthState = context.read<HealthBloc>().state;
    final rxState = context.read<PrescriptionBloc>().state;

    List<Map<String, dynamic>> vitalsJson = [];
    if (healthState is HealthLoaded) {
      vitalsJson = healthState.vitals.map((v) => {
        'date': v.timestamp.toIso8601String(),
        'blood_pressure': '${v.systolic}/${v.diastolic}',
        'blood_sugar': v.bloodSugar,
        'heart_rate': v.heartRate,
      }).toList();
    }

    List<Map<String, dynamic>> rxJson = [];
    if (rxState is SavedPrescriptionsLoaded) {
      rxJson = rxState.prescriptions.map((p) => {
        'doctor_name': p.doctorName,
        'clinic_name': p.clinicName,
        'date_visited': p.savedAt.toIso8601String(),
        'medicines': p.medicineNames,
      }).toList();
    }

    final systemContext = '''
Vitals Data: ${jsonEncode(vitalsJson)}
Prescriptions Data: ${jsonEncode(rxJson)}
''';

    context.read<ChatbotBloc>().add(ResetChatbotSession(systemContext));
  }

  void _sendMessage([String? textValue]) {
    final text = textValue ?? _messageController.text.trim();
    if (text.isEmpty) return;

    final bloc = context.read<ChatbotBloc>();
    if (bloc.state is! ChatbotReady) return;

    if (textValue == null) {
      _messageController.clear();
    }

    bloc.add(SendMessageEvent(text));

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MedAssist AI',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'English · Urdu',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Reset Chat & Refresh Records',
            onPressed: _resetContextForGemini,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<ChatbotBloc, ChatbotState>(
        listener: (context, state) {
          if (state is ChatbotError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
          if (state is ChatbotReady && !state.isTyping) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state is ChatbotInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final messages = state.messages;

          return Column(
            children: [
              // Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length + (state.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildBubble(messages[index]);
                  },
                ),
              ),

              // Quick Replies
              if (messages.length <= 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickReply('When did I visit the doctor last?'),
                        _buildQuickReply('What were my last vitals?'),
                        _buildQuickReply('میرا بلڈ پریشر؟'),
                      ],
                    ),
                  ),
                ),

              // Input Bar
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: (_) => _sendMessage(),
                        textInputAction: TextInputAction.send,
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Type your question...',
                          hintStyle: GoogleFonts.inter(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send Button
                    GestureDetector(
                      onTap: () => _sendMessage(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: msg.isUser ? 48 : 0,
        right: msg.isUser ? 0 : 48,
      ),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: msg.isUser ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
              bottomRight: Radius.circular(msg.isUser ? 4 : 18),
            ),
            border: msg.isUser ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: msg.isUser ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12, right: 48),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 40,
          height: 20,
          child: LinearProgressIndicator(color: AppColors.primaryLight),
        ),
      ),
    );
  }

  Widget _buildQuickReply(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _messageController.text = text;
          _sendMessage(text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
