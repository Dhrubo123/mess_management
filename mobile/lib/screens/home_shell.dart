import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../config/api_config.dart';
import '../l10n/app_strings.dart';
import '../services/api_service.dart';
import '../services/report_pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sheets.dart';
import '../widgets/shimmer_loading.dart';

class HomeShell extends StatefulWidget {
  final VoidCallback onLogout;
  const HomeShell({super.key, required this.onLogout});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  int _ledgerTab = 0; // 0: Bazar, 1: Deposits, 2: Fixed Bills, 3: Meals
  bool _loading = true;
  bool _mealOnlyView = true; // true = Meal Taka Only, false = Meal + Rent + Fixed Bills
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  Map<String, dynamic>? _user;
  List<dynamic> _messes = [];
  int? _activeMessId;
  Map<String, dynamic>? _summary;
  List<dynamic> _bazars = [];
  List<dynamic> _deposits = [];
  List<dynamic> _fixedBills = [];
  List<dynamic> _meals = [];
  List<dynamic> _listings = [];
  List<dynamic> _banners = [];

  final _areaSearchCtrl = TextEditingController();
  String _selectedAreaChip = 'All';
  final _quickAreas = const [
    'All',
    'Chawk Bazar',
    '2 No. Gate',
    'GEC Circle',
    'Muradpur',
    'Agrabad',
    'Halishahar',
    'Bahaddarhat',
    'Jamal Khan',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _areaSearchCtrl.dispose();
    super.dispose();
  }

  bool get _isManager => _summary?['my_role'] == 'manager';
  bool get _isMonthClosed => _summary?['month']?['status'] == 'closed';
  bool get _hasBreakfast => _summary?['mess']?['has_breakfast'] == true;

  Map<String, String> get _monthQuery => {
        'year': _selectedYear.toString(),
        'month': _selectedMonth.toString(),
      };

  Future<void> _changeMonth(int delta) async {
    HapticFeedback.selectionClick();
    final dt = DateTime(_selectedYear, _selectedMonth + delta, 1);
    setState(() {
      _selectedYear = dt.year;
      _selectedMonth = dt.month;
    });
    if (_activeMessId != null) {
      await _loadMessData(_activeMessId!);
    }
  }

  Future<void> _toggleMonthLock() async {
    if (_activeMessId == null) return;
    final closing = !_isMonthClosed;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(closing ? S.t('close_month') : S.t('reopen_month')),
        content: Text(
          closing
              ? 'Lock all meals, bazar, deposits, and bills for ${_summary?['month']?['label']}?'
              : 'Reopen ${_summary?['month']?['label']} to allow edits again?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(closing ? S.t('close_month') : S.t('reopen_month')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final path = closing
          ? '/messes/$_activeMessId/months/close'
          : '/messes/$_activeMessId/months/reopen';
      await ApiService.post(path, {'year': _selectedYear, 'month': _selectedMonth});
      await _loadMessData(_activeMessId!);
      _showSnack(closing ? 'Month closed & locked!' : 'Month reopened!');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/auth/me'),
        ApiService.get('/messes'),
        ApiService.get('/seat-listings'),
        ApiService.get('/sponsor-banners'),
      ]);

      final messes = (results[1]['messes'] as List?) ?? [];
      int? selectedId = _activeMessId;
      if (selectedId == null && messes.isNotEmpty) {
        selectedId = messes.first['id'] as int;
      }

      setState(() {
        _user = results[0]['user'] as Map<String, dynamic>?;
        _messes = messes;
        _activeMessId = selectedId;
        _listings = (results[2]['listings'] as List?) ?? [];
        _banners = (results[3]['banners'] as List?) ?? [];
      });

