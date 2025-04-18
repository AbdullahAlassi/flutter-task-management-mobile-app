import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class AttachmentPreviewScreen extends StatefulWidget {
  final String attachmentUrl;
  final String fileName;
  final String fileType;
  final VoidCallback? onDelete;

  const AttachmentPreviewScreen({
    super.key,
    required this.attachmentUrl,
    required this.fileName,
    required this.fileType,
    this.onDelete,
  });

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.fileType.startsWith('video/')) {
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    try {
      String url = widget.attachmentUrl;
      if (url.startsWith('/') || url.contains(':\\')) {
        url = 'file://$url';
      }

      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                String url = widget.attachmentUrl;
                if (url.startsWith('/') || url.contains(':\\')) {
                  url = 'file://$url';
                }

                final uri = Uri.parse(url);
                if (!await launchUrl(uri)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open the file')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Attachment'),
                        content: Text(
                          'Are you sure you want to delete "${widget.fileName}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );

                if (confirmed == true && context.mounted) {
                  widget.onDelete!();
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: Center(child: _buildPreview()),
    );
  }

  Widget _buildPreview() {
    if (widget.fileType.startsWith('image/')) {
      if (widget.attachmentUrl.startsWith('/') ||
          widget.attachmentUrl.contains(':\\')) {
        // Handle local file
        return InteractiveViewer(
          child: Image.file(
            File(widget.attachmentUrl),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading local image: $error');
              return const Center(child: Text('Failed to load image'));
            },
          ),
        );
      } else {
        // Handle network image
        return InteractiveViewer(
          child: Image.network(
            widget.attachmentUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading network image: $error');
              return const Center(child: Text('Failed to load image'));
            },
          ),
        );
      }
    } else if (widget.fileType == 'application/pdf') {
      return PdfView(path: widget.attachmentUrl);
    } else if (widget.fileType.startsWith('video/')) {
      if (!_isVideoInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getFileIcon(), size: 64),
          const SizedBox(height: 16),
          Text(widget.fileName, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'File type: ${widget.fileType}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                String url = widget.attachmentUrl;
                if (url.startsWith('/') || url.contains(':\\')) {
                  url = 'file://$url';
                }

                final uri = Uri.parse(url);
                if (!await launchUrl(uri)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open the file')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Download File'),
          ),
        ],
      );
    }
  }

  IconData _getFileIcon() {
    if (widget.fileType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (widget.fileType == 'application/msword' ||
        widget.fileType ==
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      return Icons.description;
    } else if (widget.fileType == 'application/vnd.ms-excel' ||
        widget.fileType ==
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      return Icons.table_chart;
    } else if (widget.fileType == 'application/vnd.ms-powerpoint' ||
        widget.fileType ==
            'application/vnd.openxmlformats-officedocument.presentationml.presentation') {
      return Icons.slideshow;
    } else if (widget.fileType == 'application/zip' ||
        widget.fileType == 'application/x-zip-compressed') {
      return Icons.archive;
    } else {
      return Icons.insert_drive_file;
    }
  }
}
