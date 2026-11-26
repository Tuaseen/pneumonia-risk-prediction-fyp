import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'design.dart';

class AuthScreen extends StatefulWidget {
  final AppStore store;
  final String? startupError;

  const AuthScreen({
    super.key,
    required this.store,
    this.startupError,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _specialty = TextEditingController(text: 'Pulmonology');
  String _sex = 'male';
  String _role = 'patient';

  bool _register = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _age.dispose();
    _specialty.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.store.signIn(
        _email.text,
        _password.text,
        register: _register,
        role: _role,
        name: _register ? _name.text.trim() : null,
        age: (_register && _role == 'patient') ? int.tryParse(_age.text.trim()) : null,
        sex: (_register && _role == 'patient') ? _sex : null,
        specialty: (_register && _role == 'doctor') ? _specialty.text.trim() : null,
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slateBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo & Brand
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BrandMark(size: 38),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Pneumonia Assistant',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Headline matching web app
                  const Text(
                    'Clinical Monitoring &\nPneumonia Risk Screening',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1.25,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Clinical symptom evaluation, risk screening, and personalized plain-language health reports.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5, color: textMuted),
                  ),
                  const SizedBox(height: 32),

                  // Startup Notice if any
                  if (widget.startupError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: alertRedBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: alertRedBorder),
                      ),
                      child: Text(
                        widget.startupError!,
                        style: const TextStyle(fontSize: 12, color: destructiveRed),
                      ),
                    ),



                  // Cloud Sign In / Registration Form
                  CardPanel(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _register ? 'Create an Account' : 'Account Sign In',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Role selection during registration
                          if (_register) ...[
                            const Text(
                              'Account Type:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    avatar: const Icon(Icons.person_outline, size: 16),
                                    label: const Text('Patient'),
                                    selected: _role == 'patient',
                                    selectedColor: primaryBlueLight,
                                    onSelected: (_) => setState(() => _role = 'patient'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ChoiceChip(
                                    avatar: const Icon(Icons.medical_services_outlined, size: 16),
                                    label: const Text('Doctor'),
                                    selected: _role == 'doctor',
                                    selectedColor: const Color(0xFFF3E8FF),
                                    onSelected: (_) => setState(() => _role = 'doctor'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Patient-specific demographics
                            if (_role == 'patient') ...[
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'e.g. John Doe',
                                  prefixIcon: Icon(Icons.person_outline, size: 18),
                                ),
                                validator: (v) =>
                                    (v != null && v.trim().isNotEmpty) ? null : 'Please enter your name',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _age,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Age (years)',
                                        hintText: 'e.g. 45',
                                        prefixIcon: Icon(Icons.cake_outlined, size: 18),
                                      ),
                                      validator: (v) {
                                        final a = int.tryParse(v ?? '');
                                        if (a == null || a <= 0 || a > 120) {
                                          return 'Valid age';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _sex,
                                      decoration: const InputDecoration(
                                        labelText: 'Biological Sex',
                                        prefixIcon: Icon(Icons.wc_outlined, size: 18),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'male', child: Text('Male')),
                                        DropdownMenuItem(value: 'female', child: Text('Female')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _sex = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Doctor-specific fields
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Doctor Full Name',
                                  hintText: 'e.g. Dr. Sarah Chen',
                                  prefixIcon: Icon(Icons.medical_services_outlined, size: 18),
                                ),
                                validator: (v) =>
                                    (v != null && v.trim().isNotEmpty) ? null : 'Please enter doctor name',
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _specialty,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Clinical Specialty',
                                  hintText: 'e.g. Pulmonology / Respiratory Care',
                                  prefixIcon: Icon(Icons.domain_outlined, size: 18),
                                ),
                                validator: (v) =>
                                    (v != null && v.trim().isNotEmpty) ? null : 'Please enter specialty',
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],

                          // Credentials
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.alternate_email, size: 18),
                            ),
                            validator: (v) =>
                                (v != null && v.contains('@')) ? null : 'Enter a valid email address',
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) =>
                                (v != null && v.length >= 6) ? null : 'Password must be at least 6 characters',
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(_register
                                      ? (_role == 'doctor' ? 'Create Doctor Account' : 'Create Patient Account')
                                      : 'Sign In with Cloud'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => _register = !_register),
                              child: Text(
                                _register
                                    ? 'Already have an account? Sign in'
                                    : 'New user? Create a Patient or Doctor account',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
