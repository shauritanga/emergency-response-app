import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/message.dart';

/// Utility for caching chat data for offline access
class OfflineCache {
  static const String _conversationsKey = 'cached_conversations';
  static const String _messagesKeyPrefix = 'cached_messages_';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingMessagesKey = 'pending_messages';

  /// Cache conversations for offline access
  static Future<void> cacheConversations(List<Conversation> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsJson = conversations.map((c) => c.toMap()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('Cached ${conversations.length} conversations');
    } catch (e) {
      debugPrint('Failed to cache conversations: $e');
    }
  }

  /// Get cached conversations
  static Future<List<Conversation>> getCachedConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsString = prefs.getString(_conversationsKey);
      
      if (conversationsString != null) {
        final List<dynamic> conversationsJson = jsonDecode(conversationsString);
        return conversationsJson
            .map((json) => Conversation.fromMap(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached conversations: $e');
    }
    return [];
  }

  /// Cache messages for a specific conversation
  static Future<void> cacheMessages(String conversationId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((m) => m.toMap()).toList();
      await prefs.setString('$_messagesKeyPrefix$conversationId', jsonEncode(messagesJson));
      debugPrint('Cached ${messages.length} messages for conversation $conversationId');
    } catch (e) {
      debugPrint('Failed to cache messages: $e');
    }
  }

  /// Get cached messages for a conversation
  static Future<List<ChatMessage>> getCachedMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesString = prefs.getString('$_messagesKeyPrefix$conversationId');
      
      if (messagesString != null) {
        final List<dynamic> messagesJson = jsonDecode(messagesString);
        return messagesJson
            .map((json) => ChatMessage.fromMap(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached messages: $e');
    }
    return [];
  }

  /// Store a message for later sending when online
  static Future<void> storePendingMessage(ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingMessages = await getPendingMessages();
      pendingMessages.add(message);
      
      final messagesJson = pendingMessages.map((m) => m.toMap()).toList();
      await prefs.setString(_pendingMessagesKey, jsonEncode(messagesJson));
      debugPrint('Stored pending message: ${message.id}');
    } catch (e) {
      debugPrint('Failed to store pending message: $e');
    }
  }

  /// Get all pending messages
  static Future<List<ChatMessage>> getPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingString = prefs.getString(_pendingMessagesKey);
      
      if (pendingString != null) {
        final List<dynamic> messagesJson = jsonDecode(pendingString);
        return messagesJson
            .map((json) => ChatMessage.fromMap(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to get pending messages: $e');
    }
    return [];
  }

  /// Remove a pending message (after successful send)
  static Future<void> removePendingMessage(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingMessages = await getPendingMessages();
      pendingMessages.removeWhere((message) => message.id == messageId);
      
      final messagesJson = pendingMessages.map((m) => m.toMap()).toList();
      await prefs.setString(_pendingMessagesKey, jsonEncode(messagesJson));
      debugPrint('Removed pending message: $messageId');
    } catch (e) {
      debugPrint('Failed to remove pending message: $e');
    }
  }

  /// Clear all pending messages
  static Future<void> clearPendingMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingMessagesKey);
      debugPrint('Cleared all pending messages');
    } catch (e) {
      debugPrint('Failed to clear pending messages: $e');
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Failed to get last sync time: $e');
    }
    return null;
  }

  /// Check if data is stale (older than specified duration)
  static Future<bool> isDataStale({Duration maxAge = const Duration(hours: 1)}) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > maxAge;
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_messagesKeyPrefix) || 
            key == _conversationsKey || 
            key == _lastSyncKey ||
            key == _pendingMessagesKey) {
          await prefs.remove(key);
        }
      }
      debugPrint('Cleared all cache data');
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Get cache size information
  static Future<CacheInfo> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int conversationCount = 0;
      int messageCount = 0;
      int pendingCount = 0;
      
      for (final key in keys) {
        if (key == _conversationsKey) {
          final conversations = await getCachedConversations();
          conversationCount = conversations.length;
        } else if (key.startsWith(_messagesKeyPrefix)) {
          final conversationId = key.substring(_messagesKeyPrefix.length);
          final messages = await getCachedMessages(conversationId);
          messageCount += messages.length;
        } else if (key == _pendingMessagesKey) {
          final pending = await getPendingMessages();
          pendingCount = pending.length;
        }
      }
      
      return CacheInfo(
        conversationCount: conversationCount,
        messageCount: messageCount,
        pendingMessageCount: pendingCount,
        lastSync: await getLastSyncTime(),
      );
    } catch (e) {
      debugPrint('Failed to get cache info: $e');
      return CacheInfo();
    }
  }

  /// Merge cached messages with new messages
  static List<ChatMessage> mergeMessages(
    List<ChatMessage> cachedMessages,
    List<ChatMessage> newMessages,
  ) {
    final Map<String, ChatMessage> messageMap = {};
    
    // Add cached messages first
    for (final message in cachedMessages) {
      messageMap[message.id] = message;
    }
    
    // Add/update with new messages
    for (final message in newMessages) {
      messageMap[message.id] = message;
    }
    
    // Return sorted by timestamp
    final mergedMessages = messageMap.values.toList();
    mergedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return mergedMessages;
  }

  /// Check if we have cached data for a conversation
  static Future<bool> hasConversationCache(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_messagesKeyPrefix$conversationId');
    } catch (e) {
      debugPrint('Failed to check conversation cache: $e');
      return false;
    }
  }
}

/// Information about cached data
class CacheInfo {
  final int conversationCount;
  final int messageCount;
  final int pendingMessageCount;
  final DateTime? lastSync;

  CacheInfo({
    this.conversationCount = 0,
    this.messageCount = 0,
    this.pendingMessageCount = 0,
    this.lastSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'conversationCount': conversationCount,
      'messageCount': messageCount,
      'pendingMessageCount': pendingMessageCount,
      'lastSync': lastSync?.toIso8601String(),
    };
  }
}
