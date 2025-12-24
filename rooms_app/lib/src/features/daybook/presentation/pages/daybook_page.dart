import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';
import 'package:rooms/src/features/daybook/presentation/providers/daybook_providers.dart';

class DayBookPage extends ConsumerStatefulWidget {
  const DayBookPage({super.key});

  @override
  ConsumerState<DayBookPage> createState() => _DayBookPageState();
}

class _DayBookPageState extends ConsumerState<DayBookPage> {
  // Track selected transaction IDs for multi-select
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  void _toggleSelection(String transactionId) {
    setState(() {
      if (_selectedIds.contains(transactionId)) {
        _selectedIds.remove(transactionId);
      } else {
        _selectedIds.add(transactionId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelectedTransactions(
    List<Transaction> allTransactions,
  ) async {
    final selectedTransactions = allTransactions
        .where((t) => _selectedIds.contains(t.id))
        .toList();

    if (selectedTransactions.isEmpty) return;

    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Transactions',
      message:
          'Are you sure you want to delete ${selectedTransactions.length} transaction${selectedTransactions.length > 1 ? 's' : ''}?\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final repo = ref.read(dayBookRepositoryProvider);

      for (final transaction in selectedTransactions) {
        await repo.deleteTransaction(transaction);
      }

      ref.invalidate(todayDayBookProvider);
      _clearSelection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedTransactions.length} transaction${selectedTransactions.length > 1 ? 's' : ''} deleted',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelId = ref.watch(selectedHotelIdProvider);
    final summaryAsync = ref.watch(todayDayBookProvider);
    final currentHotel = ref.watch(currentHotelProvider);
    final isOwner = currentHotel?.isOwner ?? false;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectedIds.isNotEmpty) {
              _clearSelection();
            } else {
              context.pop();
            }
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book, size: 24),
            SizedBox(width: 8),
            Text('Day Book'),
          ],
        ),
      ),
      body: hotelId == null
          ? const Center(child: Text('No hotel selected'))
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(todayDayBookProvider);
              },
              child: summaryAsync.when(
                data: (summary) => _buildContent(context, summary, isOwner),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildErrorView(context, e),
              ),
            ),
      floatingActionButton: hotelId != null && _selectedIds.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTransaction(context),
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            )
          : null,
    );
  }

  Widget _buildErrorView(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load daybook',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(todayDayBookProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DayBookSummary summary,
    bool isOwner,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(summary, isOwner),
        const SizedBox(height: 24),
        _buildTransactionsList(context, summary.transactions, isOwner),
      ],
    );
  }

  Widget _buildSummaryCard(DayBookSummary summary, bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.black),
              const SizedBox(width: 8),
              Text(
                'Today - ${_formatDate(summary.date)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isOwner
                      ? () => _showEditOpeningBalance(summary)
                      : null,
                  child: _buildBalanceItem(
                    'Opening',
                    summary.openingBalance,
                    AppColors.grey600,
                    isEditable: isOwner,
                  ),
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.grey300),
              Expanded(
                child: _buildBalanceItem(
                  'Closing',
                  summary.closingBalance,
                  AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAmountCard(
                  icon: Icons.arrow_downward,
                  label: 'Income',
                  amount: summary.totalIncome,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAmountCard(
                  icon: Icons.arrow_upward,
                  label: 'Expense',
                  amount: summary.totalExpense,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    String label,
    double amount,
    Color color, {
    bool isEditable = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (isEditable) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 12, color: AppColors.textSecondary),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: color)),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    List<Transaction> transactions,
    bool isOwner,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.receipt_long, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            const Text(
              'No transactions today',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and delete button
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedIds.isEmpty
                    ? 'Transactions'
                    : '${_selectedIds.length} selected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Show delete button when items are selected (only for owners)
            if (_selectedIds.isNotEmpty && isOwner)
              _isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.grey600),
                          onPressed: _clearSelection,
                          tooltip: 'Clear selection',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.delete, color: AppColors.error),
                          onPressed: () =>
                              _deleteSelectedTransactions(transactions),
                          tooltip: 'Delete selected',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
          ],
        ),
        const SizedBox(height: 12),
        ...transactions.map((t) => _buildTransactionCard(t, isOwner)),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction, bool isOwner) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final isSelected = _selectedIds.contains(transaction.id);
    final isInSelectionMode = _selectedIds.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: isSelected ? 2 : 1),
      ),
      child: Row(
        children: [
          // Selectable icon (only for owners)
          GestureDetector(
            onTap: isOwner ? () => _toggleSelection(transaction.id) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected
                    ? Icons.check
                    : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Transaction details - tappable to select in selection mode
          Expanded(
            child: GestureDetector(
              onTap: isInSelectionMode && isOwner
                  ? () => _toggleSelection(transaction.id)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.category.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTransactionDialog(ref: ref),
    );
  }

  void _showEditOpeningBalance(DayBookSummary summary) {
    final controller = TextEditingController(
      text: summary.openingBalance.toStringAsFixed(0),
    );

    CustomDialog.show(
      context: context,
      title: 'Edit Opening Balance',
      icon: Icons.account_balance_wallet,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current: ₹${summary.openingBalance.toStringAsFixed(0)}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'New Opening Balance',
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The closing balance will be adjusted accordingly.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
      primaryButtonText: 'Update',
      onPrimaryPressed: () async {
        final newBalance = double.tryParse(controller.text);
        if (newBalance == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a valid number'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        Navigator.pop(context);
        await _updateOpeningBalance(summary.id!, newBalance);
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _updateOpeningBalance(
    String daybookId,
    double newBalance,
  ) async {
    try {
      final repo = ref.read(dayBookRepositoryProvider);
      await repo.updateOpeningBalance(daybookId, newBalance);

      ref.invalidate(todayDayBookProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opening balance updated to ₹${newBalance.toStringAsFixed(0)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _AddTransactionDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _AddTransactionDialog({required this.ref});

  @override
  ConsumerState<_AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<_AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  TransactionCategory _selectedCategory = TransactionCategory.other;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hotelId = widget.ref.read(selectedHotelIdProvider);
      final daybookId = widget.ref.read(currentDaybookIdProvider);
      final userId = SupabaseService.instance.currentUserId;

      if (hotelId == null || daybookId == null) {
        throw Exception('No hotel or daybook selected');
      }

      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();

      final transaction = Transaction(
        id: '',
        hotelId: hotelId,
        daybookId: daybookId,
        type: _selectedType,
        category: _selectedCategory,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
        createdBy: userId ?? '',
      );

      final repo = widget.ref.read(dayBookRepositoryProvider);
      await repo.addTransaction(transaction);

      widget.ref.invalidate(todayDayBookProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedType.displayName} of ₹${amount.toStringAsFixed(0)} added',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Type',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            type: TransactionType.income,
                            icon: Icons.arrow_downward,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeButton(
                            type: TransactionType.expense,
                            icon: Icons.arrow_upward,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TransactionCategory>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: TransactionCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Amount',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null) {
                          return 'Please enter a valid number';
                        }
                        if (amount <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter description...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Add Transaction',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required TransactionType type,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.grey600, size: 20),
            const SizedBox(width: 8),
            Text(
              type.displayName,
              style: TextStyle(
                color: isSelected ? color : AppColors.grey600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
