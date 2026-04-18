import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/chatbot_repository.dart';
import 'chatbot_event_state.dart';

class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final ChatbotRepository _repository;

  ChatbotBloc(this._repository) : super(const ChatbotInitial()) {
    on<InitializeChatbotSession>(_onInitializeSession);
    on<ResetChatbotSession>(_onResetSession);
    on<SendMessageEvent>(_onSendMessage);
  }

  void _onInitializeSession(
    InitializeChatbotSession event,
    Emitter<ChatbotState> emit,
  ) {
    if (state is ChatbotReady && state.messages.isNotEmpty) {
      // Don't wipe the user's ongoing conversation history
      return;
    }
    _buildSession(event.contextData, emit);
  }

  void _onResetSession(
    ResetChatbotSession event,
    Emitter<ChatbotState> emit,
  ) {
    _buildSession(event.contextData, emit);
  }

  void _buildSession(String contextData, Emitter<ChatbotState> emit) {
    try {
      _repository.initializeSession(contextData);
      
      final welcomeMessage = ChatMessage(
        text: 'Assalam-o-Alaikum! 👋\n\nI am your MedAssist AI assistant. You can ask me about your prescriptions, medications, or any health queries in English or Urdu.\n\nآپ مجھ سے اردو میں بھی بات کر سکتے ہیں۔',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(ChatbotReady([welcomeMessage]));
    } catch (e) {
      emit(ChatbotError(e.toString(), state.messages));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatbotState> emit,
  ) async {
    final userMsg = ChatMessage(
      text: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(state.messages)..add(userMsg);
    
    // Show user msg and typing indicator
    emit(ChatbotReady(updatedMessages, isTyping: true));

    try {
      // Call Gemini API
      final rawResponse = await _repository.sendMessage(event.message);

      final botMsg = ChatMessage(
        text: rawResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final finalMessages = List<ChatMessage>.from(updatedMessages)..add(botMsg);
      emit(ChatbotReady(finalMessages, isTyping: false));
      
    } catch (e) {
      emit(ChatbotError(e.toString(), updatedMessages, isTyping: false));
    }
  }
}
