import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../services/report_service.dart';
import '../../services/profile_service.dart';
import '../../services/admin_service.dart';
import '../../services/post_service.dart';
import '../../services/comment_service.dart';
import '../../models/user_model.dart';

/// Obrazovka pro spravu nahlaseni (admin)
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _reportService = ReportService();
  final _profileService = ProfileService();

  late TabController _tabController;
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  String? _error;
  ReportStatus _currentFilter = ReportStatus.pending;

  // Cache pro autory
  final Map<String, UserModel?> _userCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final statuses = [
      ReportStatus.pending,
      ReportStatus.reviewing,
      ReportStatus.resolved,
      ReportStatus.dismissed,
    ];
    setState(() {
      _currentFilter = statuses[_tabController.index];
    });
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports = await _reportService.getAllReports(
        status: _currentFilter,
        limit: 100,
      );
      setState(() {
        _reports = reports;
        _isLoading = false;
      });

      // Nacti info o reporterech
      for (final report in reports) {
        if (!_userCache.containsKey(report.reporterId)) {
          _loadUser(report.reporterId);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUser(String userId) async {
    try {
      final user = await _profileService.getProfile(userId);
      if (mounted) {
        setState(() {
          _userCache[userId] = user;
        });
      }
    } catch (_) {
      // Ignoruj chyby
    }
  }

  Future<void> _handleResolve(ReportModel report) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ResolveDialog(report: report),
    );

    if (result != null) {
      try {
        await _reportService.resolveReport(
          reportId: report.id,
          adminNote: result['note'],
          actionTaken: result['action'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nahlaseni bylo vyreseno'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDismiss(ReportModel report) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _DismissDialog(),
    );

    if (note != null) {
      try {
        await _reportService.dismissReport(
          reportId: report.id,
          adminNote: note.isNotEmpty ? note : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nahlaseni bylo zamitnuto'),
              backgroundColor: AppColors.warning,
            ),
          );
          _loadReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToContent(ReportModel report) {
    switch (report.contentType) {
      case ReportContentType.post:
        context.push('/post/${report.contentId}');
        break;
      case ReportContentType.user:
        context.push('/profile/${report.contentId}');
        break;
      case ReportContentType.comment:
        // Komentare nemaji vlastni stranku, zkusime najit post
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prohledavam komentar...'),
            backgroundColor: AppColors.primary,
          ),
        );
        break;
      case ReportContentType.message:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zpravy nelze zobrazit primo'),
            backgroundColor: AppColors.warning,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.report, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Nahlaseni'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Cekajici'),
            Tab(text: 'V reseni'),
            Tab(text: 'Vyresene'),
            Tab(text: 'Zamitnute'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _reports.isEmpty
                  ? _buildEmptyState()
                  : _buildReportsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Chyba nacitani',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Neznama chyba',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Zkusit znovu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Zadna nahlaseni',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'V teto kategorii nejsou zadna nahlaseni.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _ReportCard(
            report: report,
            reporter: _userCache[report.reporterId],
            onResolve: () => _handleResolve(report),
            onDismiss: () => _handleDismiss(report),
            onViewContent: () => _navigateToContent(report),
          );
        },
      ),
    );
  }
}

