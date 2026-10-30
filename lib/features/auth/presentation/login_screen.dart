import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/widgets.dart';
import '../../../core/providers.dart';
import '../../../firebase_options.dart';
import '../../../l10n/strings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final contact = TextEditingController(), code = TextEditingController();
  bool phone = false, sent = false;
  @override
  void dispose() {
    contact.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.primaryContainer,
              context.colors.surface,
              context.colors.tertiaryContainer.withValues(alpha: .5),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.spa_rounded,
                      size: 56,
                      color: context.colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('appName'),
                      textAlign: TextAlign.center,
                      style: context.fonts.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('tagline'),
                      textAlign: TextAlign.center,
                      style: context.fonts.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    if (!auth.configured) ...[
                      Text(
                        context.tr('firebaseNotConfigured'),
                        style: TextStyle(color: context.colors.primary),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(context.tr('email')),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(context.tr('phone')),
                        ),
                      ],
                      selected: {phone},
                      onSelectionChanged: (value) => setState(() {
                        phone = value.first;
                        sent = false;
                        contact.clear();
                        code.clear();
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: contact,
                      keyboardType: phone
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: context.tr(phone ? 'phone' : 'email'),
                        hintText: phone ? '+923001234567' : null,
                      ),
                    ),
                    if (phone)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          context.tr('phoneConsent'),
                          style: context.fonts.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (sent && !DefaultFirebaseOptions.windows) ...[
                      TextField(
                        controller: code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: context.tr('otpCode'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ActionButton(
                        label: context.tr('verifyAndSignIn'),
                        icon: Icons.lock_open,
                        onPressed: () async {
                          if (phone) {
                            await auth.verifyPhoneCode(code.text.trim());
                          } else {
                            await auth.verifyEmailCode(contact.text, code.text);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (sent && !phone && DefaultFirebaseOptions.windows) ...[
                      TextField(
                        controller: code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: context.tr('otpCode'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ActionButton(
                        label: context.tr('verifyAndSignIn'),
                        onPressed: () =>
                            auth.verifyEmailCode(contact.text, code.text),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ActionButton(
                      label: context.tr(sent ? 'resendCode' : 'sendCode'),
                      icon: Icons.send_outlined,
                      onPressed: () async {
                        if (phone) {
                          await auth.sendPhoneCode(contact.text.trim());
                        } else {
                          await auth.requestEmailCode(contact.text);
                        }
                        if (mounted) setState(() => sent = true);
                      },
                    ),
                    const SizedBox(height: 12),
                    ActionButton(
                      label: context.tr('continueGoogle'),
                      icon: Icons.account_circle_outlined,
                      onPressed: auth.google,
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String?>(
                      valueListenable: auth.desktopCode,
                      builder: (context, value, child) => value == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                '${context.tr('desktopCode')}: $value',
                                style: context.fonts.titleLarge,
                              ),
                            ),
                    ),
                    OutlinedButton.icon(
                      onPressed: auth.enterDemo,
                      icon: const Icon(Icons.science_outlined),
                      label: Text(context.tr('tryDemo')),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('offlineLoginHelp'),
                      style: context.fonts.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DesktopApprovalScreen extends ConsumerStatefulWidget {
  const DesktopApprovalScreen({super.key});
  @override
  ConsumerState<DesktopApprovalScreen> createState() =>
      _DesktopApprovalScreenState();
}

class _DesktopApprovalScreenState extends ConsumerState<DesktopApprovalScreen> {
  bool completed = false;
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider), id = auth.desktopRequest ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('desktopSignIn'))),
      body: PageBody(
        maxWidth: 560,
        children: [
          Icon(
            completed ? Icons.check_circle_outline : Icons.computer,
            size: 64,
            color: context.colors.primary,
          ),
          Text(
            context.tr(completed ? 'desktopComplete' : 'desktopApprovalHelp'),
            style: context.fonts.titleLarge,
          ),
          if (!completed) ...[
            SelectableText(
              id.length < 6 ? id : id.substring(id.length - 6).toUpperCase(),
              style: context.fonts.headlineLarge,
            ),
            ActionButton(
              label: context.tr('approveDesktop'),
              onPressed: () async {
                await auth.completeDesktop(id);
                if (mounted) setState(() => completed = true);
              },
            ),
          ],
          OutlinedButton(
            onPressed: auth.signOut,
            child: Text(context.tr('signOut')),
          ),
        ],
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool joining = false;
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('yourShop')),
      actions: [
        IconButton(
          tooltip: context.tr('signOut'),
          onPressed: ref.read(authProvider).signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: PageBody(
      maxWidth: 560,
      children: [
        Text(context.tr('onboardingHelp'), style: context.fonts.bodyLarge),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(context.tr('createShop'))),
            ButtonSegment(value: true, label: Text(context.tr('joinShop'))),
          ],
          selected: {joining},
          onSelectionChanged: (v) => setState(() {
            joining = v.first;
            text.clear();
          }),
        ),
        TextField(
          controller: text,
          decoration: InputDecoration(
            labelText: context.tr(joining ? 'inviteCode' : 'shopName'),
          ),
        ),
        ActionButton(
          label: context.tr(joining ? 'joinShop' : 'createShop'),
          onPressed: () async {
            final auth = ref.read(authProvider);
            if (joining) {
              await auth.joinShop(text.text);
            } else {
              await auth.createShop(text.text);
            }
          },
        ),
      ],
    ),
  );
}
