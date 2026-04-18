import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event_state.dart';
import '../../blocs/family/family_bloc.dart';
import '../../blocs/family/family_event_state.dart';
import '../../blocs/family/active_profile_cubit.dart';
import '../../../data/models/family_profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _familyFormKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _familyRelationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load family members initially
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<FamilyBloc>().add(LoadFamilyMembers(authState.user.id));
    } else if (authState is AuthRegisterSuccess) {
      context.read<FamilyBloc>().add(LoadFamilyMembers(authState.user.id));
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _familyNameController.dispose();
    _familyRelationController.dispose();
    super.dispose();
  }

  void _showChangePasswordBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Change Password',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _oldPasswordController,
                  label: 'Old Password',
                  hint: 'Enter your old password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'Enter your new password',
                  obscureText: true,
                  prefixIcon: Icons.lock_reset_rounded,
                  validator: (v) =>
                      v!.length < 8 ? 'Password too short' : null,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Submit',
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(
                            ChangePasswordRequested(
                              oldPassword: _oldPasswordController.text,
                              newPassword: _newPasswordController.text,
                            ),
                          );
                      Navigator.pop(context);
                    }
                  },
                  gradient: AppColors.primaryGradient,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddFamilyBottomSheet(BuildContext context, String parentUserId) {
    _familyNameController.clear();
    _familyRelationController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _familyFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Family Member',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _familyNameController,
                  label: 'Full Name',
                  hint: 'e.g. John Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _familyRelationController,
                  label: 'Relationship',
                  hint: 'e.g. Father, Daughter',
                  prefixIcon: Icons.family_restroom_rounded,
                  validator: (v) => v!.trim().isEmpty ? 'Relationship is required' : null,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Save Profile',
                  onTap: () {
                    if (_familyFormKey.currentState!.validate()) {
                      final newMember = FamilyProfileModel(
                        id: const Uuid().v4(),
                        parentUserId: parentUserId,
                        name: _familyNameController.text.trim(),
                        relation: _familyRelationController.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      context.read<FamilyBloc>().add(AddFamilyMember(newMember));
                      Navigator.pop(context);
                    }
                  },
                  gradient: AppColors.primaryGradient,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const DeleteAccountRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primary,
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            String name = 'User';
            String email = '';
            String userId = '';
            
            if (state is AuthAuthenticated) {
              name = state.user.fullName;
              email = state.user.email;
              userId = state.user.id;
            } else if (state is AuthRegisterSuccess) {
              name = state.user.fullName;
              email = state.user.email;
              userId = state.user.id;
            } else if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final activeProfileCubit = context.watch<ActiveProfileCubit>();
            final activeProfileName = activeProfileCubit.state.isEmpty ? name : activeProfileCubit.state;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      activeProfileName.isNotEmpty ? activeProfileName[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activeProfileName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeProfileName == name ? email : 'Family Member',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Family Profiles Section
                  _buildFamilyMembers(name, activeProfileName, userId),

                  const SizedBox(height: 32),
                  _buildActionTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    onTap: () => _showChangePasswordBottomSheet(context),
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    onTap: () {
                      context.read<AuthBloc>().add(const LogoutRequested());
                    },
                    isDestructive: false,
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Account',
                    onTap: () => _confirmDeleteAccount(context),
                    isDestructive: true,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFamilyMembers(String currentUserName, String activeProfileName, String parentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Profiles',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            List<FamilyProfileModel> members = [];
            if (state is FamilyLoaded) {
              members = state.members;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Base User
                  _buildProfileAvatar(currentUserName, activeProfileName == currentUserName, parentUserId),
                  // DB Members
                  ...members.map((m) => _buildProfileAvatar(m.name, activeProfileName == m.name, parentUserId)),
                  // Add New Button
                  _buildProfileAvatar('Add New', false, parentUserId, isAdd: true),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(String name, bool isActive, String parentUserId, {bool isAdd = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          if (isAdd) {
             _showAddFamilyBottomSheet(context, parentUserId);
          } else {
            context.read<ActiveProfileCubit>().selectProfile(name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Switched to $name\'s profile'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 1),
              ),
            );
            context.go('/home');
          }
        },
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAdd ? Colors.white : (isActive ? AppColors.primary : AppColors.surfaceVariant),
                border: Border.all(
                  color: isAdd ? AppColors.border : (isActive ? AppColors.primaryDark : Colors.transparent),
                  width: 2,
                ),
                boxShadow: isActive ? [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Center(
                child: isAdd
                    ? const Icon(Icons.add_rounded, color: AppColors.primary, size: 28)
                    : Text(
                        name[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdd ? 'Add' : name.split(' ').first,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;
    final bgColor = isDestructive ? Colors.red.withOpacity(0.1) : AppColors.primarySurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
