import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../utils/message_templates.dart';

/// Widget for displaying and selecting message templates
class MessageTemplatesWidget extends StatefulWidget {
  final String userRole;
  final Function(MessageTemplate) onTemplateSelected;

  const MessageTemplatesWidget({
    super.key,
    required this.userRole,
    required this.onTemplateSelected,
  });

  @override
  State<MessageTemplatesWidget> createState() => _MessageTemplatesWidgetState();
}

class _MessageTemplatesWidgetState extends State<MessageTemplatesWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _categories = MessageTemplates.getCategoriesForRole(widget.userRole);
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(HugeIcons.strokeRoundedMessage01, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Quick Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(HugeIcons.strokeRoundedCancel01),
                ),
              ],
            ),
          ),

          // Category tabs
          if (_categories.length > 1)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              tabs: _categories.map((category) => Tab(text: category)).toList(),
            ),

          // Templates list
          Expanded(
            child: _categories.length > 1
                ? TabBarView(
                    controller: _tabController,
                    children: _categories
                        .map((category) => _buildTemplatesList(category))
                        .toList(),
                  )
                : _buildTemplatesList(_categories.first),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(String category) {
    final templates = MessageTemplates.getTemplatesByCategory(widget.userRole, category);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(MessageTemplate template) {
    Color priorityColor = _getPriorityColor(template.priority);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          widget.onTemplateSelected(template);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (template.priority != MessagePriority.normal)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              template.priority.name.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    HugeIcons.strokeRoundedArrowRight01,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.urgent:
        return Colors.red;
      case MessagePriority.high:
        return Colors.orange;
      case MessagePriority.normal:
        return Colors.blue;
    }
  }
}

/// Quick template buttons for common actions
class QuickTemplateButtons extends StatelessWidget {
  final String userRole;
  final Function(MessageTemplate) onTemplateSelected;

  const QuickTemplateButtons({
    super.key,
    required this.userRole,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final urgentTemplates = MessageTemplates.getUrgentTemplates(userRole);
    
    if (urgentTemplates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: urgentTemplates.take(3).map((template) {
              return _buildQuickButton(template);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(MessageTemplate template) {
    final priorityColor = _getPriorityColor(template.priority);
    
    return InkWell(
      onTap: () => onTemplateSelected(template),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: priorityColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              template.icon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              template.title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: priorityColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.urgent:
        return Colors.red;
      case MessagePriority.high:
        return Colors.orange;
      case MessagePriority.normal:
        return Colors.blue;
    }
  }
}

/// Show message templates bottom sheet
void showMessageTemplates({
  required BuildContext context,
  required String userRole,
  required Function(MessageTemplate) onTemplateSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MessageTemplatesWidget(
      userRole: userRole,
      onTemplateSelected: onTemplateSelected,
    ),
  );
}