      if (selectedId != null) {
        await _loadMessData(selectedId);
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMessData(int messId) async {
    final q = _monthQuery;
    final results = await Future.wait([
      ApiService.get('/messes/$messId/summary', q),
      ApiService.get('/messes/$messId/bazars', q),
      ApiService.get('/messes/$messId/deposits', q),
      ApiService.get('/messes/$messId/fixed-bills', q),
      ApiService.get('/messes/$messId/meals', q),
    ]);
    if (mounted) {
      setState(() {
        _summary = results[0];
        _bazars = (results[1]['bazars'] as List?) ?? [];
        _deposits = (results[2]['deposits'] as List?) ?? [];
        _fixedBills = (results[3]['fixed_bills'] as List?) ?? [];
        _meals = (results[4]['meals'] as List?) ?? [];
      });
    }
  }

  Future<void> _searchListings([String? areaOverride]) async {
    try {
      final area = areaOverride ?? _areaSearchCtrl.text.trim();
      final query = (area.isNotEmpty && area != 'All') ? {'area': area} : null;
      final res = await ApiService.get('/seat-listings', query);
      final bannerRes = await ApiService.get('/sponsor-banners', query);
      if (mounted) {
        setState(() {
          _listings = (res['listings'] as List?) ?? [];
          _banners = (bannerRes['banners'] as List?) ?? [];
        });
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _toggleLanguage() async {
    await AppLocale.toggle();
    try {
      await ApiService.patch('/auth/profile', {'locale': AppLocale.current.value});
    } catch (_) {}
  }

  Future<void> _openShareReportSheet() async {
    if (_activeMessId == null || _summary == null) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocale.isBn ? 'মাসিক রিপোর্ট শেয়ার করুন' : 'Share Monthly Report',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocale.isBn ? 'হোয়াটসঅ্যাপ বা মেসেঞ্জার গ্রুপে পাঠান' : 'Send directly to your mess WhatsApp or Messenger group',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
              ),
              title: Text(AppLocale.isBn ? 'PDF স্টেটমেন্ট (WhatsApp)' : 'Share PDF Statement', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(AppLocale.isBn ? 'টেবিলসহ পূর্ণাঙ্গ মাসিক হিসাব PDF' : 'Clean A4 table with meals, money given & fixed bills'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ReportPdfService.generateAndShare(_summary!);
                } catch (e) {
                  _showSnack(e.toString(), isError: true);
                }
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chat_rounded, color: AppColors.amber),
              ),
              title: Text(AppLocale.isBn ? 'টেক্সট মেসেজ শেয়ার' : 'Share Formatted Text', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(AppLocale.isBn ? 'দ্রুত চ্যাটে পাঠানোর জন্য সংক্ষিপ্ত হিসাব' : 'Quick summary message for WhatsApp / Messenger'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                Navigator.pop(ctx);
                await _copySummary(AppLocale.current.value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copySummary(String locale) async {
    if (_activeMessId == null) return;
    try {
      final res = await ApiService.get('/messes/$_activeMessId/share-text', {
        ..._monthQuery,
        'locale': locale,
      });
      final text = res['share_text'] as String;
      await Clipboard.setData(ClipboardData(text: text));
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _confirmAndDelete({
    required String title,
    required String apiPath,
    required String successMsg,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $title?'),
        content: const Text('This entry will be removed and monthly totals will recalculate immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.delete(apiPath);
      if (_activeMessId != null) await _loadMessData(_activeMessId!);
      _showSnack(successMsg);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _copyPreviousBills() async {
    if (_activeMessId == null) return;
    try {
      final res = await ApiService.post('/messes/$_activeMessId/fixed-bills/copy-previous', {
        'year': _selectedYear,
        'month': _selectedMonth,
      });
      await _loadMessData(_activeMessId!);
      _showSnack(res['message']?.toString() ?? 'Copied last month\'s bills!');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messName = _summary?['mess']?['name'] ?? 'MessMate BD';
    final messArea = _summary?['mess']?['area'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(messName, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (messArea != null)
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    '$messArea, ${_summary?['mess']?['city'] ?? 'Chattogram'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  AppLocale.isBn ? 'EN' : 'বাংলা',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: S.t('create_or_join'),
            icon: const Icon(Icons.add_home_work_outlined),
            onPressed: () async {
              if (await AppSheets.showCreateOrJoinMess(context)) {
                await _loadInitial();
                _showSnack('Mess updated!');
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const DashboardShimmer()
          : IndexedStack(
              index: _tabIndex,
              children: [
                _buildDashboardTab(),
                _buildLedgerTab(),
                _buildToLetTab(),
                _buildProfileTab(),
              ],
            ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: AppShadows.nav,
        ),
        child: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) {
            if (i != _tabIndex) {
              HapticFeedback.selectionClick();
              setState(() => _tabIndex = i);
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.space_dashboard_outlined),
              selectedIcon: const Icon(Icons.space_dashboard_rounded, color: AppColors.primary),
              label: S.t('tab_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: S.t('tab_ledger'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.bed_outlined),
              selectedIcon: const Icon(Icons.bed_rounded, color: AppColors.primary),
              label: S.t('tab_tolet'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
              label: S.t('tab_profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab() {
    if (_tabIndex == 1 && _activeMessId != null && !_isMonthClosed) {
      if (_ledgerTab == 0) {
        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () async {
            if (await AppSheets.showAddBazar(context, _activeMessId!)) {
              await _loadMessData(_activeMessId!);
              _showSnack('Bazar expense added!');
            }
          },
          icon: const Icon(Icons.shopping_basket_outlined),
          label: const Text('Add Bazar'),
        );
      }
      if (_ledgerTab == 1 && _isManager) {
        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () async {
            final members = (_summary?['members'] as List?) ?? [];
            if (await AppSheets.showAddDeposit(context, _activeMessId!, members)) {
              await _loadMessData(_activeMessId!);
              _showSnack('Deposit recorded!');
            }
          },
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Add Deposit'),
        );
      }
      if (_ledgerTab == 2 && _isManager) {
        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () async {
            if (await AppSheets.showAddFixedBill(context, _activeMessId!)) {
              await _loadMessData(_activeMessId!);
              _showSnack('Fixed bill added!');
            }
          },
          icon: const Icon(Icons.receipt_outlined),
          label: const Text('Add Bill'),
        );
      }
      if (_ledgerTab == 3) {
        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () async {
            if (await AppSheets.showLogMeal(context, _activeMessId!, hasBreakfast: _hasBreakfast)) {
              await _loadMessData(_activeMessId!);
              _showSnack('Meals saved!');
            }
          },
          icon: const Icon(Icons.restaurant_menu_rounded),
          label: const Text('Log Meal'),
        );
      }
    }

    if (_tabIndex == 2) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final messFacilities = ((_summary?['mess']?['facilities'] as List?) ?? [])
              .map((e) => e.toString())
              .toList();
          if (await AppSheets.showPostSeat(
            context,
            messId: _activeMessId,
            defaultArea: _summary?['mess']?['area'] ?? 'Chawk Bazar',
            defaultPhone: _user?['phone']?.toString() ?? '',
            defaultFacilities: messFacilities,
          )) {
            await _searchListings();
            _showSnack('Seat listing published!');
          }
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Post Seat'),
      );
    }
    return null;
  }

  // ==================== TAB 0: DASHBOARD ====================
  Widget _buildDashboardTab() {
    if (_summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.home_work_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('No Active Mess Yet', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Create your bachelor mess or join an existing one with a 6-character invite code.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  if (await AppSheets.showCreateOrJoinMess(context)) {
                    await _loadInitial();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create or Join Mess'),
              ),
            ],
          ),
        ),
      );
    }

    final totals = _summary!['totals'] as Map<String, dynamic>;
    final members = (_summary!['members'] as List?) ?? [];
    final monthLabel = _summary!['month']?['label'] ?? '';

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Fintech Hero Wallet Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0C6B54), AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.hero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _changeMonth(-1),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                          Text(
                            monthLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          InkWell(
                            onTap: () => _changeMonth(1),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_isMonthClosed)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.amberBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, size: 11, color: AppColors.amber),
                            const SizedBox(width: 3),
                            Text(
                              S.t('month_closed'),
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.amber),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      '${totals['member_count']} ${S.t('members')}',
                      style: const TextStyle(color: Color(0xFFB7E4D8), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(S.t('current_meal_rate'), style: const TextStyle(color: Color(0xFFB7E4D8), fontSize: 13)),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Row(
                    key: ValueKey('rate-$_selectedYear-$_selectedMonth-${totals['meal_rate']}'),
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '৳${totals['meal_rate']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(S.t('per_meal'), style: const TextStyle(color: Color(0xFFB7E4D8), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _heroMiniStat(S.t('total_meals'), '${totals['total_meals']}'),
                    const SizedBox(width: 10),
                    _heroMiniStat(S.t('total_bazar'), '৳${totals['total_bazar']}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _heroMiniStat(S.t('cash_in_hand'), '৳${totals['cash_in_hand']}'),
                    const SizedBox(width: 10),
                    _heroMiniStat(S.t('fixed_per_person'), '৳${totals['per_member_fixed_share']}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Live Kitchen Count Card for Bua & Manager
          Builder(builder: (_) {
            final kitchen = (_summary!['today_kitchen'] as Map<String, dynamic>?) ?? {};
            final bCount = kitchen['breakfast'] ?? 0;
            final lCount = kitchen['lunch'] ?? 0;
            final dCount = kitchen['dinner'] ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.soup_kitchen_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.t('today_kitchen'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          _hasBreakfast
                              ? '${S.t('breakfast')}: $bCount  •  ${S.t('lunch')}: $lCount  •  ${S.t('dinner')}: $dCount'
                              : '${S.t('lunch')}: $lCount  •  ${S.t('dinner')}: $dCount',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  if (_isManager && !_isMonthClosed)
                    TextButton(
                      onPressed: () async {
                        if (await AppSheets.showBulkMeals(context, _activeMessId!, members, hasBreakfast: _hasBreakfast)) {
                          await _loadMessData(_activeMessId!);
                          _showSnack('All roommate meals updated!');
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(S.t('manage_all'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),

          if (_isMonthClosed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.t('month_locked_banner'),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.amber),
                    ),
                  ),
                  if (_isManager)
                    TextButton(
                      onPressed: _toggleMonthLock,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.amber,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(S.t('reopen_month'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Quick Actions Row
          Row(
            children: [
              _quickAction(Icons.restaurant_rounded, S.t('log_meal'), () async {
                if (_isMonthClosed) {
                  _showSnack(S.t('month_locked_banner'), isError: true);
                  return;
                }
                if (await AppSheets.showLogMeal(context, _activeMessId!, hasBreakfast: _hasBreakfast)) {
                  await _loadMessData(_activeMessId!);
                  _showSnack('Meals updated!');
                }
              }),
              _quickAction(Icons.shopping_bag_rounded, S.t('add_bazar'), () async {
                if (_isMonthClosed) {
                  _showSnack(S.t('month_locked_banner'), isError: true);
                  return;
                }
                if (await AppSheets.showAddBazar(context, _activeMessId!)) {
                  await _loadMessData(_activeMessId!);
                  _showSnack('Bazar added!');
                }
              }),
              if (_isManager)
                _quickAction(Icons.payments_rounded, S.t('deposit'), () async {
                  if (_isMonthClosed) {
                    _showSnack(S.t('month_locked_banner'), isError: true);
                    return;
                  }
                  if (await AppSheets.showAddDeposit(context, _activeMessId!, members)) {
                    await _loadMessData(_activeMessId!);
                    _showSnack('Deposit recorded!');
                  }
                })
              else
                _quickAction(Icons.receipt_long_rounded, S.t('tab_ledger'), () => setState(() => _tabIndex = 1)),
              _quickAction(Icons.share_rounded, S.t('share_summary'), _openShareReportSheet),
            ],
          ),

          if (_isManager && !_isMonthClosed) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _toggleMonthLock,
                icon: const Icon(Icons.lock_outline_rounded, size: 16),
                label: Text(S.t('close_month')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // What's Included & Monthly Package Breakdown Card
          Builder(builder: (_) {
            final messFacilities = (_summary!['mess']?['facilities'] as List?) ?? [];
            final bills = (_summary!['fixed_bills'] as List?) ?? [];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        AppLocale.isBn ? 'মাসিক প্যাকেজ ও সুবিধাসমূহ' : 'What\'s Included & Monthly Bills',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Food Row
                  Row(
                    children: [
                      const Icon(Icons.restaurant_outlined, size: 16, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocale.isBn
                              ? 'খাবার: মিল রেট সিস্টেম (${_hasBreakfast ? 'সকাল, দুপুর ও রাত' : 'দুপুর ও রাত'})'
                              : 'Food: Meal-Rate System (${_hasBreakfast ? '3 Meals' : 'Lunch & Dinner'})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '৳${totals['meal_rate']}/meal',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (bills.isNotEmpty) ...[
                    const Divider(height: 18, color: AppColors.border),
                    ...bills.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b['title']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                                ),
                              ),
                              Text(
                                '৳${b['per_member']}/person',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                            ],
                          ),
                        )),
                  ],
                  if (messFacilities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: messFacilities
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  f.toString(),
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Section Header + Meal Only / All Toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.t('member_balances'), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                    Text(
                      _mealOnlyView
                          ? (AppLocale.isBn
                              ? 'মোট মিল জমা: ৳${totals['total_meal_deposits']}'
                              : 'Meal Fund Collected: ৳${totals['total_meal_deposits']}')
                          : (AppLocale.isBn
                              ? 'মোট জমা (মিল + বিল): ৳${totals['total_deposits']}'
                              : 'Total Collected: ৳${totals['total_deposits']}'),
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _balanceModeChip(AppLocale.isBn ? 'শুধু মিল' : 'Meal Only', _mealOnlyView, () => setState(() => _mealOnlyView = true)),
                    _balanceModeChip(AppLocale.isBn ? 'সব বিল' : 'All Bills', !_mealOnlyView, () => setState(() => _mealOnlyView = false)),
                  ],
                ),
              ),
            ],
          ),
          if (_isManager && !_isMonthClosed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocale.isBn ? 'টিপস: সদস্যের উপর ট্যাপ করে জমা নিন' : 'Tap any member to record deposit',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      if (await AppSheets.showAddMember(context, _activeMessId!)) {
                        await _loadMessData(_activeMessId!);
                        _showSnack('Roommate added to mess!');
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: Text(AppLocale.isBn ? '+ সদস্য যোগ' : '+ Add Member', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          ...members.map((m) {
            final shownCost = (_mealOnlyView ? m['meal_cost'] : m['total_cost']) as num;
            final shownPaid = (_mealOnlyView ? m['meal_deposit'] : m['total_paid']) as num;
            final shownNet = ((_mealOnlyView ? m['meal_balance'] : m['net_balance']) as num).toDouble();
            final isPos = shownNet >= 0;
            final isMgr = m['role'] == 'manager';
            final noDeposit = shownPaid <= 0;
            final progress = shownCost > 0 ? (shownPaid / shownCost).clamp(0.0, 1.0).toDouble() : (shownPaid > 0 ? 1.0 : 0.0);

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: (_isManager && !_isMonthClosed)
                  ? () async {
                      if (await AppSheets.showAddDeposit(
                        context,
                        _activeMessId!,
                        members,
                        initialUserId: m['user_id'] as int,
                      )) {
                        await _loadMessData(_activeMessId!);
                        _showSnack('Deposit recorded for ${m['name']}!');
                      }
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: noDeposit ? AppColors.danger.withValues(alpha: 0.35) : AppColors.border,
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: isMgr ? AppColors.primary : AppColors.primaryLight,
                          foregroundColor: isMgr ? Colors.white : AppColors.primary,
                          child: Text(
                            (m['name'] as String).substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      m['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isMgr) ...[
                                    const SizedBox(width: 6),
                                    _badge(S.t('manager'), AppColors.amberBg, AppColors.amber),
                                  ],
                                  if (noDeposit) ...[
                                    const SizedBox(width: 6),
                                    _badge(AppLocale.isBn ? 'জমা দেয়নি' : 'UNPAID', AppColors.dangerBg, AppColors.danger),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${m['total_meals']} ${S.t('meals')}  •  ${S.t('cost')} ৳$shownCost  •  ${S.t('paid')} ৳$shownPaid',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPos ? AppColors.primaryLight : AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isPos ? '+৳${shownNet.toStringAsFixed(0)}' : '-৳${shownNet.abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: isPos ? AppColors.primary : AppColors.danger,
                                ),
                              ),
                              Text(
                                isPos ? S.t('refund') : S.t('due'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isPos ? AppColors.primary : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: AppColors.surface,
                        color: isPos ? AppColors.accent : (noDeposit ? AppColors.danger : AppColors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _balanceModeChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _heroMiniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFFB7E4D8), fontSize: 11.5)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB 1: LEDGER ====================
  Widget _buildLedgerTab() {
    final labels = [S.t('bazar'), S.t('deposits'), S.t('fixed_bills'), S.t('meals_tab')];
    return Column(
      children: [
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: labels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final active = _ledgerTab == i;
              return ChoiceChip(
                label: Text(labels[i]),
                selected: active,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: active ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _ledgerTab = i),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _activeMessId != null ? _loadMessData(_activeMessId!) : Future.value(),
            child: _ledgerTab == 0
                ? _buildBazarList()
                : _ledgerTab == 1
                    ? _buildDepositList()
                    : _ledgerTab == 2
                        ? _buildFixedBillList()
                        : _buildMealList(),
          ),
        ),
      ],
    );
  }

  void _openPhotoViewer(String rawPath, String title) {
    final url = ApiConfig.resolveMediaUrl(rawPath);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Photo',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, _) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Could not load photo', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 48,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBazarList() {
    if (_bazars.isEmpty) return _emptyState(Icons.shopping_basket_outlined, 'No bazar entries yet');
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: _bazars.length,
      itemBuilder: (_, i) {
        final b = _bazars[i];
        final receiptUrl = b['receipt_url']?.toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (receiptUrl != null && receiptUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => _openPhotoViewer(receiptUrl, 'Bazar Slip • ${b['bazar_date'] ?? ''}'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      ApiConfig.resolveMediaUrl(receiptUrl),
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 46,
                        height: 46,
                        color: AppColors.amberBg,
                        child: const Icon(Icons.receipt_long, color: AppColors.amber, size: 20),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.amber, size: 20),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(b['buyer']?['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _openPhotoViewer(receiptUrl, 'Bazar Slip • ${b['bazar_date'] ?? ''}'),
                            child: _badge('SLIP', AppColors.primaryLight, AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b['items_note']?.toString().isNotEmpty == true ? b['items_note'] : 'Daily grocery bazar',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(b['bazar_date'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('৳${b['amount']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
              if (_isManager && !_isMonthClosed)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete Bazar',
                  onPressed: () => _confirmAndDelete(
                    title: 'Bazar Entry',
                    apiPath: '/messes/$_activeMessId/bazars/${b['id']}',
                    successMsg: 'Bazar entry deleted.',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepositList() {
    if (_deposits.isEmpty) return _emptyState(Icons.account_balance_wallet_outlined, 'No deposits recorded yet');
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: _deposits.length,
      itemBuilder: (_, i) {
        final d = _deposits[i];
        final method = (d['payment_method'] ?? 'cash').toString().toUpperCase();
        final badgeColor = method == 'BKASH'
            ? const Color(0xFFE2136E)
            : method == 'NAGAD'
                ? const Color(0xFFF26522)
                : AppColors.primary;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(method, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['user']?['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '${d['deposit_date']} • ${d['deposit_type'] == 'fixed_bill' ? 'Fixed Bill' : 'Meal Fund'}${d['reference'] != null ? ' • ${d['reference']}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text('+৳${d['amount']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppColors.primary)),
              if (_isManager && !_isMonthClosed)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete Deposit',
                  onPressed: () => _confirmAndDelete(
                    title: 'Deposit',
                    apiPath: '/messes/$_activeMessId/deposits/${d['id']}',
                    successMsg: 'Deposit deleted.',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFixedBillList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      children: [
        if (_isManager && !_isMonthClosed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: _copyPreviousBills,
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: Text(AppLocale.isBn ? 'গত মাসের ফিক্সড বিল কপি করুন' : 'Copy Last Month\'s Bills'),
            ),
          ),
        if (_fixedBills.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Column(
              children: [
                Icon(Icons.receipt_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text(S.t('no_bills'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        else
          ..._fixedBills.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            'Category: ${(b['category'] ?? 'other').toString().toUpperCase()} • ${S.t('equal_split')}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Text('৳${b['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    if (_isManager && !_isMonthClosed)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete Bill',
                        onPressed: () => _confirmAndDelete(
                          title: 'Fixed Bill',
                          apiPath: '/messes/$_activeMessId/fixed-bills/${b['id']}',
                          successMsg: 'Fixed bill deleted.',
                        ),
                      ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildMealList() {
    if (_meals.isEmpty) return _emptyState(Icons.restaurant_menu_rounded, 'No meals logged yet');
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: _meals.length,
      itemBuilder: (_, i) {
        final m = _meals[i];
        final total = (m['breakfast'] as num) + (m['lunch'] as num) + (m['dinner'] as num) + (m['guest_meals'] as num);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${m['user']?['name'] ?? 'Member'} • ${m['meal_date']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      '${_hasBreakfast ? 'B: ${m['breakfast']}  |  ' : ''}L: ${m['lunch']}  |  D: ${m['dinner']}${((m['guest_meals'] as num) > 0) ? '  |  Guest: ${m['guest_meals']}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: Text('${total.toStringAsFixed(1)} meals', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Center(child: Text(text, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600))),
      ],
    );
  }

  // ==================== TAB 2: TO-LET FINDER ====================
  Widget _buildToLetTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _areaSearchCtrl,
            decoration: InputDecoration(
              hintText: S.t('search_area_hint'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                onPressed: () => _searchListings(),
              ),
            ),
            onSubmitted: (_) => _searchListings(),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _quickAreas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final area = _quickAreas[i];
              final selected = _selectedAreaChip == area;
              return ChoiceChip(
                label: Text(area, style: const TextStyle(fontSize: 12.5)),
                selected: selected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                onSelected: (_) {
                  setState(() {
                    _selectedAreaChip = area;
                    _areaSearchCtrl.text = area == 'All' ? '' : area;
                  });
                  _searchListings(area);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (_banners.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Builder(builder: (_) {
              final banner = _banners.first as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${banner['badge_text'] ?? 'SPONSORED'} • ${banner['sponsor_name'] ?? ''}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            banner['headline']?.toString() ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          if (banner['subtitle'] != null && banner['subtitle'].toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              banner['subtitle'].toString(),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: banner['cta_value'].toString()));
                        _showSnack('${banner['sponsor_name']} contact copied: ${banner['cta_value']}');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(banner['cta_label']?.toString() ?? 'Call', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              );
            }),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _searchListings(),
            child: _listings.isEmpty
                ? _emptyState(Icons.bed_outlined, 'No bachelor seats found for this area')
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 88),
                    itemCount: _listings.length,
                    itemBuilder: (_, i) {
                      final item = _listings[i] as Map<String, dynamic>;
                      final facilities = (item['facilities'] as List?) ?? [];
                      final photoUrls = (item['photo_urls'] as List?) ?? [];
                      final isVerified = item['mess_id'] != null;
                      final isFeatured = item['is_featured'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isFeatured ? AppColors.amber.withValues(alpha: 0.45) : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (photoUrls.isNotEmpty)
                              SizedBox(
                                height: 165,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photoUrls.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                                  itemBuilder: (_, pIdx) {
                                    final raw = photoUrls[pIdx].toString();
                                    return GestureDetector(
                                      onTap: () => _openPhotoViewer(raw, item['title'] as String),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.network(
                                          ApiConfig.resolveMediaUrl(raw),
                                          width: photoUrls.length == 1 ? 300 : 220,
                                          height: 155,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 220,
                                            color: AppColors.surface,
                                            child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(
                                children: [
                                  if (isFeatured)
                                    _badge('FEATURED', AppColors.amberBg, AppColors.amber),
                                  if (isVerified) ...[
                                    if (isFeatured) const SizedBox(width: 6),
                                    _badge('VERIFIED MESS', AppColors.primaryLight, AppColors.primary),
                                  ],
                                  const Spacer(),
                                  Text(
                                    '৳${(item['monthly_rent'] as num).toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                  const Text('/mo', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['title'] as String,
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.3),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 15, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${item['area']}, ${item['city']} • From ${item['available_from']}',
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                                    ),
                                  ),
                                ],
                              ),
                              if (item['avg_meal_cost'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Avg Meal Cost: ~৳${(item['avg_meal_cost'] as num).toStringAsFixed(0)}/month',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                                ),
                              ],
                              if (facilities.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: facilities
                                      .map((f) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Text(f.toString(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                          ))
                                      .toList(),
                                ),
                              ],
                              const Divider(height: 22, color: AppColors.border),
                              Row(
                                children: [
                                  const Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    item['contact_phone'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  if (!isFeatured && item['posted_by'] == _user?['id']) ...[
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        if (await AppSheets.showBoostSeat(
                                          context,
                                          listingId: item['id'] as int,
                                          listingTitle: item['title'] as String,
                                          defaultPhone: _user?['phone']?.toString() ?? '',
                                        )) {
                                          _showSnack('৳99 Boost request submitted for admin approval!');
                                        }
                                      },
                                      icon: const Icon(Icons.rocket_launch_outlined, size: 14, color: AppColors.amber),
                                      label: const Text('Boost ৳99', style: TextStyle(fontSize: 12, color: AppColors.amber)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppColors.amber.withValues(alpha: 0.5)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: item['contact_phone'].toString()));
                                      _showSnack('Phone number copied!');
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 15),
                                    label: const Text('Copy'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }

  // ==================== TAB 3: PROFILE ====================
  Widget _buildProfileTab() {
    final inviteCode = _summary?['mess']?['invite_code'];
    final members = (_summary?['members'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Text(
                  (_user?['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_user?['name'] ?? 'User', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(_user?['phone'] ?? _user?['email'] ?? '', style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              if (_isManager) _badge('MANAGER', AppColors.amberBg, AppColors.amber),
            ],
          ),
        ),

        if (inviteCode != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.t('invite_code_title'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(
                        inviteCode.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(S.t('invite_code_desc'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode.toString()));
                    _showSnack('Invite code copied!');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(S.t('copy')),
                ),
              ],
            ),
          ),
        ],

        if (_isManager && _activeMessId != null) ...[
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.wb_twilight_rounded, color: AppColors.primary),
              title: Text(S.t('include_breakfast'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(S.t('include_breakfast_desc')),
              value: _hasBreakfast,
              onChanged: (val) async {
                try {
                  await ApiService.patch('/messes/$_activeMessId/settings', {'has_breakfast': val});
                  await _loadMessData(_activeMessId!);
                  _showSnack(val ? 'Breakfast enabled (3-Meal Mode)' : 'Switched to Lunch + Dinner only');
                } catch (e) {
                  _showSnack(e.toString(), isError: true);
                }
              },
            ),
          ),
        ],

        if (_isManager && _activeMessId != null && members.length > 1) ...[
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
              title: Text(S.t('handover_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(S.t('handover_desc')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                if (await AppSheets.showHandoverManager(context, _activeMessId!, members, _user!['id'] as int)) {
                  await _loadMessData(_activeMessId!);
                  _showSnack('Manager role transferred!');
                }
              },
            ),
          ),
        ],

        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: const Icon(Icons.translate_rounded, color: AppColors.primary),
            title: Text(S.t('language_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(S.t('language_desc')),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'bn', label: Text('বাংলা')),
              ],
              selected: {AppLocale.current.value},
              onSelectionChanged: (s) async {
                await AppLocale.setLocale(s.first);
                try {
                  await ApiService.patch('/auth/profile', {'locale': s.first});
                } catch (_) {}
              },
            ),
          ),
        ),

        if (_messes.length > 1) ...[
          const SizedBox(height: 14),
          const Text('Switch Active Mess', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: _messes.map((m) {
                final id = m['id'] as int;
                final selected = id == _activeMessId;
                return ListTile(
                  leading: Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? AppColors.primary : Colors.grey,
                  ),
                  title: Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(m['area'] as String),
                  onTap: () {
                    setState(() => _activeMessId = id);
                    _loadMessData(id);
                  },
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await ApiService.post('/auth/logout', {});
            } catch (_) {}
            await ApiService.clearToken();
            widget.onLogout();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: Text(S.t('sign_out')),
        ),
      ],
      ),
    );
  }
}
