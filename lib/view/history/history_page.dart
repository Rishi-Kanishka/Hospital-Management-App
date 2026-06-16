import 'package:flutter/material.dart';
import 'package:readit/constants/styles.dart';
import 'package:readit/services/firebase_service.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _extractedTexts = [];
  bool _isLoading = true;
  final Set<String> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _loadExtractedTexts();
  }

  Future<void> _loadExtractedTexts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final texts = await _firebaseService.getExtractedTexts();
      setState(() {
        _extractedTexts = texts;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading extracted texts: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  Future<void> _deleteText(String id) async {
    try {
      await _firebaseService.deleteExtractedText(id);
      _loadExtractedTexts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text deleted successfully')),
        );
      }
    } catch (e) {
      _logger.e('Error deleting text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting text: $e')),
        );
      }
    }
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, String formattedDate) {
    final bool isExpanded = _expandedItems.contains(item['id']);
    const primaryBlue = Color(0xFF1F3C88);
    const lightBlue = Color(0xFFD6E4FF);
    const deleteRed = Color(0xFFFF4B4B);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightBlue, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(item['id']);
                } else {
                  _expandedItems.add(item['id']);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: primaryBlue.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['source'] ?? 'Scanned Document',
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: deleteRed,
                          size: 20,
                        ),
                        onPressed: () => _deleteText(item['id']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    firstChild: Text(
                      item['text'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryBlue.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['text'] ?? '',
                          style: TextStyle(
                            color: primaryBlue.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: lightBlue.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_up,
                                    size: 18,
                                    color: primaryBlue.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Show less',
                                    style: TextStyle(
                                      color: primaryBlue.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: primaryBlue.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isExpanded)
                        Text(
                          'Tap to expand',
                          style: TextStyle(
                            color: primaryBlue.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1F3C88);
    const lightBlue = Color(0xFFD6E4FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _loadExtractedTexts,
          backgroundColor: primaryBlue,
          child: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              lightBlue.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primaryBlue),
                )
              : _extractedTexts.isEmpty
                  ? Center(
                      child: Text(
                        'No scanned documents yet',
                        style: TextStyle(
                          color: primaryBlue.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _extractedTexts.length,
                      itemBuilder: (context, index) {
                        final item = _extractedTexts[index];
                        final timestamp = item['timestamp'] as Timestamp?;
                        final formattedDate = timestamp != null
                            ? DateFormat('MMM d, y • h:mm a')
                                .format(timestamp.toDate())
                            : 'No date';

                        return _buildHistoryCard(item, formattedDate);
                      },
                    ),
        ),
      ),
    );
  }
}
