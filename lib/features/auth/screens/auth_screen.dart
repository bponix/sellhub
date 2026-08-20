import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/config/app_text.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/navigation/deep_link_service.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/store/store_registry.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_brand_mark.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_state.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_view_extension.dart';
import 'package:pinput/pinput.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.preferredCountryCode,
    this.startInForgotMode = false,
    this.initialIdentifier,
    this.onAuthenticatedLocation,
  });

  final String? preferredCountryCode;
  final bool startInForgotMode;
  final String? initialIdentifier;
  final String? onAuthenticatedLocation;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const int _defaultCountryNumeric = 50;
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isForgotMode = false;
  bool _isNavigating = false;
  String _dialCode = '880';
  int? _countryNumeric = _defaultCountryNumeric;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isForgotMode = widget.startInForgotMode;
    if (widget.initialIdentifier != null &&
        widget.initialIdentifier!.trim().isNotEmpty) {
      _identifierController.text = widget.initialIdentifier!.trim();
    }
    Future<void>.microtask(_loadDefaultCountryLocalFirst);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultCountryLocalFirst() async {
    final preferredCode = widget.preferredCountryCode?.trim().toUpperCase();
    if (preferredCode != null && preferredCode.isNotEmpty) {
      _setCountryByCode(preferredCode);
    }
  }

  void _setCountryByCode(String code) {
    final country = Country.tryParse(code);
    if (country == null || !mounted) {
      return;
    }
    setState(() {
      _dialCode = country.phoneCode;
      _countryNumeric = _countryNumericFromIso(country.countryCode);
    });
  }

  int? _countryNumericFromIso(String alpha2) {
    const numericMap = <String, int>{
      'BD': 50,
      'IN': 356,
      'PK': 586,
      'NP': 524,
      'LK': 144,
      'US': 840,
      'GB': 826,
      'AE': 784,
      'SA': 682,
      'MY': 458,
      'SG': 702,
      'TH': 764,
      'JP': 392,
      'CN': 156,
      'CA': 124,
      'AU': 36,
      'DE': 276,
      'FR': 250,
      'IT': 380,
      'ES': 724,
    };
    return numericMap[alpha2.toUpperCase()];
  }

  void _openCountryPicker({required bool enabled}) {
    if (!enabled) {
      return;
    }
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      searchAutofocus: true,
      countryListTheme: const CountryListThemeData(
        bottomSheetHeight: 520,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      onSelect: (country) {
        if (!mounted) {
          return;
        }
        setState(() {
          _dialCode = country.phoneCode;
          _countryNumeric = _countryNumericFromIso(country.countryCode);
        });
      },
    );
  }

  void _resetFlow() {
    setState(() {
      _isForgotMode = false;
    });
    _passwordController.clear();
    _confirmPasswordController.clear();
    _otpController.clear();
    context.read<AuthCubit>().resetFlow();
  }

  String _identifierHintText() {
    const phoneExamplesByDial = <String, String>{
      '880': '017********',
      '91': '09********',
      '1': '(555) 123-4567',
      '44': '07*********',
      '971': '05********',
    };
    final phoneExample = phoneExamplesByDial[_dialCode];
    if (phoneExample == null) {
      return 'e.g. phone@example.com / 017********';
    }
    return 'e.g. $phoneExample';
  }

  ({String normalized, bool isEmail})? _parseIdentifier(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    if (value.contains('@')) {
      final normalizedEmail = value.toLowerCase();
      final emailPattern = RegExp(
        r"^[A-Z0-9._%+\-']+@[A-Z0-9.\-]+\.[A-Z]{2,63}$",
        caseSensitive: false,
      );
      if (!emailPattern.hasMatch(normalizedEmail)) {
        return null;
      }
      return (normalized: normalizedEmail, isEmail: true);
    }

    final compact = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (compact.isEmpty) {
      return null;
    }
    final normalized = compact.startsWith(_dialCode)
        ? compact
        : '$_dialCode${compact.replaceFirst(RegExp(r'^0+'), '')}';
    if (normalized.length < 8 || normalized.length > 15) {
      return null;
    }
    return (normalized: normalized, isEmail: false);
  }

  ({String firstName, String lastName}) _splitName(String rawName) {
    final normalized = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return (firstName: 'User', lastName: 'Guest');
    }
    final parts = normalized.split(' ');
    if (parts.length == 1) {
      return (firstName: parts.first, lastName: 'Guest');
    }
    return (
      firstName: parts.first,
      lastName: parts.sublist(1).join(' ').trim().isEmpty
          ? 'Guest'
          : parts.sublist(1).join(' '),
    );
  }

  Future<void> _handleSubmit(AuthState state) async {
    final cubit = context.read<AuthCubit>();
    if (state.isInitialMode()) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      final parsed = _parseIdentifier(_identifierController.text);
      if (parsed == null) {
        CustomToast.error('Enter a valid email or phone number');
        return;
      }
      FocusScope.of(context).unfocus();
      await cubit.checkUser(parsed.normalized);
      return;
    }

    if (state.isLoginMode(_isForgotMode) && state.userId != null) {
      if (_passwordController.text.isEmpty) {
        CustomToast.error('Password required');
        return;
      }
      final success = await cubit.login(
        _identifierController.text,
        _passwordController.text.trim(),
      );
      if (!mounted || !success) {
        return;
      }
      return;
    }

    if (state.isRegisterMode()) {
      if (_passwordController.text.length < 6) {
        CustomToast.error('Password min 6 chars');
        return;
      }
      final parsed = _parseIdentifier(_identifierController.text);
      if (parsed == null) {
        CustomToast.error('Enter a valid email or phone number');
        return;
      }
      final fullName = _fullNameController.text.trim();
      if (fullName.isEmpty) {
        CustomToast.error('Full name is required');
        return;
      }
      final nameParts = _splitName(fullName);
      final model = SignUpReq(
        country: _countryNumeric ?? _defaultCountryNumeric,
        currency: StoreRegistry.currentStore?.market.currencyCode ?? 'BDT',
        firstName: nameParts.firstName,
        language: StoreRegistry.currentStore?.market.defaultLanguage ?? 'en',
        lastName: nameParts.lastName,
        name: fullName,
        password: _passwordController.text.trim(),
        phone: parsed.isEmail ? null : int.tryParse(parsed.normalized),
        referedCode: '6',
        source: StoreScope.activeDomain(context),
        username: parsed.normalized,
        sourceId: StoreScope.activeSourceId(context),
        parentId: null,
      );
      await cubit.register(model);
      return;
    }

    if (state.isForgotMode(_isForgotMode)) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      final parsed = _parseIdentifier(_identifierController.text);
      if (parsed == null) {
        CustomToast.error('Enter a valid email or phone number');
        return;
      }
      await cubit.sendOtp(
        StoreScope.activeDomain(context),
        StoreScope.activeSourceId(context),
        parsed.normalized,
      );
      return;
    }

    if (state.isOtpMode(_isForgotMode) && state.userId != null) {
      final otp = int.tryParse(_otpController.text.trim());
      if (otp == null || _otpController.text.trim().length != 6) {
        CustomToast.error('Enter 6-digit OTP');
        return;
      }
      final success = await cubit.verifyOtp(
        otp,
        _identifierController.text,
        isResetFlow: _isForgotMode,
      );
      if (!mounted || !success) {
        return;
      }
      if (!_isForgotMode && _passwordController.text.isNotEmpty) {
        final didLogin = await cubit.login(
          _identifierController.text,
          _passwordController.text.trim(),
        );
        if (!mounted) {
          return;
        }
        if (didLogin) {
          _goAfterAuth();
          await DeepLinkService.consumePendingLink();
        }
      }
      return;
    }

    if (state.isResetMode() && state.userId != null) {
      if (_passwordController.text != _confirmPasswordController.text) {
        CustomToast.error('Passwords mismatch');
        return;
      }
      final otp = int.tryParse(_otpController.text.trim());
      if (otp == null) {
        CustomToast.error('Enter valid OTP');
        return;
      }
      final success = await cubit.resetPassword(
        _identifierController.text,
        otp,
        _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      if (success) {
        CustomToast.info('Password reset successfully. Please login.');
        _resetFlow();
      }
    }
  }

  void _goAfterAuth() {
    final target = widget.onAuthenticatedLocation?.trim();
    if (target != null && target.isNotEmpty) {
      AppRouter.go(target);
      return;
    }
    AppRouter.goToHome(context);
  }

  List<List<dynamic>> _stageIcon(AuthState state) {
    if (state.isOtpMode(_isForgotMode)) {
      return HugeIcons.strokeRoundedShield01;
    }
    if (state.isResetMode()) {
      return HugeIcons.strokeRoundedLockPassword;
    }
    if (state.isRegisterMode()) {
      return HugeIcons.strokeRoundedUserAdd02;
    }
    if (state.isForgotMode(_isForgotMode)) {
      return HugeIcons.strokeRoundedKey01;
    }
    if (state.isLoginMode(_isForgotMode)) {
      return HugeIcons.strokeRoundedLogin02;
    }
    return HugeIcons.strokeRoundedUserAccount;
  }

  String _stageEyebrow(AuthState state) {
    if (state.isOtpMode(_isForgotMode)) return 'Verify identity';
    if (state.isResetMode()) return 'Create a new password';
    if (state.isRegisterMode()) return 'Create account';
    if (state.isForgotMode(_isForgotMode)) return 'Recover account';
    if (state.isLoginMode(_isForgotMode)) return 'Welcome back';
    return 'Account access';
  }

  String _stageTitle(AuthState state) {
    if (state.isOtpMode(_isForgotMode)) return 'One more secure step';
    if (state.isResetMode()) return 'Set a password you can remember';
    if (state.isRegisterMode()) return 'Finish setting up your account';
    if (state.isForgotMode(_isForgotMode)) return 'Send a recovery code';
    if (state.isLoginMode(_isForgotMode)) {
      return 'Sign in to continue selling';
    }
    return 'Use email or phone to continue';
  }

  String _stageSubtitle(AuthState state) {
    if (state.isOtpMode(_isForgotMode)) {
      return 'We only need the verification code before moving you forward.';
    }
    if (state.isResetMode()) {
      return 'Choose a fresh password to restore access without leaving the app.';
    }
    if (state.isRegisterMode()) {
      return 'Your account stays linked to orders, saved products, and notifications.';
    }
    if (state.isForgotMode(_isForgotMode)) {
      return 'We will send a code to the same identifier used on your account.';
    }
    if (state.isLoginMode(_isForgotMode)) {
      return 'Your selling list, orders, and saved products stay connected to this account.';
    }
    return 'Start with the identifier you already use for Bponi stores.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final showFullLoader = _isNavigating;
    final inputTheme = theme.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status || prev.errorMessage != curr.errorMessage,
      listener: (context, state) async {
        if (state.status == AuthStatus.authenticated) {
          if (mounted) {
            setState(() => _isNavigating = true);
          }
          try {
            _goAfterAuth();
            await DeepLinkService.consumePendingLink();
          } finally {
            if (mounted) {
              setState(() => _isNavigating = false);
            }
          }
        } else if (state.status == AuthStatus.passwordReset) {
          CustomToast.info('Password reset successfully. Please login.');
          _resetFlow();
        } else if (state.errorMessage?.trim().isNotEmpty == true &&
            !state.isLoading) {
          CustomToast.error(state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: const SellHubTopAppBar(
            title: 'Account',
            subtitle: 'Sign in or create account',
            icon: HugeIcons.strokeRoundedUserAccount,
          ),
          body: SafeArea(
            child:
                showFullLoader ||
                    state.isLoading && state.status == AuthStatus.loading
                ? const _AuthScreenSkeleton()
                : GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        32 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.errorMessage?.trim().isNotEmpty ==
                                  true) ...[
                                _AuthErrorBanner(
                                  message: state.errorMessage!,
                                  onReset: _resetFlow,
                                ),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 8),
                              const _AuthLogo(size: 72, showWordmark: false),
                              const SizedBox(height: 16),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _AuthHeader(
                                  key: ValueKey<String>(
                                    '${state.status.name}-${_isForgotMode ? 'forgot' : 'main'}',
                                  ),
                                  title: state.getMainTitle(
                                    false,
                                    _isForgotMode,
                                  ),
                                  subtitle: state.getSubtitle(_isForgotMode),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _AuthStageBanner(
                                icon: _stageIcon(state),
                                eyebrow: _stageEyebrow(state),
                                title: _stageTitle(state),
                                subtitle: _stageSubtitle(state),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColor.safe1,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColor.safe,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 18,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Account access',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Secure sign in and recovery',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _AuthHintsRow(
                                icon: state.isOtpMode(_isForgotMode)
                                    ? HugeIcons.strokeRoundedMessage02
                                    : HugeIcons.strokeRoundedShoppingBag02,
                                title: state.isOtpMode(_isForgotMode)
                                    ? 'Use the 6-digit code'
                                    : 'Recover selling list and orders',
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Theme(
                                  data: theme.copyWith(
                                    inputDecorationTheme: inputTheme,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: cs.outlineVariant
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: state.isInitialMode()
                                                    ? () => _openCountryPicker(
                                                        enabled: true,
                                                      )
                                                    : null,
                                                borderRadius:
                                                    const BorderRadius.horizontal(
                                                      left: Radius.circular(12),
                                                    ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 12,
                                                      ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '+$_dialCode',
                                                        style: theme
                                                            .textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Icon(
                                                        Icons
                                                            .keyboard_arrow_down_rounded,
                                                        color:
                                                            cs.onSurfaceVariant,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 36,
                                                color: cs.outlineVariant
                                                    .withValues(alpha: 0.7),
                                              ),
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _identifierController,
                                                  readOnly: !state
                                                      .isInitialMode(),
                                                  keyboardType: TextInputType
                                                      .emailAddress,
                                                  validator: (v) =>
                                                      (v?.isEmpty ?? true)
                                                      ? 'Required'
                                                      : null,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        _identifierHintText(),
                                                    border: InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                          horizontal: 12,
                                                        ),
                                                    suffixIcon:
                                                        !state.isInitialMode()
                                                        ? IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                            ),
                                                            onPressed:
                                                                _resetFlow,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (state.isInitialMode())
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              'Use email or phone to continue.',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        if (state.isLoginMode(_isForgotMode) ||
                                            state.isRegisterMode()) ...[
                                          const SizedBox(height: 16),
                                          _PasswordField(
                                            controller: _passwordController,
                                            label: state.isResetMode()
                                                ? 'New Password'
                                                : 'Password',
                                            obscure: _obscurePassword,
                                            onToggle: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ],
                                        if (state.isRegisterMode()) ...[
                                          const SizedBox(height: 16),
                                          const _InlineFormLead(
                                            icon: HugeIcons.strokeRoundedUser,
                                            title: 'Profile details',
                                            subtitle:
                                                'Use your real name so order updates stay recognizable.',
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _fullNameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Full name',
                                              hintText: 'e.g. John William Doe',
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              labelText: 'Email (optional)',
                                              hintText: 'name@company.com',
                                            ),
                                          ),
                                        ],
                                        if (state.isLoginMode(_isForgotMode))
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () async {
                                                setState(() {
                                                  _isForgotMode = true;
                                                });
                                                await context
                                                    .read<AuthCubit>()
                                                    .sendOtp(
                                                      StoreScope.activeDomain(
                                                        context,
                                                      ),
                                                      StoreScope.activeSourceId(
                                                        context,
                                                      ),
                                                      _identifierController
                                                          .text,
                                                    );
                                              },
                                              child: const Text(
                                                'Forgot password?',
                                              ),
                                            ),
                                          ),
                                        if (state.isForgotMode(_isForgotMode))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              'We will send a verification code.',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        if (state.isOtpMode(_isForgotMode)) ...[
                                          const SizedBox(height: 12),
                                          _InlineFormLead(
                                            icon:
                                                HugeIcons.strokeRoundedShield01,
                                            title: 'Verification code',
                                            subtitle:
                                                'Enter the 6-digit code sent to your account.',
                                          ),
                                          const SizedBox(height: 12),
                                          _OtpInput(controller: _otpController),
                                          const SizedBox(height: 16),
                                          if (state.resendSeconds > 0)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColor.safe1,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Resend in ${state.resendSeconds}s',
                                                textAlign: TextAlign.center,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          cs.onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            )
                                          else
                                            TextButton(
                                              onPressed: () => context
                                                  .read<AuthCubit>()
                                                  .resendOtp(),
                                              child: const Text('Resend code'),
                                            ),
                                        ],
                                        if (state.isResetMode()) ...[
                                          const SizedBox(height: 16),
                                          _PasswordField(
                                            controller:
                                                _confirmPasswordController,
                                            label: 'Confirm Password',
                                            obscure: _obscureConfirmPassword,
                                            onToggle: () {
                                              setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
                                              });
                                            },
                                          ),
                                        ],
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          height: 48,
                                          child: FilledButton(
                                            onPressed: state.isLoading
                                                ? null
                                                : () => _handleSubmit(state),
                                            child: Text(
                                              state.isLoading
                                                  ? 'Please wait...'
                                                  : state.getButtonText(
                                                      _isForgotMode,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo({required this.size, required this.showWordmark});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surface,
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          padding: EdgeInsets.all(size * 0.14),
          child: SellHubBrandMark(size: size * 0.72),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 10),
          Text(
            AppText.appName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AuthStageBanner extends StatelessWidget {
  const _AuthStageBanner({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColor.safe),
            ),
            child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHintsRow extends StatelessWidget {
  const _AuthHintsRow({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _HintTile(
            icon: HugeIcons.strokeRoundedShield01,
            title: 'Secure',
            subtitle: 'Protected account access',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HintTile(
            icon: icon,
            title: title,
            subtitle: 'Fast, guided recovery flow',
          ),
        ),
      ],
    );
  }
}

class _HintTile extends StatelessWidget {
  const _HintTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppHugeIcon(icon, size: 16, color: AppColor.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineFormLead extends StatelessWidget {
  const _InlineFormLead({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppHugeIcon(icon, size: 16, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter ${label.toLowerCase()}',
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  const _OtpInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Pinput(
      length: 6,
      controller: controller,
      keyboardType: TextInputType.number,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      defaultPinTheme: PinTheme(
        width: 46,
        height: 54,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: 46,
        height: 54,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      submittedPinTheme: PinTheme(
        width: 46,
        height: 54,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message, required this.onReset});

  final String message;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.alertLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.alert.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authentication issue',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColor.alert,
            ),
          ),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 10),
          TextButton(onPressed: onReset, child: const Text('Reset')),
        ],
      ),
    );
  }
}

class _AuthScreenSkeleton extends StatelessWidget {
  const _AuthScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: _SkeletonCircle(size: 72),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: _SkeletonLine(width: 160, height: 22),
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: _SkeletonLine(width: 260, height: 14),
              ),
              SizedBox(height: 16),
              _SkeletonBox(height: 196),
              SizedBox(height: 14),
              Align(
                alignment: Alignment.center,
                child: _SkeletonLine(width: 280, height: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColor.safe1),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
