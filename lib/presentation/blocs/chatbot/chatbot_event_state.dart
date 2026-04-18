import 'package:equatable/equatable.dart';

// --- Messaging Models ---
class ChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, isUser, timestamp];
}

abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();

  @override
  List<Object?> get props => [];
}

class InitializeChatbotSession extends ChatbotEvent {
  final String contextData;
  const InitializeChatbotSession(this.contextData);

  @override
  List<Object?> get props => [contextData];
}

class ResetChatbotSession extends ChatbotEvent {
  final String contextData;
  const ResetChatbotSession(this.contextData);

  @override
  List<Object?> get props => [contextData];
}

class SendMessageEvent extends ChatbotEvent {
  final String message;
  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class ChatbotState extends Equatable {
  final List<ChatMessage> messages;
  final bool isTyping;

  const ChatbotState({this.messages = const [], this.isTyping = false});

  @override
  List<Object?> get props => [messages, isTyping];
}

class ChatbotInitial extends ChatbotState {
  const ChatbotInitial() : super(messages: const [], isTyping: false);
}

class ChatbotReady extends ChatbotState {
  const ChatbotReady(List<ChatMessage> messages, {bool isTyping = false}) 
      : super(messages: messages, isTyping: isTyping);
}

class ChatbotError extends ChatbotState {
  final String error;
  const ChatbotError(this.error, List<ChatMessage> messages, {bool isTyping = false}) 
      : super(messages: messages, isTyping: isTyping);

  @override
  List<Object?> get props => [error, messages, isTyping];
}
