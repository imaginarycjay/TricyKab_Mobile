import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/info_row.dart';
import '../../../data/mock_data.dart';

/// Add passenger screen for shared rides.
/// PRD Section 16.4: Add Passenger flow, Section 13.4: capacity validation.
class AddPassengerScreen extends StatefulWidget {
  const AddPassengerScreen({super.key});

  @override
  State<AddPassengerScreen> createState() => _AddPassengerScreenState();
}

class _AddPassengerScreenState extends State<AddPassengerScreen> {
  int _quantity = 1;
  final _notesController = TextEditingController();
  final int _currentCount = MockTrip.passengerCount;
  final int _maxCapacity = MockDriver.capacity;

  int get _availableSlots => _maxCapacity - _currentCount;
  double get _fillPercent => (_currentCount + _quantity) / _maxCapacity;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Walk-in Passenger',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Record additional passengers for this shared ride',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Capacity card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        InfoRow(
                          label: 'Current Passengers',
                          value: '$_currentCount',
                        ),
                        InfoRow(
                          label: 'Max Capacity',
                          value: '$_maxCapacity',
                        ),
                        InfoRow(
                          label: 'Available Slots',
                          value: '$_availableSlots',
                          valueColor: _availableSlots <= 1 ? AppColors.warning : AppColors.success,
                          showBorder: false,
                        ),
                        const SizedBox(height: 12),
                        // Capacity bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: _fillPercent.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.subtleBackground,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _fillPercent >= 1.0
                                  ? AppColors.danger
                                  : _fillPercent >= 0.75
                                      ? AppColors.warning
                                      : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((_currentCount + _quantity)).clamp(0, _maxCapacity)} / $_maxCapacity passengers after adding',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quantity stepper
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUANTITY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StepperButton(
                              icon: Icons.remove,
                              onTap: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _StepperButton(
                              icon: Icons.add,
                              onTap: _quantity < _availableSlots
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'NOTES (OPTIONAL)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Walk-in passenger near market',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Show success feedback then pop
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$_quantity passenger(s) added successfully'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                      label: Text('Confirm Add $_quantity Passenger${_quantity > 1 ? 's' : ''}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.subtleBackground : AppColors.primary10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? AppColors.border : AppColors.primary20,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isDisabled ? AppColors.textMuted : AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}
