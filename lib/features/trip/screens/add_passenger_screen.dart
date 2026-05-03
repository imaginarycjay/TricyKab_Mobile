import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/mock_data.dart';
import '../../driver_flow/driver_flow_scope.dart';

/// Add street passenger — parity with `mockups/driver/06-add-passenger.html`.
class AddPassengerScreen extends StatefulWidget {
  const AddPassengerScreen({super.key});

  @override
  State<AddPassengerScreen> createState() => _AddPassengerScreenState();
}

class _AddPassengerScreenState extends State<AddPassengerScreen> {
  int _quantity = 1;
  final TextEditingController _destinationController = TextEditingController(text: 'USM Main Gate');
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = DriverFlowScope.of(context);
    final int currentCount = flow.onboardPassengers.length;
    final int maxCapacity = flow.capacity;
    final int availableSlots = maxCapacity - currentCount;
    final int afterBoard = (currentCount + _quantity).clamp(0, maxCapacity);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 12,
              bottom: 16,
            ),
            color: AppColors.success,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHARED RIDE',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add Street Passenger',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.subtleBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Board a walk-up passenger during a shared ride. Capacity is tracked automatically.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          'Current Capacity',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: (currentCount / maxCapacity).clamp(0.0, 1.0),
                            backgroundColor: AppColors.subtleBackground,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              currentCount >= maxCapacity ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$currentCount of $maxCapacity seats occupied',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            Text(
                              '$availableSlots available',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                MockAddPassenger.sampleOnboard.initials ?? 'MC',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    MockAddPassenger.sampleOnboard.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    MockAddPassenger.sampleOnboard.routeSubtitle ?? '',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          'New Passenger',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Number of Passengers',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StepperButton(
                              icon: Icons.remove,
                              emphasized: false,
                              onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            _StepperButton(
                              icon: Icons.add,
                              emphasized: true,
                              onTap: _quantity < availableSlots && _quantity < 3
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Destination (optional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _destinationController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.place_outlined, color: AppColors.primary),
                            hintText: 'Where are they going?',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Notes (optional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., student, elderly, with child',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'After boarding:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                            Text(
                              '$afterBoard / $maxCapacity seats',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: (afterBoard / maxCapacity).clamp(0.0, 1.0),
                            backgroundColor: AppColors.subtleBackground,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final String dest = _destinationController.text.trim();
                        flow.destinationWalkIn = dest.isEmpty ? null : dest;
                        await flow.addPassengers(_quantity);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Confirm & Board'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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
  const _StepperButton({
    required this.icon,
    required this.emphasized,
    this.onTap,
  });

  final IconData icon;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: emphasized ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          color: emphasized ? AppColors.primary10 : AppColors.cardBackground,
        ),
        child: Icon(
          icon,
          color: disabled ? AppColors.textMuted : (emphasized ? AppColors.primary : AppColors.textPrimary),
          size: 22,
        ),
      ),
    );
  }
}
