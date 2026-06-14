import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/upload_provider.dart';
import '../../providers/topic_provider.dart';
import '../../models/upload_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/extensions.dart';

class NotesScreen extends StatefulWidget {
  final bool embedded;
  const NotesScreen({super.key, this.embedded = false});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UploadProvider>().loadUploads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
        automaticallyImplyLeading: false,
        title: const Text('Notes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadSheet(context),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload'),
      ),
      body: Consumer<UploadProvider>(
        builder: (context, provider, _) {
          if (provider.isUploading || provider.isPolling) {
            return _UploadProgressView(provider: provider);
          }

          if (provider.uploadStatus == UploadStatus.done) {
            return _UploadSuccessView(provider: provider);
          }

          if (provider.uploads.isEmpty) {
            return _EmptyUploads(onUpload: () => _showUploadSheet(context));
          }

          return _UploadsList(provider: provider);
        },
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<UploadProvider>(),
        child: _UploadSheet(),
      ),
    );
  }
}

class _EmptyUploads extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyUploads({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_rounded,
                  size: 36, color: AppTheme.primary),
            ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
            const SizedBox(height: 20),
            Text('Upload your notes',
                    style: Theme.of(context).textTheme.headlineSmall)
                .animate()
                .fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Upload PDF, DOCX, or TXT files and we\'ll automatically generate flashcards for you.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Upload File'),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['PDF', 'DOCX', 'TXT'].map((ext) => Chip(
                    label: Text(ext),
                    avatar: const Icon(Icons.description_outlined, size: 14),
                  )).toList(),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _UploadProgressView extends StatelessWidget {
  final UploadProvider provider;
  const _UploadProgressView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isPolling = provider.isPolling;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: isPolling ? provider.uploadProgress : null,
                strokeWidth: 5,
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceVariant,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 24),
            Text(
              isPolling ? 'Generating cards…' : 'Uploading file…',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              isPolling
                  ? 'Extracting text and building flashcards'
                  : 'Sending file to server',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms),
            if (isPolling) ...[
              const SizedBox(height: 20),
              Text(
                '${(provider.uploadProgress * 100).toInt()}%',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: AppTheme.primary),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadSuccessView extends StatelessWidget {
  final UploadProvider provider;
  const _UploadSuccessView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final count = provider.generatedCards.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 44, color: AppTheme.secondary),
            )
                .animate()
                .scale(curve: Curves.elasticOut, duration: 600.ms)
                .fadeIn(),
            const SizedBox(height: 20),
            Text('Cards Generated!',
                    style: Theme.of(context).textTheme.headlineMedium)
                .animate()
                .fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              '$count flashcards created from your notes.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            // Preview first 3 cards
            ...provider.generatedCards.take(3).map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Text(
                    c.question,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.resetUploadState(),
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Upload Another'),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => provider.resetUploadState(),
              child: const Text('Done'),
            ).animate().fadeIn(delay: 450.ms),
          ],
        ),
      ),
    );
  }
}

class _UploadsList extends StatelessWidget {
  final UploadProvider provider;
  const _UploadsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: provider.uploads.length,
      itemBuilder: (context, i) {
        final upload = provider.uploads[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _UploadTile(upload: upload, provider: provider),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      },
    );
  }
}

class _UploadTile extends StatelessWidget {
  final UploadModel upload;
  final UploadProvider provider;

  const _UploadTile({required this.upload, required this.provider});

  @override
  Widget build(BuildContext context) {
    final statusColor = upload.isDone
        ? AppTheme.secondary
        : upload.isFailed
            ? AppTheme.error
            : AppTheme.accent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _fileTypeColor(upload.fileType).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _fileTypeIcon(upload.fileType),
              color: _fileTypeColor(upload.fileType),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upload.originalFilename,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      upload.statusLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: statusColor),
                    ),
                    if (upload.fileSizeBytes != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        upload.fileSizeLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            upload.uploadedAt.relativeTime,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppTheme.textDisabled,
            onPressed: () => provider.deleteUpload(upload.id),
          ),
        ],
      ),
    );
  }

  IconData _fileTypeIcon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'docx': return Icons.description_rounded;
      default: return Icons.article_rounded;
    }
  }

  Color _fileTypeColor(String type) {
    switch (type) {
      case 'pdf': return AppTheme.error;
      case 'docx': return const Color(0xFF2B7CD3);
      default: return AppTheme.textSecondary;
    }
  }
}

class _UploadSheet extends StatefulWidget {
  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  String? _selectedTopicId;
  PlatformFile? _pickedFile;
  bool _picking = false;

  Future<void> _pickFile() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _pickedFile = result.files.first);
      }
    } finally {
      setState(() => _picking = false);
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null || _pickedFile!.path == null) return;

    final provider = context.read<UploadProvider>();
    Navigator.of(context).pop();
    await provider.uploadFile(
      filePath: _pickedFile!.path!,
      fileName: _pickedFile!.name,
      topicId: _selectedTopicId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<TopicProvider>().topics;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Upload Notes',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('PDF, DOCX, or TXT files up to 20 MB',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),

          // File picker
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _pickedFile != null
                      ? AppTheme.primary
                      : AppTheme.divider,
                  width: _pickedFile != null ? 1.5 : 1,
                ),
              ),
              child: _picking
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary))
                  : _pickedFile != null
                      ? Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(_pickedFile!.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    '${(_pickedFile!.size / 1024).toStringAsFixed(0)} KB',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _pickFile,
                              child: const Text('Change'),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const Icon(Icons.cloud_upload_rounded,
                                size: 36, color: AppTheme.primary),
                            const SizedBox(height: 8),
                            Text('Tap to choose file',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall),
                            const SizedBox(height: 4),
                            Text('PDF · DOCX · TXT',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppTheme.textSecondary)),
                          ],
                        ),
            ),
          ),

          const SizedBox(height: 16),

          // Topic selector
          Text('Add to topic (optional)',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TopicChip(
                  label: 'None',
                  selected: _selectedTopicId == null,
                  onTap: () =>
                      setState(() => _selectedTopicId = null),
                ),
                const SizedBox(width: 8),
                ...topics.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TopicChip(
                        label: t.title,
                        selected: _selectedTopicId == t.id,
                        color: t.color,
                        onTap: () =>
                            setState(() => _selectedTopicId = t.id),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _pickedFile != null ? _upload : null,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Upload & Generate Cards'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? c.withOpacity(0.4) : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? c : AppTheme.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
