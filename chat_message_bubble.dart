import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';

/* ----------------------------------------------------------
   MESSAGE BUBBLE & ACTION BUTTONS - iOS Style Interactions
---------------------------------------------------------- */
class MessageBubble extends StatefulWidget {
  final Message message;
  final VoidCallback? onRegenerate;
  final VoidCallback? onUserMessageTap;
  const MessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onUserMessageTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with TickerProviderStateMixin {
  bool _showActions = false;
  late AnimationController _actionsAnimationController;
  late Animation<double> _actionsAnimation;
  bool _showUserActions = false;
  late AnimationController _userActionsAnimationController;
  late Animation<double> _userActionsAnimation;

  @override
  void initState() {
    super.initState();
    _actionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _actionsAnimation = CurvedAnimation(
      parent: _actionsAnimationController,
      curve: Curves.easeOut,
    );
    
    _userActionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _userActionsAnimation = CurvedAnimation(
      parent: _userActionsAnimationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _actionsAnimationController.dispose();
    _userActionsAnimationController.dispose();
    super.dispose();
  }

  void _toggleActions() {
    setState(() {
      _showActions = !_showActions;
      if (_showActions) {
        _actionsAnimationController.forward();
      } else {
        _actionsAnimationController.reverse();
      }
    });
  }

  void _toggleUserActions() {
    setState(() {
      _showUserActions = !_showUserActions;
      if (_showUserActions) {
        _userActionsAnimationController.forward();
      } else {
        _userActionsAnimationController.reverse();
      }
    });
  }

  void _giveFeedback(BuildContext context, bool isPositive) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPositive ? '👍 Thank you for your feedback!' : '👎 Feedback noted. We\'ll improve!',
          style: const TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
        duration: const Duration(seconds: 2),
      ),
    );
    _toggleActions();
  }

  void _copyMessage(BuildContext context) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '📋 Message copied to clipboard!',
          style: TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
        duration: const Duration(seconds: 2),
      ),
    );
    _toggleActions();
  }

  void _shareMessage(BuildContext context) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '🔗 Message ready to share!',
          style: TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
        duration: const Duration(seconds: 2),
      ),
    );
    _toggleActions();
  }

  Widget _buildImageWidget(String url) {
    try {
      Widget image;
      if (url.startsWith('data:image')) {
        final commaIndex = url.indexOf(',');
        final header = url.substring(5, commaIndex);
        final mime = header.split(';').first;
        final base64Data = url.substring(commaIndex + 1);
        final bytes = base64Decode(base64Data);
        if (mime == 'image/svg+xml') {
          image = SvgPicture.memory(bytes, fit: BoxFit.contain);
        } else {
          image = Image.memory(bytes, fit: BoxFit.contain);
        }
      } else {
        if (url.toLowerCase().endsWith('.svg')) {
          image = SvgPicture.network(
            url,
            fit: BoxFit.contain,
            placeholderBuilder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        } else {
          image = Image.network(url, fit: BoxFit.contain);
        }
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300, maxWidth: double.infinity),
          child: image,
        ),
      );
    } catch (_) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBot = widget.message.sender == Sender.bot;
    final isUser = widget.message.sender == Sender.user;
    final canShowActions = isBot && !widget.message.isStreaming && widget.message.text.isNotEmpty && widget.onRegenerate != null;

    Widget bubbleContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: isBot ? Colors.transparent : const Color(0xFFEAE9E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: isBot
          ? MarkdownBody(
              data: widget.message.displayText,
              imageBuilder: (uri, title, alt) => _buildImageWidget(uri.toString()),
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 15, 
                  height: 1.5, 
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w400,
                ),
                code: TextStyle(
                  backgroundColor: const Color(0xFFEAE9E5),
                  color: const Color(0xFF000000),
                  fontFamily: 'SF Mono',
                  fontSize: 14,
                ),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFFEAE9E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                h1: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
                h2: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
                h3: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
                listBullet: const TextStyle(color: Color(0xFFA3A3A3)),
                blockquote: const TextStyle(color: Color(0xFFA3A3A3)),
                strong: const TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
                em: const TextStyle(color: Color(0xFF000000), fontStyle: FontStyle.italic),
              ),
            )
          : Text(
              widget.message.text, 
              style: const TextStyle(
                fontSize: 15, 
                height: 1.5, 
                color: Color(0xFF000000),
                fontWeight: FontWeight.w500,
              ),
            ),
    );

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Thoughts panel for bot messages
          if (isBot && widget.message.thoughts.isNotEmpty)
            ThoughtsPanel(thoughts: widget.message.thoughts),
          if (isBot && widget.message.codes.isNotEmpty)
            CodePanel(codes: widget.message.codes),
          // Tool results panel for bot messages
          if (isBot && widget.message.toolData.isNotEmpty)
            ToolResultsPanel(toolData: widget.message.toolData),
          
          if (isUser)
            GestureDetector(
              onTap: _toggleUserActions,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _showUserActions ? const Color(0xFFEAE9E5).withOpacity(0.3) : Colors.transparent,
                ),
                child: bubbleContent,
              ),
            )
          else if (isBot && canShowActions)
            GestureDetector(
              onTap: _toggleActions,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _showActions ? const Color(0xFFEAE9E5).withOpacity(0.3) : Colors.transparent,
                ),
                child: bubbleContent,
              ),
            )
          else
            bubbleContent,
          
          // User message actions
          if (isUser && _showUserActions)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(_userActionsAnimation),
              child: FadeTransition(
                opacity: _userActionsAnimation,
                child: Container(
                  margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ActionButton(
                        icon: Icons.content_copy_rounded,
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: widget.message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '📋 Message copied to clipboard!',
                                style: TextStyle(
                                  color: Color(0xFF000000),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: Colors.white,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                              elevation: 4,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _toggleUserActions();
                        },
                        tooltip: 'Copy text',
                      ),
                      const SizedBox(width: 8),
                      ActionButton(
                        icon: Icons.edit_rounded,
                        onTap: () {
                          if (widget.onUserMessageTap != null) {
                            widget.onUserMessageTap!();
                          }
                          _toggleUserActions();
                        },
                        tooltip: 'Edit & Resend',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // iOS-style action buttons that slide in for bot messages
          if (canShowActions && _showActions)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.2, 0),
                end: Offset.zero,
              ).animate(_actionsAnimation),
              child: FadeTransition(
                opacity: _actionsAnimation,
                child: Container(
                  margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ActionButton(
                        icon: Icons.thumb_up_rounded,
                        onTap: () => _giveFeedback(context, true),
                        tooltip: 'Good response',
                      ),
                      const SizedBox(width: 8),
                      ActionButton(
                        icon: Icons.thumb_down_rounded,
                        onTap: () => _giveFeedback(context, false),
                        tooltip: 'Bad response',
                      ),
                      const SizedBox(width: 8),
                      ActionButton(
                        icon: Icons.content_copy_rounded,
                        onTap: () => _copyMessage(context),
                        tooltip: 'Copy text',
                      ),
                      const SizedBox(width: 8),
                      ActionButton(
                        icon: Icons.refresh_rounded,
                        onTap: () {
                          widget.onRegenerate?.call();
                          _toggleActions();
                        },
                        tooltip: 'Regenerate',
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  
  const ActionButton({
    super.key,
    required this.icon, 
    required this.onTap,
    this.tooltip,
  });
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon, 
              color: const Color(0xFF000000), 
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}