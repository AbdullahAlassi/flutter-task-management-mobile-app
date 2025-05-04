import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
  bool _isLoading = true;
  String? _error;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  Future<void> _initializePreview() async {
    try {
      if (widget.fileType.toLowerCase().contains('pdf')) {
        await _downloadAndSavePdf();
      } else if (widget.fileType.toLowerCase().contains('video')) {
        await _initializeVideo();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      final response = await http.get(Uri.parse(widget.attachmentUrl));
      final bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${widget.fileName}');
      await file.writeAsBytes(bytes);

      setState(() {
        _localPath = file.path;
      });
    } catch (e) {
      setState(() {
        _error = 'Error downloading PDF: $e';
      });
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.network(widget.attachmentUrl);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
    } catch (e) {
      setState(() {
        _error = 'Error initializing video: $e';
      });
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
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Attachment'),
                        content: const Text(
                          'Are you sure you want to delete this attachment?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onDelete?.call();
                              Navigator.pop(context);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : _buildPreview(),
    );
  }

  Widget _buildPreview() {
    if (widget.fileType.toLowerCase().contains('pdf')) {
      if (_localPath == null) {
        return const Center(child: Text('Error loading PDF'));
      }
      return PDFView(
        filePath: _localPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          setState(() {
            _error = 'Error loading PDF: $error';
          });
        },
        onPageError: (page, error) {
          setState(() {
            _error = 'Error loading page $page: $error';
          });
        },
      );
    } else if (widget.fileType.toLowerCase().contains('video')) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const Center(child: Text('Error loading video'));
      }
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _videoController!.value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  });
                },
              ),
            ],
          ),
        ),
      );
    } else if (widget.fileType.toLowerCase().contains('image')) {
      return InteractiveViewer(
        child: Image.network(
          widget.attachmentUrl,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Error loading image: $error'),
                ],
              ),
            );
          },
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(widget.fileName),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(widget.attachmentUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open file')),
                    );
                  }
                }
              },
              child: const Text('Open File'),
            ),
          ],
        ),
      );
    }
  }
}
