import 'package:flutter/material.dart';

import '../customer/customer_dashboard.dart';
import '../services/api_service.dart';
import '../shared/app_theme.dart';
import '../shared/widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final municipalityController = TextEditingController(text: 'Trinidad');
  final streetNoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String selectedBarangay = 'Poblacion (Center)';
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  static const List<String> barangays = [
    'Banlasan',
    'Bongbong',
    'Catoogan',
    'Guinobatan',
    'Hinlayagan Ilaud',
    'Hinlayagan Sur',
    'Ipil',
    'Kinan-oan',
    'La Union',
    'La Victoria',
    'Mabuhay Cabigohan',
    'Mahagbu',
    'Manuel M. Roxas',
    'Poblacion (Center)',
    'San Isidro',
    'San Vicente',
    'Santo Tomas',
    'Soom',
    'Tagum Norte',
    'Tagum Sur',
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    municipalityController.dispose();
    streetNoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final streetNo = streetNoController.text.trim();
    final password = passwordController.text;
    final passwordConfirmation = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || streetNo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
        ),
      );
      return;
    }

    if (password != passwordConfirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    try {
      await ApiService.register(
        name: name,
        email: email,
        phone: phone,
        municipality: 'Trinidad',
        barangay: selectedBarangay,
        streetNo: streetNo,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerDashboard(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        title: const Text('Create Customer Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  size: 60,
                  color: AppTheme.emerald,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Join as a Customer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your account to browse products and place orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Full Name',
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'Email Address',
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'Phone Number',
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: municipalityController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city_outlined),
                    labelText: 'Municipality',
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: selectedBarangay,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.map_outlined),
                    labelText: 'Barangay',
                  ),
                  items: barangays
                      .map(
                        (barangay) => DropdownMenuItem(
                          value: barangay,
                          child: Text(barangay),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedBarangay = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: streetNoController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.home_outlined),
                    hintText: 'Street No. / House No.',
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: hideConfirmPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    hintText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hideConfirmPassword = !hideConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Sign Up',
                  icon: Icons.person_add,
                  onPressed: register,
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
