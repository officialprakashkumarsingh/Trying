import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'external_tools_service.dart';

/* ----------------------------------------------------------
   INPUT BAR – Clean Design with Icons Below
---------------------------------------------------------- */
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onStop,
    required this.awaitingReply,
    required this.isEditing,
    required this.onCancelEdit,
    required this.externalToolsService,
    required this.webSearchMode,
    required this.onToggleWebSearch,
    required this.onImageUpload,
    this.uploadedImagePath,
    required this.onClearImage,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool awaitingReply;
  final bool isEditing;
  final VoidCallback onCancelEdit;
  final ExternalToolsService externalToolsService;
  final bool webSearchMode;
  final VoidCallback onToggleWebSearch;
  final VoidCallback onImageUpload;
  final String? uploadedImagePath;
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F0), // Main theme background
      ),
      child: Column(
        children: [
          // Edit mode indicator
          if (isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12, top: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF000000).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Color(0xFF000000), size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Editing message...", 
                      style: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onCancelEdit();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          
          // Main input container
          Container(
            margin: EdgeInsets.fromLTRB(20, isEditing ? 0 : 16, 20, 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white, // White input background
              borderRadius: BorderRadius.circular(24), // Fully rounded border on both sides
              border: Border.all(
                color: const Color(0xFFEAE9E5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text input field with reduced height
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !awaitingReply,
                    maxLines: 3, // Reduced from 6
                    minLines: 1, // Reduced from 3
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: const Color(0xFF000000),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: awaitingReply 
                          ? 'AhamAI is responding...' 
                          : externalToolsService.isExecuting
                              ? 'External tool is running...'
                              : webSearchMode
                                  ? 'Web search mode - Ask me anything...'
                                  : uploadedImagePath != null
                                      ? 'Image uploaded - Describe or ask about it...'
                                      : 'Message AhamAI (images, web search, screenshots, vision)...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA3A3A3),
                        fontSize: 16,
                        height: 1.4,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, // Increased padding for better rounded appearance
                        vertical: 12 // Reduced from 18
                      ),
                    ),
                  ),
                ),
                
                // Send/Stop button
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 6), // Adjusted padding
                  child: GestureDetector(
                    onTap: awaitingReply ? onStop : onSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10), // Smaller padding
                      decoration: BoxDecoration(
                        color: awaitingReply 
                            ? Colors.red.withOpacity(0.1)
                            : const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(12), // Smaller radius
                      ),
                      child: Icon(
                        awaitingReply ? Icons.stop_circle : Icons.arrow_upward_rounded,
                        color: awaitingReply ? Colors.red : Colors.white,
                        size: 18, // Smaller icon
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Icons below input bar
          if (!awaitingReply)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action icons row
                  Row(
                    children: [
                      // Web Search Icon - clean design
                      AnimatedModeIcon(
                        isActive: webSearchMode,
                        icon: FontAwesomeIcons.search,
                        label: 'Search',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onToggleWebSearch();
                        },
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Image Upload Icon - clean design
                      AnimatedModeIcon(
                        isActive: uploadedImagePath != null,
                        icon: uploadedImagePath != null 
                            ? FontAwesomeIcons.times
                            : FontAwesomeIcons.camera,
                        label: 'Image',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (uploadedImagePath != null) {
                            onClearImage();
                          } else {
                            onImageUpload();
                          }
                        },
                      ),
                    
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------
   ANIMATED MODE ICON - Reusable component with animated border
---------------------------------------------------------- */
class AnimatedModeIcon extends StatefulWidget {
  final bool isActive;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AnimatedModeIcon({
    super.key,
    required this.isActive,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<AnimatedModeIcon> createState() => _AnimatedModeIconState();
}

class _AnimatedModeIconState extends State<AnimatedModeIcon> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clean icon with subtle active state
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isActive 
                          ? const Color(0xFF6366F1).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FaIcon(
                        widget.icon,
                        color: widget.isActive 
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF6B7280),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isActive 
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}