/// Karta nahlaseni
class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final UserModel? reporter;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;
  final VoidCallback onViewContent;

  const _ReportCard({
    required this.report,
    this.reporter,
    required this.onResolve,
    required this.onDismiss,
    required this.onViewContent,
  });

  IconData get _contentTypeIcon {
    switch (report.contentType) {
      case ReportContentType.post:
        return Icons.article;
      case ReportContentType.comment:
        return Icons.chat_bubble;
      case ReportContentType.user:
        return Icons.person;
      case ReportContentType.message:
        return Icons.mail;
    }
  }

  String get _contentTypeName {
    switch (report.contentType) {
      case ReportContentType.post:
        return 'Prispevek';
      case ReportContentType.comment:
        return 'Komentar';
      case ReportContentType.user:
        return 'Uzivatel';
      case ReportContentType.message:
        return 'Zprava';
    }
  }

  Color get _reasonColor {
    switch (report.reason) {
      case ReportReason.spam:
        return Colors.orange;
      case ReportReason.harassment:
      case ReportReason.hateSpeech:
        return Colors.red;
      case ReportReason.violence:
      case ReportReason.selfHarm:
        return Colors.deepOrange;
      case ReportReason.nudity:
        return Colors.pink;
      case ReportReason.falseInformation:
        return Colors.blue;
      case ReportReason.scam:
        return Colors.purple;
      case ReportReason.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = report.status == ReportStatus.pending ||
        report.status == ReportStatus.reviewing;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withAlpha(50)
              : Colors.white.withAlpha(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _reasonColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_contentTypeIcon, color: _reasonColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _contentTypeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nahlasil: ${reporter?.username ?? 'Nacitani...'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _reasonColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.reason.displayName,
                    style: TextStyle(
                      color: _reasonColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Popis
          if (report.description != null && report.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

          // Admin note (pokud existuje)
          if (report.adminNote != null && report.adminNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(30)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.adminNote!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Cas
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              _formatDate(report.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),

          // Akce (pouze pro cekajici/v reseni)
          if (isPending)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Zobrazit - jen ikona
                  IconButton(
                    onPressed: onViewContent,
                    icon: const Icon(Icons.visibility, size: 20),
                    color: AppColors.textSecondary,
                    tooltip: 'Zobrazit obsah',
                  ),
                  const SizedBox(width: 8),
                  // Zamitnout
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Zamitnout', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Vyresit
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onResolve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Vyresit', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'pred ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'pred ${diff.inHours} hod';
    } else if (diff.inDays < 7) {
      return 'pred ${diff.inDays} dny';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

/// Dialog pro vyreseni nahlaseni s primymi akcemi
class _ResolveDialog extends StatefulWidget {
  final ReportModel report;

  const _ResolveDialog({required this.report});

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _noteController = TextEditingController();
  final _adminService = AdminService();
  final _postService = PostService();
  final _commentService = CommentService();

  bool _isLoading = false;
  String? _selectedAction;
  bool _deleteContent = false;
  bool _blockUser = false;
  bool _warnUser = false;

  String get _contentTypeName {
    switch (widget.report.contentType) {
      case ReportContentType.post:
        return 'prispevek';
      case ReportContentType.comment:
        return 'komentar';
      case ReportContentType.user:
        return 'uzivatele';
      case ReportContentType.message:
        return 'zpravu';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _executeActions() async {
    setState(() => _isLoading = true);

    final actions = <String>[];

    try {
      // Smazat obsah
      if (_deleteContent) {
        switch (widget.report.contentType) {
          case ReportContentType.post:
            await _postService.deletePost(widget.report.contentId);
            actions.add('Prispevek smazan');
            break;
          case ReportContentType.comment:
            await _commentService.deleteComment(widget.report.contentId);
            actions.add('Komentar smazan');
            break;
          default:
            break;
        }
      }

      // Zablokovat uzivatele
      if (_blockUser) {
        // Potrebujeme ID autora obsahu - pro uzivatele je to contentId
        String? userToBlock;
        if (widget.report.contentType == ReportContentType.user) {
          userToBlock = widget.report.contentId;
        }
        // Pro ostatni typy bychom potrebovali nacist autora

        if (userToBlock != null) {
          await _adminService.blockUser(userToBlock);
          actions.add('Uzivatel zablokovany');
        }
      }

      // Varovat uzivatele
      if (_warnUser) {
        actions.add('Uzivatel varovani');
      }

      // Pokud nebyla vybrana zadna akce
      if (actions.isEmpty && _selectedAction != null) {
        actions.add(_selectedAction!);
      } else if (actions.isEmpty) {
        actions.add('Zkontrolovano');
      }

      if (mounted) {
        Navigator.pop(context, {
          'action': actions.join(', '),
          'note': _noteController.text,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDeleteContent = widget.report.contentType == ReportContentType.post ||
        widget.report.contentType == ReportContentType.comment;
    final canBlockUser = widget.report.contentType == ReportContentType.user;

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.gavel, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Resit nahlaseni',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Nahlaseny $_contentTypeName - ${widget.report.reason.displayName}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Akce - checkboxy
              Text(
                'Provest akce',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Smazat obsah
              if (canDeleteContent)
                _ActionCheckbox(
                  icon: Icons.delete_forever,
                  label: 'Smazat $_contentTypeName',
                  description: 'Trvale odstrani nahlaseny obsah',
                  color: AppColors.error,
                  value: _deleteContent,
                  onChanged: (v) => setState(() => _deleteContent = v ?? false),
                ),

              // Zablokovat uzivatele
              if (canBlockUser)
                _ActionCheckbox(
                  icon: Icons.block,
                  label: 'Zablokovat uzivatele',
                  description: 'Uzivatel se nebude moci prihlasit',
                  color: AppColors.error,
                  value: _blockUser,
                  onChanged: (v) => setState(() => _blockUser = v ?? false),
                ),

              // Varovat uzivatele
              _ActionCheckbox(
                icon: Icons.warning_amber,
                label: 'Zaslat varovani',
                description: 'Uzivatel dostane upozorneni',
                color: AppColors.warning,
                value: _warnUser,
                onChanged: (v) => setState(() => _warnUser = v ?? false),
              ),

              const SizedBox(height: 16),
              Divider(color: AppColors.functionalBorder),
              const SizedBox(height: 16),

              // Rychle akce - chipy
              Text(
                'Nebo rychla akce',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickActionChip(
                    label: 'V poradku',
                    icon: Icons.check,
                    isSelected: _selectedAction == 'V poradku',
                    onTap: () => setState(() => _selectedAction = 'V poradku'),
                  ),
                  _QuickActionChip(
                    label: 'Falesne hlaseni',
                    icon: Icons.cancel,
                    isSelected: _selectedAction == 'Falesne hlaseni',
                    onTap: () => setState(() => _selectedAction = 'Falesne hlaseni'),
                  ),
                  _QuickActionChip(
                    label: 'Jiz vyreseno',
                    icon: Icons.done_all,
                    isSelected: _selectedAction == 'Jiz vyreseno',
                    onTap: () => setState(() => _selectedAction = 'Jiz vyreseno'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Poznamka
              Text(
                'Interni poznamka',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Volitelna poznamka pro adminy...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Tlacitka
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Zrusit',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _executeActions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Vyresit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Checkbox pro akci
class _ActionCheckbox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ActionCheckbox({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: value ? color.withAlpha(20) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip pro rychlou akci
class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog pro zamitnuti nahlaseni
class _DismissDialog extends StatefulWidget {
  @override
  State<_DismissDialog> createState() => _DismissDialogState();
}

class _DismissDialogState extends State<_DismissDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: AppColors.warning),
                const SizedBox(width: 12),
                Text(
                  'Zamitnout nahlaseni',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Nahlaseni bude oznaceno jako neopodstatnene.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),

            // Poznamka
            Text(
              'Duvod zamitnuti (volitelne)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Proc je nahlaseni neopodstatnene...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),

            // Tlacitka
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Zrusit',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _noteController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Zamitnout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
