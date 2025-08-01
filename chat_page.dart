import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'models.dart';
import 'character_service.dart';
import 'external_tools_service.dart';
import 'chat_message_bubble.dart';
import 'chat_input_bar.dart';
import 'chat_panels.dart';
import 'tool_loading_indicator.dart';

/* ----------------------------------------------------------
   CHAT PAGE
---------------------------------------------------------- */
class ChatPage extends StatefulWidget {
  final void Function(Message botMessage) onBookmark;
  final String selectedModel;
  const ChatPage({super.key, required this.onBookmark, required this.selectedModel});

  @override
  State<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <Message>[
    Message.bot('Hi, I\'m AhamAI. Ask me anything!'),
  ];
  bool _awaitingReply = false;
  String? _editingMessageId;

  // Web search and image upload modes
  bool _webSearchMode = false;
  String? _uploadedImagePath;
  String? _uploadedImageBase64;

  // Add memory system for general chat
  final List<String> _conversationMemory = [];
  static const int _maxMemorySize = 10;

  http.Client? _httpClient;
  final CharacterService _characterService = CharacterService();
  final ExternalToolsService _externalToolsService = ExternalToolsService();

  final _prompts = ['Explain quantum computing', 'Write a Python snippet', 'Draft an email to my boss', 'Ideas for weekend trip'];
  
  // MODIFICATION: Robust function to fix server-side encoding errors (mojibake).
  // This is the core fix for rendering emojis and special characters correctly.
  String _fixServerEncoding(String text) {
    try {
      // This function corrects text that was encoded in UTF-8 but mistakenly interpreted as Latin-1.
      // 1. We take the garbled string and encode it back into bytes using Latin-1.
      //    This recovers the original, correct UTF-8 byte sequence.
      final originalBytes = latin1.encode(text);
      // 2. We then decode these bytes using the correct UTF-8 format.
      //    `allowMalformed: true` makes this more robust against potential errors.
      return utf8.decode(originalBytes, allowMalformed: true);
    } catch (e) {
      // If anything goes wrong, return the original text to prevent the app from crashing.
      return text;
    }
  }

  @override
  void initState() {
    super.initState();
    _characterService.addListener(_onCharacterChanged);
    _externalToolsService.addListener(_onExternalToolsServiceChanged);
    _updateGreetingForCharacter();
    _controller.addListener(() {
      setState(() {}); // Refresh UI when text changes
    });
  }

  @override
  void dispose() {
    _characterService.removeListener(_onCharacterChanged);
    _externalToolsService.removeListener(_onExternalToolsServiceChanged);
    _controller.dispose();
    _scroll.dispose();
    _httpClient?.close();
    super.dispose();
  }

  List<Message> getMessages() => _messages;

  void loadChatSession(List<Message> messages) {
    setState(() {
      _awaitingReply = false;
      _httpClient?.close();
      _messages.clear();
      _messages.addAll(messages);
    });
  }

  void _onCharacterChanged() {
    if (mounted) {
      _updateGreetingForCharacter();
    }
  }

  void _onExternalToolsServiceChanged() {
    if (mounted) {
      setState(() {}); // Refresh UI when external tools service state changes
    }
  }

  void _updateGreetingForCharacter() {
    final selectedCharacter = _characterService.selectedCharacter;
    setState(() {
      if (_messages.isNotEmpty && _messages.first.sender == Sender.bot && _messages.length == 1) {
        if (selectedCharacter != null) {
          _messages.first = Message.bot('Hello! I\'m ${selectedCharacter.name}. ${selectedCharacter.description}. How can I help you today?');
        } else {
          _messages.first = Message.bot('Hi, I\'m AhamAI. Ask me anything!');
        }
      }
    });
  }

  void _startEditing(Message message) {
    setState(() {
      _editingMessageId = message.id;
      _controller.text = message.text;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    });
  }
  
  void _cancelEditing() {
    setState(() {
      _editingMessageId = null;
      _controller.clear();
    });
  }

