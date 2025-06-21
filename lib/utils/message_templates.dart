/// Predefined message templates for quick responses in emergency situations
class MessageTemplates {
  // Citizen templates
  static const List<MessageTemplate> citizenTemplates = [
    MessageTemplate(
      id: 'citizen_safe',
      category: 'Status',
      title: 'I am safe',
      content: '✅ I am safe and secure at my current location.',
      icon: '✅',
      priority: MessagePriority.normal,
    ),
    MessageTemplate(
      id: 'citizen_need_help',
      category: 'Emergency',
      title: 'Need immediate help',
      content: '🚨 I need immediate assistance. Please send help to my location.',
      icon: '🚨',
      priority: MessagePriority.urgent,
    ),
    MessageTemplate(
      id: 'citizen_injured',
      category: 'Medical',
      title: 'Someone is injured',
      content: '🩹 There is an injured person here. Medical assistance needed.',
      icon: '🩹',
      priority: MessagePriority.high,
    ),
    MessageTemplate(
      id: 'citizen_trapped',
      category: 'Emergency',
      title: 'Trapped/Cannot move',
      content: '⚠️ I am trapped and cannot move from my current location.',
      icon: '⚠️',
      priority: MessagePriority.urgent,
    ),
    MessageTemplate(
      id: 'citizen_evacuating',
      category: 'Status',
      title: 'Evacuating area',
      content: '🚶 I am evacuating the area and moving to safety.',
      icon: '🚶',
      priority: MessagePriority.normal,
    ),
    MessageTemplate(
      id: 'citizen_shelter',
      category: 'Status',
      title: 'Found shelter',
      content: '🏠 I have found shelter and am waiting for further instructions.',
      icon: '🏠',
      priority: MessagePriority.normal,
    ),
  ];

  // Responder templates
  static const List<MessageTemplate> responderTemplates = [
    MessageTemplate(
      id: 'responder_enroute',
      category: 'Status',
      title: 'En route to location',
      content: '🚗 Emergency responders are en route to your location. ETA: [TIME]',
      icon: '🚗',
      priority: MessagePriority.high,
    ),
    MessageTemplate(
      id: 'responder_arrived',
      category: 'Status',
      title: 'Arrived on scene',
      content: '📍 Emergency responders have arrived on scene and are assessing the situation.',
      icon: '📍',
      priority: MessagePriority.high,
    ),
    MessageTemplate(
      id: 'responder_evacuate',
      category: 'Instructions',
      title: 'Evacuation order',
      content: '🚨 EVACUATION ORDER: Please evacuate the area immediately. Follow designated evacuation routes.',
      icon: '🚨',
      priority: MessagePriority.urgent,
    ),
    MessageTemplate(
      id: 'responder_shelter',
      category: 'Instructions',
      title: 'Shelter in place',
      content: '🏠 SHELTER IN PLACE: Stay indoors, close all windows and doors. Do not leave until further notice.',
      icon: '🏠',
      priority: MessagePriority.urgent,
    ),
    MessageTemplate(
      id: 'responder_all_clear',
      category: 'Status',
      title: 'All clear',
      content: '✅ ALL CLEAR: The immediate danger has passed. Normal activities may resume.',
      icon: '✅',
      priority: MessagePriority.normal,
    ),
    MessageTemplate(
      id: 'responder_medical_enroute',
      category: 'Medical',
      title: 'Medical team en route',
      content: '🚑 Medical team is en route to your location. Please remain calm and follow first aid procedures if trained.',
      icon: '🚑',
      priority: MessagePriority.high,
    ),
    MessageTemplate(
      id: 'responder_need_info',
      category: 'Information',
      title: 'Need more information',
      content: '❓ We need more information about the situation. Please provide details about number of people affected and current conditions.',
      icon: '❓',
      priority: MessagePriority.normal,
    ),
    MessageTemplate(
      id: 'responder_stay_calm',
      category: 'Instructions',
      title: 'Stay calm',
      content: '🤝 Please remain calm. Help is on the way. Follow emergency procedures and stay in a safe location.',
      icon: '🤝',
      priority: MessagePriority.normal,
    ),
  ];

  // Admin templates
  static const List<MessageTemplate> adminTemplates = [
    MessageTemplate(
      id: 'admin_broadcast_alert',
      category: 'Broadcast',
      title: 'Emergency broadcast',
      content: '📢 EMERGENCY BROADCAST: [EMERGENCY_TYPE] reported in [LOCATION]. All residents in the area should [INSTRUCTIONS].',
      icon: '📢',
      priority: MessagePriority.urgent,
    ),
    MessageTemplate(
      id: 'admin_status_update',
      category: 'Update',
      title: 'Status update',
      content: '📊 STATUS UPDATE: Current situation - [STATUS]. Response teams deployed: [TEAMS]. Estimated resolution: [TIME].',
      icon: '📊',
      priority: MessagePriority.high,
    ),
    MessageTemplate(
      id: 'admin_resources_deployed',
      category: 'Resources',
      title: 'Resources deployed',
      content: '🚒 RESOURCES DEPLOYED: [RESOURCE_LIST] have been dispatched to the emergency location.',
      icon: '🚒',
      priority: MessagePriority.high,
    ),
  ];

  /// Get templates for a specific user role
  static List<MessageTemplate> getTemplatesForRole(String role) {
    switch (role.toLowerCase()) {
      case 'citizen':
        return citizenTemplates;
      case 'responder':
        return responderTemplates;
      case 'admin':
        return adminTemplates;
      default:
        return citizenTemplates;
    }
  }

  /// Get templates by category
  static List<MessageTemplate> getTemplatesByCategory(String role, String category) {
    final templates = getTemplatesForRole(role);
    return templates.where((template) => template.category == category).toList();
  }

  /// Get urgent templates
  static List<MessageTemplate> getUrgentTemplates(String role) {
    final templates = getTemplatesForRole(role);
    return templates.where((template) => template.priority == MessagePriority.urgent).toList();
  }

  /// Get all categories for a role
  static List<String> getCategoriesForRole(String role) {
    final templates = getTemplatesForRole(role);
    return templates.map((template) => template.category).toSet().toList();
  }

  /// Find template by ID
  static MessageTemplate? getTemplateById(String id) {
    final allTemplates = [...citizenTemplates, ...responderTemplates, ...adminTemplates];
    try {
      return allTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Process template content with variables
  static String processTemplate(String content, Map<String, String> variables) {
    String processed = content;
    variables.forEach((key, value) {
      processed = processed.replaceAll('[$key]', value);
    });
    return processed;
  }
}

/// Message template model
class MessageTemplate {
  final String id;
  final String category;
  final String title;
  final String content;
  final String icon;
  final MessagePriority priority;

  const MessageTemplate({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.icon,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'content': content,
      'icon': icon,
      'priority': priority.name,
    };
  }

  factory MessageTemplate.fromMap(Map<String, dynamic> map) {
    return MessageTemplate(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      icon: map['icon'] ?? '',
      priority: MessagePriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => MessagePriority.normal,
      ),
    );
  }
}

/// Message priority levels
enum MessagePriority {
  normal,
  high,
  urgent,
}

/// Template categories
class TemplateCategories {
  static const String status = 'Status';
  static const String emergency = 'Emergency';
  static const String medical = 'Medical';
  static const String instructions = 'Instructions';
  static const String information = 'Information';
  static const String broadcast = 'Broadcast';
  static const String update = 'Update';
  static const String resources = 'Resources';
}
