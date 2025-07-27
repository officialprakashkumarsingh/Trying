import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'external_tools_service.dart';

/* ----------------------------------------------------------
   ENHANCED TOOL LOADING INDICATOR - Better Animation & Design
---------------------------------------------------------- */
class ToolLoadingIndicator extends StatefulWidget {
  final ExternalToolsService externalToolsService;
  
  const ToolLoadingIndicator({
    super.key,
    required this.externalToolsService,
  });

  @override
  State<ToolLoadingIndicator> createState() => _ToolLoadingIndicatorState();
}

class _ToolLoadingIndicatorState extends State<ToolLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Slide in/out animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Pulse animation for the progress indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    // Auto-show when tool execution starts
    widget.externalToolsService.addListener(_onToolExecutionChanged);
    if (widget.externalToolsService.isExecuting) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    widget.externalToolsService.removeListener(_onToolExecutionChanged);
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onToolExecutionChanged() {
    if (mounted) {
      if (widget.externalToolsService.isExecuting) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.externalToolsService.isExecuting) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE9E5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D1D1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Animated loading indicator
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF000000),
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF4F3F0),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                
                // Tool execution text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.externalToolsService.currentlyExecutingTools.length > 1
                            ? 'Running ${widget.externalToolsService.currentlyExecutingTools.length} tools'
                            : 'Using external tool',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      if (widget.externalToolsService.currentlyExecutingTools.length == 1)
                        Text(
                          _getToolDescription(widget.externalToolsService.currentlyExecutingTools.first),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFA3A3A3),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Animated dots indicator
                _AnimatedDots(),
              ],
            ),
            
            // Tool chips
            if (widget.externalToolsService.currentlyExecutingTools.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.externalToolsService.currentlyExecutingTools.map((tool) {
                  return _ToolChip(toolName: tool);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getToolDescription(String toolName) {
    switch (toolName) {
      case 'screenshot':
        return 'Capturing webpage screenshot...';
      case 'generate_image':
        return 'Creating AI-generated image...';
      case 'web_search':
        return 'Searching the web for information...';
      case 'screenshot_vision':
        return 'Analyzing screenshot with AI vision...';
      case 'create_image_collage':
        return 'Creating image collage...';
      case 'mermaid_chart':
        return 'Generating diagram...';
      case 'fetch_ai_models':
        return 'Fetching available AI models...';
      case 'switch_ai_model':
        return 'Switching AI model...';
      case 'fetch_image_models':
        return 'Fetching image generation models...';
      default:
        return 'Processing request...';
    }
  }
}

/* ----------------------------------------------------------
   TOOL CHIP - Individual tool indicator
---------------------------------------------------------- */
class _ToolChip extends StatefulWidget {
  final String toolName;
  
  const _ToolChip({required this.toolName});
  
  @override
  State<_ToolChip> createState() => _ToolChipState();
}

class _ToolChipState extends State<_ToolChip> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getToolIcon(widget.toolName),
              size: 12,
              color: const Color(0xFFFFFFFF),
            ),
            const SizedBox(width: 6),
            Text(
              _getToolDisplayName(widget.toolName),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFFFFFFFF),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getToolIcon(String toolName) {
    switch (toolName) {
      case 'screenshot':
        return Icons.screenshot_rounded;
      case 'generate_image':
        return Icons.image_rounded;
      case 'web_search':
        return Icons.search_rounded;
      case 'screenshot_vision':
        return Icons.visibility_rounded;
      case 'create_image_collage':
        return Icons.collections_rounded;
      case 'mermaid_chart':
        return Icons.account_tree_rounded;
      case 'fetch_ai_models':
      case 'switch_ai_model':
        return Icons.smart_toy_rounded;
      case 'fetch_image_models':
        return Icons.palette_rounded;
      default:
        return Icons.build_rounded;
    }
  }
  
  String _getToolDisplayName(String toolName) {
    switch (toolName) {
      case 'screenshot':
        return 'Screenshot';
      case 'generate_image':
        return 'Image Gen';
      case 'web_search':
        return 'Web Search';
      case 'screenshot_vision':
        return 'Vision AI';
      case 'create_image_collage':
        return 'Collage';
      case 'mermaid_chart':
        return 'Diagram';
      case 'fetch_ai_models':
        return 'AI Models';
      case 'switch_ai_model':
        return 'Switch Model';
      case 'fetch_image_models':
        return 'Image Models';
      default:
        return toolName.replaceAll('_', ' ').toUpperCase();
    }
  }
}

/* ----------------------------------------------------------
   ANIMATED DOTS - Loading indicator dots
---------------------------------------------------------- */
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimation();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startAnimation() async {
    while (mounted) {
      for (int i = 0; i < _controllers.length; i++) {
        if (mounted) {
          _controllers[i].forward();
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      for (var controller in _controllers) {
        if (mounted) {
          controller.reverse();
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(
                left: index > 0 ? 4 : 0,
              ),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF000000).withOpacity(_animations[index].value),
              ),
            );
          },
        );
      }),
    );
  }
}