  void _showUserMessageOptions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF4F3F0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.copy_all_rounded, color: Color(0xFF8E8E93)),
              title: const Text('Copy', style: TextStyle(color: Colors.white)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('Copied to clipboard')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Color(0xFF8E8E93)),
              title: const Text('Edit & Resend', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _startEditing(message);
              },
            ),
          ],
        );
      },
    );
  }

  void _updateConversationMemory(String userMessage, String aiResponse) {
    final memoryEntry = 'User: $userMessage\nAI: $aiResponse';
    _conversationMemory.add(memoryEntry);
    
    // Keep only the last 10 memory entries
    if (_conversationMemory.length > _maxMemorySize) {
      _conversationMemory.removeAt(0);
    }
  }

  String _getMemoryContext() {
    if (_conversationMemory.isEmpty) return '';
    return 'Previous conversation context:\n${_conversationMemory.join('\n\n')}\n\nCurrent conversation:';
  }

  Future<void> _generateResponse(String prompt) async {
    if (widget.selectedModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No model selected'), backgroundColor: Color(0xFFEAE9E5)),
      );
      return;
    }

    setState(() => _awaitingReply = true);

    // Regular AI chat - AI is now aware of external tools it can access
    // The AI will mention and use external tools based on user requests

    _httpClient = http.Client();
    final memoryContext = _getMemoryContext();
    final fullPrompt = memoryContext.isNotEmpty ? '$memoryContext\n\nUser: $prompt' : prompt;

    try {
      final request = http.Request('POST', Uri.parse('https://ahamai-api.officialprakashkrsingh.workers.dev/v1/chat/completions'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ahamaibyprakash25',
      });
      // Build message content with optional image
      Map<String, dynamic> messageContent;
      if (_uploadedImageBase64 != null && _uploadedImageBase64!.isNotEmpty) {
        messageContent = {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': fullPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': _uploadedImageBase64!,
              },
            },
          ],
        };
      } else {
        messageContent = {'role': 'user', 'content': fullPrompt};
      }

      // Build system prompt with external tools information
      final availableTools = _externalToolsService.getAvailableTools();
      final toolsInfo = availableTools.map((tool) => 
        '- ${tool.name}: ${tool.description}'
      ).join('\n');
      
      final systemMessage = {
        'role': 'system',
        'content': '''You are AhamAI, an intelligent assistant with access to external tools. You can execute tools to help users with various tasks.

Available External Tools:
$toolsInfo

🔧 TOOL USAGE:
When you need to use a single tool, use this JSON format:
```json
{
  "tool_use": true,
  "tool_name": "tool_name_here",
  "parameters": {
    "param1": "value1",
    "param2": "value2"
  }
}
```

For parallel tool execution (when multiple tools are needed), use this array format:
```json
[
  {
    "tool_use": true,
    "tool_name": "first_tool",
    "parameters": {"param1": "value1"}
  },
  {
    "tool_use": true,
    "tool_name": "second_tool", 
    "parameters": {"param2": "value2"}
  }
]
```

🎯 WHEN TO USE TOOLS:
- **screenshot**: Capture single/multiple webpages visually (supports urls array for batch)
- **generate_image**: Create unique images with enhanced prompts (models: flux, turbo) - now generates different images for different prompts
- **fetch_image_models**: Show available image generation models
- **web_search**: Get real-time information from DuckDuckGo and Wikipedia (enhanced with deep search)
- **screenshot_vision**: Analyze single images OR multiple images as collage (ALWAYS include image_url or image_urls parameter)
- **create_image_collage**: Combine multiple images into one collage for easier analysis
- **mermaid_chart**: Generate professional diagrams with auto-enhancement (flowchart, sequence, class, gantt, etc.)

🔍 ENHANCED FEATURES:
- Image generation now uses unique seeds to prevent duplicate images
- Screenshot analysis supports multiple images via automatic collage creation
- Mermaid diagrams auto-enhanced with professional styling and structure
- All tools optimized for parallel execution when appropriate
- **fetch_ai_models**: List available AI chat models
- **switch_ai_model**: Change to different AI model

🔗 PARALLEL EXECUTION:
You can now use multiple tools simultaneously! For example:
- Take screenshot + analyze it with vision
- Generate image + search for related information
- Fetch models + take screenshot

Always use proper JSON format and explain what you're doing to help the user understand the process.

Be conversational and helpful!'''
      };

      request.body = json.encode({
        'model': widget.selectedModel,
        'messages': [systemMessage, messageContent],
        'stream': true,
      });

      final response = await _httpClient!.send(request);

      if (response.statusCode == 200) {
        final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());
        var botMessage = Message.bot('', isStreaming: true);
        final botMessageIndex = _messages.length;
        
        setState(() {
          _messages.add(botMessage);
        });

        String accumulatedText = '';
        await for (final line in stream) {
          if (!mounted || _httpClient == null) break;
          
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            if (jsonStr.trim() == '[DONE]') break;
            
            try {
              final data = json.decode(jsonStr);
              final content = data['choices']?[0]?['delta']?['content'];
              if (content != null) {
                accumulatedText += _fixServerEncoding(content);
                setState(() {
                  _messages[botMessageIndex] = botMessage.copyWith(
                    text: accumulatedText,
                    isStreaming: true,
                  );
                });
                _scrollToBottom();
              }
            } catch (e) {
              // Continue on JSON parsing errors
            }
          }
        }

        // Process completed message for tool calls
        final processedMessage = await _processToolCalls(accumulatedText);
        
        setState(() {
          _messages[botMessageIndex] = Message.bot(
            processedMessage['text'],
            isStreaming: false,
            toolData: processedMessage['toolData'],
          );
        });

        // Update memory with the completed conversation
        _updateConversationMemory(prompt, processedMessage['text']);

        // Ensure UI scrolls to bottom after processing
        _scrollToBottom();

      } else {
        // Handle different status codes more gracefully
        String errorMessage;
        if (response.statusCode == 400) {
          errorMessage = 'Bad request. Please check your message format and try again.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Authentication failed. Please check API credentials.';
        } else if (response.statusCode == 429) {
          errorMessage = 'Rate limit exceeded. Please wait a moment and try again.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Server error. Please try again in a moment.';
        } else {
          errorMessage = 'Sorry, there was an error processing your request. Status: ${response.statusCode}';
        }
        
        setState(() {
          _messages.add(Message.bot(errorMessage));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(Message.bot('Sorry, I\'m having trouble connecting right now. Please try again. Error: ${e.toString().length > 100 ? e.toString().substring(0, 100) + '...' : e.toString()}'));
        });
      }
    } finally {
      // Clean up resources
      _httpClient?.close();
      _httpClient = null;
      if (mounted) {
        setState(() {
          _awaitingReply = false;
        });
        // Clear uploaded image only after successful processing
        if (_uploadedImageBase64 != null) {
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) _clearUploadedImage();
          });
        }
      }
    }
  }

  /// Process tool calls in AI response and execute them
  Future<Map<String, dynamic>> _processToolCalls(String responseText) async {
    Map<String, dynamic> toolData = {};
    String processedText = responseText;
    
    // Enhanced patterns for more robust JSON tool detection
    final singleJsonPattern = RegExp(r'```json\s*(\{[^`]*?["\x27]tool_use["\x27]\s*:\s*true[^`]*?\})\s*```', dotAll: true, multiLine: true);
    
    // Look for parallel tool calls (array of tool calls)
    final parallelJsonPattern = RegExp(r'```json\s*(\[[^`]*?["\x27]tool_use["\x27]\s*:\s*true[^`]*?\])\s*```', dotAll: true, multiLine: true);
    
    // Also look for tool calls without explicit tool_use flag
    final implicitToolPattern = RegExp(r'```json\s*(\{[^`]*?["\x27]tool_name["\x27]\s*:\s*["\x27][^"\x27]+["\x27][^`]*?\})\s*```', dotAll: true, multiLine: true);
    final implicitParallelPattern = RegExp(r'```json\s*(\[[^`]*?["\x27]tool_name["\x27]\s*:\s*["\x27][^"\x27]+["\x27][^`]*?\])\s*```', dotAll: true, multiLine: true);
    
    final singleMatches = singleJsonPattern.allMatches(responseText);
    final parallelMatches = parallelJsonPattern.allMatches(responseText);
    final implicitSingleMatches = implicitToolPattern.allMatches(responseText);
    final implicitParallelMatches = implicitParallelPattern.allMatches(responseText);
    
    // Handle parallel tool calls first
    for (final match in [...parallelMatches, ...implicitParallelMatches]) {
      try {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final toolCalls = json.decode(jsonStr) as List;
          final validToolCalls = toolCalls.where((call) => 
            call is Map<String, dynamic> && 
            (call['tool_use'] == true || call['tool_name'] != null) &&
            call['tool_name'] != null
          ).cast<Map<String, dynamic>>().toList();
          
          // Add tool_use flag for implicit calls
          for (final call in validToolCalls) {
            call['tool_use'] = true;
          }
          
          if (validToolCalls.isNotEmpty) {
            // Execute tools in parallel
            final results = await _externalToolsService.executeToolsParallel(validToolCalls);
            toolData.addAll(results);
            
            // Build combined result text
            String combinedResultText = '**🔧 Parallel Tools Executed**\n\n';
            for (final call in validToolCalls) {
              final toolName = call['tool_name'] as String;
              final result = results[toolName];
              combinedResultText += _formatToolResult(toolName, result ?? {}) + '\n\n';
            }
            
            processedText = processedText.replaceAll(match.group(0)!, combinedResultText.trim());
          }
        }
      } catch (e) {
        debugPrint('Parallel tool call JSON parsing error: $e');
      }
    }
    
    // Handle single tool calls
    for (final match in [...singleMatches, ...implicitSingleMatches]) {
      try {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final toolCall = json.decode(jsonStr);
          
          if ((toolCall['tool_use'] == true || toolCall['tool_name'] != null) && toolCall['tool_name'] != null) {
            final toolName = toolCall['tool_name'] as String;
            final parameters = toolCall['parameters'] as Map<String, dynamic>? ?? {};
            
            // Ensure tool_use flag is set
            toolCall['tool_use'] = true;
            
            // Execute the tool
            final result = await _externalToolsService.executeTool(toolName, parameters);
            toolData[toolName] = result;
            
            // Replace the JSON block with the tool execution result
            String resultText = _formatToolResult(toolName, result);
            processedText = processedText.replaceAll(match.group(0)!, resultText);
          }
        }
      } catch (e) {
        // If JSON parsing fails, leave the original text
        debugPrint('Tool call JSON parsing error: $e');
      }
    }
    
    return {
      'text': processedText,
      'toolData': toolData,
    };
  }

  /// Format tool execution result for display
  String _formatToolResult(String toolName, Map<String, dynamic> result) {
    if (result['success'] == true) {
      switch (toolName) {
        case 'screenshot':
          // Handle multiple screenshots if they exist
          if (result.containsKey('screenshots') && result['screenshots'] is List) {
            final screenshots = result['screenshots'] as List;
            String screenshotImages = '';
            for (int i = 0; i < screenshots.length; i++) {
              final shot = screenshots[i] as Map;
              screenshotImages += '![Screenshot ${i + 1}](${shot['preview_url']})\n\n';
            }
            return '''**🖼️ Multiple Screenshots Captured Successfully**

$screenshotImages**Service:** ${result['service']}

✅ All screenshots captured and available for viewing!''';
          } else {
            return '''**🖼️ Screenshot Tool Executed Successfully**

**URL:** ${result['url']}
**Dimensions:** ${result['width']}x${result['height']}
**Service:** ${result['service']}

![Screenshot](${result['preview_url']})

✅ Screenshot captured and available for viewing!''';
          }

        case 'fetch_ai_models':
          final models = result['models'] as List;
          final modelsList = models.take(10).join(', ');
          return '''**🤖 AI Models Fetched Successfully**

**Available Models:** ${result['total_count']} models found
**Sample Models:** $modelsList${models.length > 10 ? '...' : ''}
**API Status:** ${result['api_status']}

✅ Models list retrieved successfully!''';

        case 'switch_ai_model':
          return '''**🔄 AI Model Switch Executed**

**New Model:** ${result['new_model']}
**Reason:** ${result['reason']}
**Validation:** ${result['validation']}
**Status:** ${result['action_completed']}

✅ Model switch completed successfully!''';

        case 'generate_image':
          return '''**🎨 Image Generated Successfully**

**Prompt:** ${result['original_prompt'] ?? result['prompt'] ?? 'N/A'}
**Model:** ${result['model']}
**Dimensions:** ${result['width']}x${result['height']}
**Image Size:** ${(result['image_size'] as int? ?? 0) ~/ 1024}KB
**Unique Seed:** ${result['seed']}

![Generated Image](${result['image_url']})

✅ Image generated successfully using ${result['model']} model with unique identifier!''';

        case 'fetch_image_models':
          final models = result['model_names'] as List;
          final modelsList = models.take(5).join(', ');
          return '''**🎨 Image Models Fetched Successfully**

**Available Models:** ${result['total_count']} models found
**Sample Models:** $modelsList${models.length > 5 ? '...' : ''}
**API Status:** ${result['api_status']}

✅ Image models list retrieved successfully!''';

        case 'web_search':
          final results = result['results'] as List;
          String resultsList = '';
          for (int i = 0; i < results.length && i < 5; i++) {
            final res = results[i] as Map<String, dynamic>;
            final source = res['source']?.toString() ?? '';
            final type = res['type']?.toString() ?? '';
            String icon = '🔍';
            if (source.contains('Wikipedia')) icon = '📖';
            else if (type == 'definition') icon = '📚';
            else if (type == 'primary') icon = '⭐';
            
            resultsList += '$icon **${res['title']}** ($source)\n';
            resultsList += '   ${res['snippet']}\n';
            if (res['url']?.toString().isNotEmpty == true) {
              resultsList += '   🔗 [Read more](${res['url']})\n';
            }
            resultsList += '\n';
          }
          
          final searchDetails = result['search_details'] as Map<String, dynamic>? ?? {};
          return '''**🔍 Enhanced Web Search Completed Successfully**

**Query:** ${result['query']}
**Source:** ${result['source']}
**Deep Search:** ${result['deep_search'] == true ? 'Enabled' : 'Disabled'}

**Search Results:**
$resultsList

**Result Distribution:**
- Wikipedia: ${searchDetails['wikipedia_results'] ?? 0} results
- DuckDuckGo: ${searchDetails['duckduckgo_results'] ?? 0} results
- Total Found: ${result['total_found']}

✅ Enhanced web search completed successfully!''';

        case 'screenshot_vision':
          return '''**👁️ Screenshot Vision Analysis Completed**

**Question:** ${result['question']}
**Model:** ${result['model']}
**Analysis:** ${result['answer']}

          ✅ Screenshot analyzed successfully using vision AI!''';

        case 'mermaid_chart':
          return '''**📊 Mermaid Chart Generated**

**Format:** ${result['format']}

![Diagram](${result['image_url']})

✅ Diagram generated successfully!''';


        default:
          return '''**🛠️ Tool Executed: $toolName**

✅ ${result['description'] ?? 'Tool executed successfully'}''';
      }
    } else {
      return '''**❌ Tool Execution Failed: $toolName**

Error: ${result['error']}''';
    }
  }

  void _regenerateResponse(int botMessageIndex) {
    int userMessageIndex = botMessageIndex - 1;
    if (userMessageIndex >= 0 && _messages[userMessageIndex].sender == Sender.user) {
      String lastUserPrompt = _messages[userMessageIndex].text;
      setState(() => _messages.removeAt(botMessageIndex));
      _generateResponse(lastUserPrompt);
    }
  }
  
  void _stopGeneration() {
    _httpClient?.close();
    _httpClient = null;
    if(mounted) {
      setState(() {
        if (_awaitingReply && _messages.isNotEmpty && _messages.last.isStreaming) {
           final lastIndex = _messages.length - 1;
           _messages[lastIndex] = _messages.last.copyWith(isStreaming: false);
        }
        _awaitingReply = false;
      });
    }
  }

  void startNewChat() {
    setState(() {
      _awaitingReply = false;
      _editingMessageId = null;
      _conversationMemory.clear(); // Clear memory for fresh start
      _httpClient?.close();
      _httpClient = null;
      _messages.clear();
      final selectedCharacter = _characterService.selectedCharacter;
      if (selectedCharacter != null) {
        _messages.add(Message.bot('Fresh chat started with ${selectedCharacter.name}. How can I help?'));
      } else {
        _messages.add(Message.bot('Hi, I\'m AhamAI. Ask me anything!'));
      }
    });
  }



  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
      }
    });
  }

  Future<void> _send({String? text}) async {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty || _awaitingReply) return;

    final isEditing = _editingMessageId != null;
    if (isEditing) {
      final messageIndex = _messages.indexWhere((m) => m.id == _editingMessageId);
      if (messageIndex != -1) {
        setState(() {
          _messages.removeRange(messageIndex, _messages.length);
        });
      }
    }
    
    _controller.clear();
    setState(() {
      _messages.add(Message.user(messageText));
      _editingMessageId = null;
    });

    _scrollToBottom();
    HapticFeedback.lightImpact();
    await _generateResponse(messageText);
  }

  void _toggleWebSearch() {
    setState(() {
      _webSearchMode = !_webSearchMode;
    });
  }

  Future<void> _handleImageUpload() async {
    try {
      await _showImageSourceDialog();
    } catch (e) {
      // Handle error
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F3F0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFC4C4C4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Text(
              'Select Image Source',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000000),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Camera option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF000000)),
              ),
              title: Text(
                'Take Photo',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF000000),
                ),
              ),
              subtitle: Text(
                'Capture with camera',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA3A3A3),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            
            // Gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF000000)),
              ),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF000000),
                ),
              ),
              subtitle: Text(
                'Select from photos',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA3A3A3),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        setState(() {
          _uploadedImagePath = pickedFile.path;
          _uploadedImageBase64 = 'data:image/jpeg;base64,$base64Image';
        });
        
        // Add image message to chat
        final imageMessage = Message.user("📷 Image uploaded: ${pickedFile.name}");
        setState(() {
          _messages.add(imageMessage);
        });
        
        _scrollToBottom();
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearUploadedImage() {
    setState(() {
      _uploadedImagePath = null;
      _uploadedImageBase64 = null;
    });
  }



  @override
  Widget build(BuildContext context) {
    final emptyChat = _messages.length <= 1;
    return Container(
      color: const Color(0xFFF4F3F0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message,
                  onRegenerate: () => _regenerateResponse(index),
                  onUserMessageTap: () => _showUserMessageOptions(context, message),
                );
              },
            ),
          ),
          if (emptyChat && _editingMessageId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _prompts.map((p) => Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _controller.text = p;
                            _send();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAE9E5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF000000),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          // Enhanced external tools status with better animation
          ToolLoadingIndicator(externalToolsService: _externalToolsService),
                        SafeArea(
            top: false,
            left: false,
            right: false,
            child: ChatInputBar(
              controller: _controller,
              onSend: () => _send(),
              onStop: _stopGeneration,
              awaitingReply: _awaitingReply,
              isEditing: _editingMessageId != null,
              onCancelEdit: _cancelEditing,
              externalToolsService: _externalToolsService,
              webSearchMode: _webSearchMode,
              onToggleWebSearch: _toggleWebSearch,
              onImageUpload: _handleImageUpload,
              uploadedImagePath: _uploadedImagePath,
              onClearImage: _clearUploadedImage,
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------
   CHAT PAGE IMPLEMENTATION
---------------------------------------------------------- */

/* ----------------------------------------------------------
   END OF CHAT PAGE IMPLEMENTATION
---------------------------------------------------------- */
// All components have been moved to separate files:
// - chat_message_bubble.dart
// - chat_input_bar.dart 
// - chat_panels.dart
// - tool_loading_indicator.dart
}