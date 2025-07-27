import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';

/* ----------------------------------------------------------
   CODE PANEL - Collapsible panel for code blocks
---------------------------------------------------------- */
class CodePanel extends StatefulWidget {
  final List<CodeContent> codes;
  
  const CodePanel({super.key, required this.codes});
  
  @override
  State<CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends State<CodePanel> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '📋 Code copied to clipboard!',
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
  }
  
  String _getCodePreview() {
    if (widget.codes.isEmpty) return '';
    final firstCode = widget.codes.first;
    final preview = firstCode.code.length > 50 
        ? '${firstCode.code.substring(0, 50)}...'
        : firstCode.code;
    return preview;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle button
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.code_rounded,
                    size: 16,
                    color: const Color(0xFF000000),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isExpanded 
                          ? '${widget.codes.length} Code Block${widget.codes.length > 1 ? 's' : ''}'
                          : _getCodePreview(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFA3A3A3),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: _isExpanded ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.codes.map((codeContent) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE9E5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with language and copy button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF000000),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                codeContent.extension.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFFFFF),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _copyCode(codeContent.code),
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: Color(0xFF000000),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Code content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              codeContent.code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.4,
                                color: Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------
   THOUGHTS PANEL - Collapsible panel for AI thinking content
---------------------------------------------------------- */
class ThoughtsPanel extends StatefulWidget {
  final List<ThoughtContent> thoughts;
  
  const ThoughtsPanel({super.key, required this.thoughts});
  
  @override
  State<ThoughtsPanel> createState() => _ThoughtsPanelState();
}

class _ThoughtsPanelState extends State<ThoughtsPanel> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  String _getThoughtsPreview() {
    if (widget.thoughts.isEmpty) return '';
    final firstThought = widget.thoughts.first;
    final preview = firstThought.text.length > 50 
        ? '${firstThought.text.substring(0, 50)}...'
        : firstThought.text;
    return preview;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE9E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle button
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 16,
                    color: const Color(0xFF000000),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isExpanded 
                          ? 'Thoughts (${widget.thoughts.length})'
                          : _getThoughtsPreview(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA3A3A3),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: _isExpanded ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.thoughts.map((thought) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F3F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          thought.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFFFFF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        thought.text,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF000000),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------
   TOOL RESULTS PANEL - Displays external tool execution results
---------------------------------------------------------- */
class ToolResultsPanel extends StatefulWidget {
  final Map<String, dynamic> toolData;
  
  const ToolResultsPanel({super.key, required this.toolData});
  
  @override
  State<ToolResultsPanel> createState() => _ToolResultsPanelState();
}

class _ToolResultsPanelState extends State<ToolResultsPanel> with SingleTickerProviderStateMixin {
  bool _isExpanded = true; // Start expanded for better visibility
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Start expanded
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF000000).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle button
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.build_circle_rounded,
                    size: 16,
                    color: const Color(0xFF000000),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tool Results (${widget.toolData.length})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.toolData.entries.map((entry) {
                  final toolName = entry.key;
                  final result = entry.value as Map<String, dynamic>;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE9E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with tool name and status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: result['success'] == true ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  toolName.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFFFFF),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                result['success'] == true ? Icons.check_circle : Icons.error,
                                size: 16,
                                color: result['success'] == true ? Colors.green : Colors.red,
                              ),
                              const Spacer(),
                              if (result['execution_time'] != null)
                                Text(
                                  'Executed',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFFA3A3A3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Tool result content
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              // Result details
                              if ((result['url'] != null) ||
                                  (result['models'] != null) ||
                                  (result['new_model'] != null) ||
                                  (result['api_status'] != null) ||
                                  (result['error'] != null))
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (result['url'] != null)
                                        _buildResultRow('URL', result['url']),
                                      if (result['models'] != null)
                                        _buildResultRow('Models Count', '${(result['models'] as List).length}'),
                                      if (result['new_model'] != null)
                                        _buildResultRow('New Model', result['new_model']),
                                      if (result['api_status'] != null)
                                        _buildResultRow('API Status', result['api_status']),
                                      if (result['error'] != null)
                                        _buildResultRow('Error', result['error'], isError: true),
                                    ],
                                  ),
                                ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
                color: Colors.grey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
                color: isError ? Colors.red[300] : const Color(0xFFFFFFFF),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}