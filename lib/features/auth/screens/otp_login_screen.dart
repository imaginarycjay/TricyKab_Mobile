import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../driver_flow/driver_flow_controller.dart';
import '../../driver_flow/driver_flow_scope.dart';
import '../../../navigation/app_router.dart';

/// Driver login — Step 1 matches `01-otp-login.html`; Step 2 is PRD OTP verification (deviation documented in audit).
class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _showOtpStep = false;

  @override
  void dispose() {
    for (final TextEditingController c in _otpControllers) {
      c.dispose();
    }
    for (final FocusNode f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final DriverFlowController flow = DriverFlowScope.of(context);
    await flow.requestOtp();
    if (flow.otpSent) {
      const String mockOtp = '123456';
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = mockOtp[i];
      }
      setState(() {});
    }
  }

  Future<void> _verifyOtp() async {
    final DriverFlowController flow = DriverFlowScope.of(context);
    final String otpCode = _otpControllers.map((TextEditingController c) => c.text).join();
    final bool verified = await flow.verifyOtp(otpCode);
    if (verified && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DriverFlowController flow = DriverFlowScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.electric_rickshaw,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'TricyKab',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Driver Portal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only approved & verified TODA drivers can sign in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.35),
                ),
                const SizedBox(height: 32),

                if (!_showOtpStep) ...[
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
                          'Sign in with your registered number',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Registered Mobile',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: flow.phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 14, right: 8),
                              child: Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                            ),
                            prefixIconConstraints: BoxConstraints(minWidth: 48),
                            hintText: '+63 918 222 3333',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _showOtpStep = true),
                            icon: const Icon(Icons.verified_user_outlined, size: 18),
                            label: const Text('Sign In as Driver'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Not registered? Contact your TODA President.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ] else ...[
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
                        TextButton.icon(
                          onPressed: () => setState(() => _showOtpStep = false),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                          label: const Text('Back'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the OTP sent to your phone',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        if (!flow.otpSent) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: flow.isLoading ? null : _sendOtp,
                              child: flow.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Send OTP'),
                            ),
                          ),
                        ],
                        if (flow.otpSent) ...[
                          const Text(
                            'VERIFICATION CODE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(6, (int i) {
                              return SizedBox(
                                width: 44,
                                height: 52,
                                child: TextField(
                                  controller: _otpControllers[i],
                                  focusNode: _otpFocusNodes[i],
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    fillColor: _otpControllers[i].text.isNotEmpty
                                        ? AppColors.primary10
                                        : AppColors.cardBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _otpControllers[i].text.isNotEmpty
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _otpControllers[i].text.isNotEmpty
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (String val) {
                                    if (val.isNotEmpty && i < 5) {
                                      _otpFocusNodes[i + 1].requestFocus();
                                    }
                                    setState(() {});
                                  },
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: flow.resendSeconds == 0 ? _sendOtp : null,
                              child: Text(
                                flow.resendSeconds == 0
                                    ? 'Resend Code'
                                    : 'Resend Code (${flow.resendSeconds}s)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: flow.resendSeconds == 0 ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          if (flow.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              flow.errorMessage!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: flow.isLoading ? null : _verifyOtp,
                              child: flow.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Verify & Sign In'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Only approved TODA drivers can sign in.\nContact your TODA admin for registration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
