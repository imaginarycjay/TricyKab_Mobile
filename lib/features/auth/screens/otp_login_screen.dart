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
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  String get _otpJoined => _otpControllers.map((TextEditingController c) => c.text).join();

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
    if (mounted) {
      setState(() {
        for (final c in _otpControllers) {
          c.clear();
        }
      });
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _otpFocusNodes.first.requestFocus();
      });
    }
  }

  Future<void> _verifyOtp() async {
    final DriverFlowController flow = DriverFlowScope.of(context);
    final String otpCode = _otpJoined;
    if (otpCode.length < 6) {
      flow.setErrorMessage('Enter the full 6-digit code.');
      return;
    }
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const _BrandHero(),
                  const SizedBox(height: 6),
                  const Text(
                    'Driver Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                  if (!flow.otpSent) _phoneCard(flow) else _otpCard(flow),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Not registered? Contact your TODA President.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneCard(DriverFlowController flow) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign in with your registered number',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'REGISTERED MOBILE',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: flow.phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone, color: AppColors.primary, size: 20),
              hintText: '+63 917 110 0000',
            ),
          ),
          if (flow.errorMessage != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: flow.errorMessage!),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: flow.isLoading ? null : _sendOtp,
            icon: const Icon(Icons.send, size: 18),
            label: Text(flow.isLoading ? 'Sending...' : 'Send OTP'),
          ),
        ],
      ),
    );
  }

  Widget _otpCard(DriverFlowController flow) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter verification code',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sent to ${flow.phoneController.text.trim()}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 44,
                child: _OtpBox(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  onChanged: (v) {
                    if (v.length == 1 && i < 5) _otpFocusNodes[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _otpFocusNodes[i - 1].requestFocus();
                    if (_otpJoined.length == 6) _verifyOtp();
                    setState(() {});
                  },
                ),
              );
            }),
          ),
          if (flow.errorMessage != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: flow.errorMessage!),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: flow.isLoading ? null : _verifyOtp,
            icon: const Icon(Icons.verified, size: 18),
            label: Text(flow.isLoading ? 'Verifying...' : 'Verify & Sign In'),
          ),
          TextButton(
            onPressed: (flow.resendSeconds == 0 && !flow.isLoading) ? _sendOtp : null,
            child: Text(
              flow.resendSeconds == 0 ? 'Resend OTP' : 'Resend OTP (${flow.resendSeconds}s)',
            ),
          ),
          TextButton(
            onPressed: flow.isLoading
                ? null
                : () {
                    flow.resetOtpFlow();
                    for (final c in _otpControllers) {
                      c.clear();
                    }
                    FocusScope.of(context).unfocus();
                  },
            child: const Text('Change number'),
          ),
        ],
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          alignment: Alignment.center,
          child: const Icon(Icons.electric_rickshaw, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'TricyKab',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Smart Tricycle Dispatch · Kabacan',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.controller, required this.focusNode, required this.onChanged});
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.isNotEmpty;
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          fillColor: filled ? AppColors.primary10 : AppColors.cardBackground,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: filled ? AppColors.primary : AppColors.border,
              width: filled ? 2 : 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
