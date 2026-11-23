import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AppSheets {
  static Widget _sheetShell(BuildContext context, {required String title, String? subtitle, required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool> showCreateOrJoinMess(BuildContext context) async {
    bool isCreate = true;
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Chawk Bazar');
    final rentCtrl = TextEditingController(text: '3500');
    final codeCtrl = TextEditingController();
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: isCreate ? 'Create New Mess' : 'Join Existing Mess',
          subtitle: isCreate
              ? 'Start tracking meals, bazar & bills with your roommates.'
              : 'Ask your mess manager for the 6-character invite code.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Create Mess')),
                  ButtonSegment(value: false, label: Text('Join via Code')),
                ],
                selected: {isCreate},
                onSelectionChanged: (s) => setS(() => isCreate = s.first),
              ),
              const SizedBox(height: 16),
              if (isCreate) ...[
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Mess Name (e.g. Chawk Bazar Mess)')),
                const SizedBox(height: 12),
                TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Area (e.g. Chawk Bazar, GEC, Agrabad)')),
                const SizedBox(height: 12),
                TextField(
                  controller: rentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Your Monthly Seat Rent (৳)', prefixText: '৳ '),
                ),
              ] else ...[
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Invite Code (e.g. CTG100)'),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          if (isCreate) {
                            await ApiService.post('/messes', {
                              'name': nameCtrl.text.trim(),
                              'area': areaCtrl.text.trim(),
                              'monthly_seat_rent': double.tryParse(rentCtrl.text.trim()) ?? 0,
                            });
                          } else {
                            await ApiService.post('/messes/join', {
                              'invite_code': codeCtrl.text.trim(),
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Please wait...' : (isCreate ? 'Create Mess' : 'Join Mess')),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  static Future<bool> showLogMeal(BuildContext context, int messId, {bool hasBreakfast = false}) async {
    double breakfast = hasBreakfast ? 0.5 : 0;
    double lunch = 1, dinner = 1, guest = 0;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool saving = false;

    Widget row(String label, IconData icon, double val, ValueChanged<double> onSet) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            IconButton.filledTonal(
              onPressed: val > 0 ? () => onSet((val - 0.5).clamp(0, 10)) : null,
              icon: const Icon(Icons.remove, size: 18),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
            ),
            SizedBox(
              width: 44,
              child: Text(
                val.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => onSet((val + 0.5).clamp(0, 10)),
              icon: const Icon(Icons.add, size: 18),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: 'Log Today\'s Meals',
          subtitle: '${DateFormat('EEEE, d MMM yyyy').format(DateTime.now())} • ${hasBreakfast ? '3-Meal Mode' : 'Lunch + Dinner Mode'}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasBreakfast)
                row('Breakfast', Icons.wb_twilight_rounded, breakfast, (v) => setS(() => breakfast = v)),
              row('Lunch (দুপুর)', Icons.wb_sunny_outlined, lunch, (v) => setS(() => lunch = v)),
              row('Dinner (রাত)', Icons.nights_stay_outlined, dinner, (v) => setS(() => dinner = v)),
              row('Guest Meals', Icons.person_add_alt_1_outlined, guest, (v) => setS(() => guest = v)),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          await ApiService.post('/messes/$messId/meals', {
                            'meal_date': today,
                            'breakfast': hasBreakfast ? breakfast : 0,
                            'lunch': lunch,
                            'dinner': dinner,
                            'guest_meals': guest,
                          });
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save ${((hasBreakfast ? breakfast : 0) + lunch + dinner + guest).toStringAsFixed(1)} Meals'),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  static Future<bool> showBulkMeals(
    BuildContext context,
    int messId,
    List<dynamic> members, {
    bool hasBreakfast = false,
  }) async {
    if (members.isEmpty) return false;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<int, Map<String, double>> state = {
      for (final m in members)
        m['user_id'] as int: {
          'breakfast': hasBreakfast ? 0.5 : 0.0,
          'lunch': 1.0,
          'dinner': 1.0,
        },
    };
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: 'Manage Today\'s Meals (All)',
          subtitle: 'Tap to toggle each roommate\'s meal for $today.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...members.map((m) {
                final uid = m['user_id'] as int;
                final s = state[uid]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasBreakfast) ...[
                        FilterChip(
                          label: const Text('B', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          selected: s['breakfast']! > 0,
                          visualDensity: VisualDensity.compact,
                          onSelected: (v) => setS(() => s['breakfast'] = v ? 0.5 : 0.0),
                        ),
                        const SizedBox(width: 6),
                      ],
                      FilterChip(
                        label: const Text('Lunch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        selected: s['lunch']! > 0,
                        visualDensity: VisualDensity.compact,
                        onSelected: (v) => setS(() => s['lunch'] = v ? 1.0 : 0.0),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Dinner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        selected: s['dinner']! > 0,
                        visualDensity: VisualDensity.compact,
                        onSelected: (v) => setS(() => s['dinner'] = v ? 1.0 : 0.0),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          await ApiService.post('/messes/$messId/meals/bulk', {
                            'meal_date': today,
                            'entries': state.entries
                                .map((e) => {
                                      'user_id': e.key,
                                      'breakfast': hasBreakfast ? e.value['breakfast'] : 0,
                                      'lunch': e.value['lunch'],
                                      'dinner': e.value['dinner'],
                                      'guest_meals': 0,
                                    })
                                .toList(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Saving All...' : 'Save All Roommates (${members.length})'),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  static Future<bool> showAddBazar(BuildContext context, int messId) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final picker = ImagePicker();
    XFile? receiptFile;
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: 'Add Bazar Expense',
          subtitle: 'Record daily grocery spend and optionally attach a bazar slip photo.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Spent (BDT)', prefixText: '৳ '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Items Bought',
                  hintText: 'e.g. Khatunganj rice 10kg, Chicken 3kg, Eggs, Vegetables',
                ),
              ),
              const SizedBox(height: 12),
              if (receiptFile != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(receiptFile!.path, height: 130, width: double.infinity, fit: BoxFit.cover)
                          : Image.file(File(receiptFile!.path), height: 130, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setS(() => receiptFile = null),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                          if (picked != null) setS(() => receiptFile = picked);
                        },
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery Slip'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                          if (picked != null) setS(() => receiptFile = picked);
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Camera Slip'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          if (receiptFile != null) {
                            final bytes = await receiptFile!.readAsBytes();
                            await ApiService.postMultipart(
                              '/messes/$messId/bazars',
                              fields: {
                                'bazar_date': today,
                                'amount': (double.tryParse(amountCtrl.text.trim()) ?? 0).toString(),
                                'items_note': noteCtrl.text.trim(),
                              },
                              files: [
                                http.MultipartFile.fromBytes('receipt', bytes, filename: receiptFile!.name),
                              ],
                            );
                          } else {
                            await ApiService.post('/messes/$messId/bazars', {
                              'bazar_date': today,
                              'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                              'items_note': noteCtrl.text.trim(),
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save Bazar Entry'),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  static Future<bool> showAddDeposit(BuildContext context, int messId, List<dynamic> members) async {
    if (members.isEmpty) return false;
    int selectedUserId = members.first['user_id'] as int;
    String method = 'bkash';
    String type = 'meal';
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: 'Record Member Deposit',
          subtitle: 'Log cash, bKash, or Nagad money received from a roommate.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedUserId,
                decoration: const InputDecoration(labelText: 'Member'),
                items: members
                    .map((m) => DropdownMenuItem<int>(
                          value: m['user_id'] as int,
                          child: Text(m['name'] as String),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setS(() => selectedUserId = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (BDT)', prefixText: '৳ '),
              ),
              const SizedBox(height: 12),
              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['bkash', 'nagad', 'cash', 'bank']
                    .map((m) => ChoiceChip(
                          label: Text(m.toUpperCase()),
                          selected: method == m,
                          onSelected: (_) => setS(() => method = m),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              const Text('Deposit For', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('Meal Fund'), selected: type == 'meal', onSelected: (_) => setS(() => type = 'meal')),
                  ChoiceChip(label: const Text('Fixed Bills / Rent'), selected: type == 'fixed_bill', onSelected: (_) => setS(() => type = 'fixed_bill')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'TrxID / Note (Optional)'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          await ApiService.post('/messes/$messId/deposits', {
                            'user_id': selectedUserId,
                            'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                            'deposit_type': type,
                            'payment_method': method,
                            'reference': refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                            'deposit_date': today,
                          });
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save Deposit'),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  static Future<bool> showAddFixedBill(BuildContext context, int messId) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'wifi';
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: 'Add Fixed Monthly Bill',
          subtitle: 'Automatically split equally among all active mess members.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: ['wifi', 'bua', 'electricity', 'gas', 'water', 'rent', 'other']
                    .map((c) => ChoiceChip(
                          label: Text(c[0].toUpperCase() + c.substring(1)),
                          selected: category == c,
                          onSelected: (_) => setS(() => category = c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Bill Title (e.g. Broadband Wi-Fi)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Amount (BDT)', prefixText: '৳ '),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          await ApiService.post('/messes/$messId/fixed-bills', {
                            'title': titleCtrl.text.trim(),
                            'category': category,
                            'total_amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                          });
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Add Fixed Bill'),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  static Future<bool> showPostSeat(
    BuildContext context, {
    int? messId,
    String defaultArea = 'Chawk Bazar',
    String defaultPhone = '',
  }) async {
    final titleCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: defaultArea);
    final rentCtrl = TextEditingController(text: '3500');
    final mealCtrl = TextEditingController(text: '2800');
    final phoneCtrl = TextEditingController(text: defaultPhone);
    final descCtrl = TextEditingController();
    String seatType = 'shared_seat';
    final allFacilities = ['Wi-Fi', 'Bua', 'Fridge', 'Lift', 'Generator', 'Filter Water', 'Attached Bath'];
    final selectedFacilities = <String>{'Wi-Fi', 'Bua', 'Filter Water'};
    final picker = ImagePicker();
    final List<XFile> pickedPhotos = [];
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: 'Post Vacant Bachelor Seat',
          subtitle: messId != null ? 'Will display a Verified Mess badge automatically.' : 'Reach thousands of Chattogram bachelors.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Headline (e.g. 1 Seat near Metro)')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Area'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: seatType,
                      decoration: const InputDecoration(labelText: 'Seat Type'),
                      items: const [
                        DropdownMenuItem(value: 'shared_seat', child: Text('Shared Seat')),
                        DropdownMenuItem(value: 'single_room', child: Text('Single Room')),
                        DropdownMenuItem(value: 'sublet', child: Text('Sublet')),
                      ],
                      onChanged: (v) => setS(() => seatType = v ?? 'shared_seat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: rentCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Seat Rent (৳)', prefixText: '৳ '),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: mealCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Avg Meal (৳)', prefixText: '৳ '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
              ),
              const SizedBox(height: 10),
              const Text('Facilities', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: allFacilities.map((f) {
                  final on = selectedFacilities.contains(f);
                  return FilterChip(
                    label: Text(f, style: const TextStyle(fontSize: 12)),
                    selected: on,
                    onSelected: (v) => setS(() => v ? selectedFacilities.add(f) : selectedFacilities.remove(f)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Short Description')),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Room Photos (${pickedPhotos.length}/3)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  TextButton.icon(
                    onPressed: pickedPhotos.length >= 3
                        ? null
                        : () async {
                            final imgs = await picker.pickMultiImage(imageQuality: 75);
                            if (imgs.isNotEmpty) {
                              setS(() {
                                for (final img in imgs) {
                                  if (pickedPhotos.length < 3) pickedPhotos.add(img);
                                }
                              });
                            }
                          },
                    icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                    label: const Text('Add Photos'),
                  ),
                ],
              ),
              if (pickedPhotos.isNotEmpty)
                SizedBox(
                  height: 82,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pickedPhotos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) {
                      final f = pickedPhotos[idx];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.network(f.path, width: 92, height: 82, fit: BoxFit.cover)
                                : Image.file(File(f.path), width: 92, height: 82, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setS(() => pickedPhotos.removeAt(idx)),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          final availDate = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7)));
                          if (pickedPhotos.isNotEmpty) {
                            final files = <http.MultipartFile>[];
                            for (var i = 0; i < pickedPhotos.length; i++) {
                              final bytes = await pickedPhotos[i].readAsBytes();
                              files.add(http.MultipartFile.fromBytes('photos[$i]', bytes, filename: pickedPhotos[i].name));
                            }
                            final fields = <String, String>{
                              'title': titleCtrl.text.trim(),
                              'area': areaCtrl.text.trim(),
                              'seat_type': seatType,
                              'monthly_rent': (double.tryParse(rentCtrl.text.trim()) ?? 3000).toString(),
                              'available_from': availDate,
                              'contact_phone': phoneCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                            };
                            if (messId != null) fields['mess_id'] = messId.toString();
                            final avgMeal = double.tryParse(mealCtrl.text.trim());
                            if (avgMeal != null) fields['avg_meal_cost'] = avgMeal.toString();

                            await ApiService.postMultipart(
                              '/seat-listings',
                              fields: fields,
                              arrayFields: {'facilities': selectedFacilities.toList()},
                              files: files,
                            );
                          } else {
                            await ApiService.post('/seat-listings', {
                              'mess_id': messId,
                              'title': titleCtrl.text.trim(),
                              'area': areaCtrl.text.trim(),
                              'seat_type': seatType,
                              'monthly_rent': double.tryParse(rentCtrl.text.trim()) ?? 3000,
                              'avg_meal_cost': double.tryParse(mealCtrl.text.trim()),
                              'available_from': availDate,
                              'contact_phone': phoneCtrl.text.trim(),
                              'facilities': selectedFacilities.toList(),
                              'description': descCtrl.text.trim(),
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Publishing...' : 'Publish Seat Listing'),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  static Future<bool> showHandoverManager(BuildContext context, int messId, List<dynamic> members, int currentUserId) async {
    final candidates = members.where((m) => m['user_id'] != currentUserId).toList();
    if (candidates.isEmpty) return false;
    int selectedId = candidates.first['user_id'] as int;
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: 'Handover Manager Role',
          subtitle: 'Transfer admin control to next month\'s mess manager without losing any records.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...candidates.map((m) {
                final uid = m['user_id'] as int;
                final selected = uid == selectedId;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: selected ? AppColors.primaryLight : null,
                  leading: CircleAvatar(
                    backgroundColor: selected ? AppColors.primary : Colors.grey.shade200,
                    foregroundColor: selected ? Colors.white : AppColors.ink,
                    child: Text((m['name'] as String).substring(0, 1).toUpperCase()),
                  ),
                  title: Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(m['phone']?.toString() ?? ''),
                  trailing: Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: selected ? AppColors.primary : Colors.grey,
                  ),
                  onTap: () => setS(() => selectedId = uid),
                );
              }),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          await ApiService.post('/messes/$messId/handover', {
                            'new_manager_user_id': selectedId,
                          });
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Transferring...' : 'Confirm Manager Handover'),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  static Future<bool> showBoostSeat(
    BuildContext context, {
    required int listingId,
    required String listingTitle,
    String defaultPhone = '',
  }) async {
    String method = 'bkash';
    final phoneCtrl = TextEditingController(text: defaultPhone);
    final trxCtrl = TextEditingController();
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _sheetShell(
          ctx,
          title: 'Boost Seat for 7 Days (৳99)',
          subtitle: listingTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amberBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to Pay ৳99', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.amber)),
                    SizedBox(height: 4),
                    Text(
                      'Send Money ৳99 to bKash/Nagad Personal: 01800-000000, then enter your TrxID below. Our CTG team approves within 15 minutes.',
                      style: TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: ['bkash', 'nagad']
                    .map((m) => ChoiceChip(
                          label: Text(m.toUpperCase()),
                          selected: method == m,
                          onSelected: (_) => setS(() => method = m),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Your Sender Phone Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trxCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Transaction ID (TrxID)', hintText: 'e.g. BK99CTG842'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        try {
                          await ApiService.post('/seat-listings/$listingId/boost', {
                            'payment_method': method,
                            'sender_phone': phoneCtrl.text.trim(),
                            'trx_id': trxCtrl.text.trim(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setS(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Submitting...' : 'Submit ৳99 Boost Request'),
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }
}
