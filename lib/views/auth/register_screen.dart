import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/vroom_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/vroom_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgController = TextEditingController(text: 'CUET');

  // Role selection
  UserRoleMode _selectedRole = UserRoleMode.passenger;

  // Vehicle info (for Rider)
  String _vehicleType = 'Motorcycle';
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final isRider = _selectedRole == UserRoleMode.rider;

    return Scaffold(
      backgroundColor: VroomColors.background,
      appBar: AppBar(
        title: const Text('Create VROOM Account'),
        backgroundColor: VroomColors.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Join VROOM',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: VroomColors.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share campus & city rides, split fuel costs, and travel safely.',
                style: TextStyle(fontSize: 13, color: VroomColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Step 1: Select Role Option (Passenger vs Rider)
              const Text(
                'I am registering primarily as:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VroomColors.text),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      title: 'Passenger',
                      subtitle: 'Find & book rides',
                      icon: Icons.person_pin_circle,
                      mode: UserRoleMode.passenger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      title: 'Rider / Driver',
                      subtitle: 'Offer empty seats',
                      icon: Icons.two_wheeler,
                      mode: UserRoleMode.rider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: VroomColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: VroomColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Md. Redwan Mahmud',
                        prefixIcon: Icon(Icons.person_outline, size: 18, color: VroomColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'e.g. redwan@cuet.ac.bd',
                        prefixIcon: Icon(Icons.email_outlined, size: 18, color: VroomColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+880 1712-345678',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18, color: VroomColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('University / Organization', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _orgController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. CSE, CUET (ID: 2204055)',
                        prefixIcon: Icon(Icons.school_outlined, size: 18, color: VroomColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Create a password (min 6 characters)',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: VroomColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: VroomColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    // Rider Specific Vehicle Details Section
                    if (isRider) ...[
                      const Divider(height: 32),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: VroomColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.directions_bike, color: VroomColors.primary, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Vehicle Information',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: VroomColors.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Vehicle Type Selector (Motorcycle / Car)
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Motorcycle / Bike', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              selected: _vehicleType == 'Motorcycle',
                              selectedColor: VroomColors.primary,
                              labelStyle: TextStyle(color: _vehicleType == 'Motorcycle' ? Colors.white : VroomColors.text),
                              onSelected: (_) => setState(() => _vehicleType = 'Motorcycle'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Car / Microbus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              selected: _vehicleType == 'Car',
                              selectedColor: VroomColors.primary,
                              labelStyle: TextStyle(color: _vehicleType == 'Car' ? Colors.white : VroomColors.text),
                              onSelected: (_) => setState(() => _vehicleType = 'Car'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text('Vehicle Model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _vehicleModelController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Honda CB Hornet / Toyota Axio',
                          prefixIcon: Icon(Icons.two_wheeler, size: 18, color: VroomColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('BRTA Registration / License Plate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _vehiclePlateController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Chatto Metro-Ha 139396',
                          prefixIcon: Icon(Icons.badge_outlined, size: 18, color: VroomColors.textMuted),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit Registration Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: VroomColors.primary,
                      ),
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Register as ${_selectedRole == UserRoleMode.rider ? "Rider" : "Passenger"}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Back to Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: VroomColors.textMuted, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(color: VroomColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required UserRoleMode mode,
  }) {
    final isSelected = _selectedRole == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedRole = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? VroomColors.surfaceMuted : VroomColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? VroomColors.primary : VroomColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? VroomColors.primary : VroomColors.textMuted),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isSelected ? VroomColors.primary : VroomColors.text,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: VroomColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final org = _orgController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in name, email, phone, and password.'),
          backgroundColor: VroomColors.danger,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password should be at least 6 characters.'),
          backgroundColor: VroomColors.danger,
        ),
      );
      return;
    }

    if (_selectedRole == UserRoleMode.rider) {
      if (_vehicleModelController.text.trim().isEmpty || _vehiclePlateController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your vehicle model and license plate number.'),
            backgroundColor: VroomColors.danger,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    final provider = context.read<VroomProvider>();

    final success = await provider.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      roleMode: _selectedRole,
      universityOrOrg: org.isNotEmpty ? org : 'Verified Commuter',
      vehicleType: _selectedRole == UserRoleMode.rider ? _vehicleType : null,
      vehicleModel: _selectedRole == UserRoleMode.rider ? _vehicleModelController.text.trim() : null,
      vehiclePlate: _selectedRole == UserRoleMode.rider ? _vehiclePlateController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Pop back to root (which now renders Home because isAuthenticated = true)
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account registered! Welcome, ${provider.currentUser.name}'),
            backgroundColor: VroomColors.text,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please check information and try again.'),
            backgroundColor: VroomColors.danger,
          ),
        );
      }
    }
  }
}
