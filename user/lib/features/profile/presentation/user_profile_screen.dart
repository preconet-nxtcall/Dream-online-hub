import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../models/user/recharge_record_model.dart';
import '../../../network/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../storage/local_storage_repository.dart';
import '../../../storage/secure_storage_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_logout_dialog.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  double _successfulRechargeBalance = 0.0;
  int _successfulOrdersCount = 0;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final apiClient = ApiClient();
      int userId = 22;
      final currentUser = LocalStorageRepositoryImpl().getUser();
      if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
        final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          userId = int.tryParse(digitsOnly) ?? 22;
        }
      }
      if (userId == 22) {
        final storedUserId = await SecureStorageService().read(StorageKeys.userId);
        if (storedUserId != null && storedUserId.isNotEmpty) {
          final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
          if (digitsOnly.isNotEmpty) {
            userId = int.tryParse(digitsOnly) ?? 22;
          }
        }
      }

      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        options: Options(validateStatus: (status) => status != null && status < 500),
        data: {
          'action': 'recharge_records',
          'user_id': userId,
        },
      );

      double sumApproved = 0.0;
      int approvedCount = 0;
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        List rawList = [];
        if (data['data'] is List && (data['data'] as List).isNotEmpty) {
          rawList.addAll(data['data'] as List);
        } else if (data['recharges'] is List && (data['recharges'] as List).isNotEmpty) {
          rawList.addAll(data['recharges'] as List);
        } else if (data['categorized'] is Map) {
          final cat = data['categorized'] as Map;
          if (cat['successful'] is List) rawList.addAll(cat['successful'] as List);
        }

        for (final item in rawList) {
          final rawAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          final rawStatus = (item['stage_status']?.toString() ?? item['status']?.toString() ?? '').toLowerCase();

          if (rawStatus.contains('done') || rawStatus.contains('successful') || rawStatus.contains('approved')) {
            sumApproved += rawAmount;
            approvedCount++;
          }
        }
      }

      if (sumApproved == 0.0 && approvedCount == 0) {
        final local = LocalStorageRepositoryImpl().getSubmittedRecharges();
        for (final item in local) {
          double amt = 0.0;
          String st = '';
          if (item is RechargeRecordModel) {
            amt = item.amount;
            st = item.status.toLowerCase();
          } else if (item is Map) {
            amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            st = (item['status'] ?? '').toString().toLowerCase();
          }
          if (st.contains('done') || st.contains('successful') || st.contains('approved')) {
            sumApproved += amt;
            approvedCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _successfulRechargeBalance = sumApproved;
          _successfulOrdersCount = approvedCount;
          _isLoadingBalance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    AppLogoutDialog.show(context);
  }

  void _showEditProfileDialog(BuildContext context, String currentName, String currentEmail, String currentPhone) {
    final nameCtrl = TextEditingController(text: currentName);
    final emailCtrl = TextEditingController(text: currentEmail);
    final phoneCtrl = TextEditingController(text: currentPhone);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final nameVal = nameCtrl.text.trim();
                          final phoneVal = phoneCtrl.text.trim();
                          final emailVal = emailCtrl.text.trim();

                          if (nameVal.isEmpty || phoneVal.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name and Phone cannot be empty.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final authProv = Provider.of<AuthProvider>(context, listen: false);
                          final success = await authProv.updateUserProfile(
                            name: nameVal,
                            email: emailVal,
                            phone: phoneVal,
                          );

                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User profile updated successfully!'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProv.errorMessage ?? 'Failed to update profile.'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpdatePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14102B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Orange Icon Badge matching screenshot
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Update Your Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.black54),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // OLD PASSWORD
                      _buildPasswordInput(
                        controller: oldPassCtrl,
                        label: 'OLD PASSWORD',
                        hint: 'Enter Old Password',
                        obscureText: obscureOld,
                        onToggleObscure: () => setDialogState(() => obscureOld = !obscureOld),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // NEW PASSWORD
                      _buildPasswordInput(
                        controller: newPassCtrl,
                        label: 'NEW PASSWORD',
                        hint: 'Enter New Password',
                        obscureText: obscureNew,
                        onToggleObscure: () => setDialogState(() => obscureNew = !obscureNew),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // CONFIRM PASSWORD
                      _buildPasswordInput(
                        controller: confirmPassCtrl,
                        label: 'CONFIRM PASSWORD',
                        hint: 'Confirm New Password',
                        obscureText: obscureConfirm,
                        onToggleObscure: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 28),

                      // Save Changes Pill Button matching screenshot
                      Center(
                        child: SizedBox(
                          width: 220,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final oldPass = oldPassCtrl.text.trim();
                                    final newPass = newPassCtrl.text.trim();
                                    final confirmPass = confirmPassCtrl.text.trim();

                                    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please fill in all password fields.'),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }

                                    if (newPass != confirmPass) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('New password and confirm password do not match.'),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }

                                    if (newPass.length < 6) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('New password must be at least 6 characters long.'),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSaving = true);
                                    final authProv = Provider.of<AuthProvider>(context, listen: false);
                                    final success = await authProv.updatePassword(
                                      oldPassword: oldPass,
                                      newPassword: newPass,
                                      confirmPassword: confirmPass,
                                    );

                                    if (!context.mounted) return;
                                    Navigator.of(ctx).pop();

                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Password updated successfully!'),
                                          backgroundColor: Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(authProv.errorMessage ?? 'Failed to update password.'),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C2F36),
                              foregroundColor: const Color(0xFFFFD700),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Color(0xFFFFD700), strokeWidth: 2),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFD700),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF475569),
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13.5),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1B2E) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : Colors.grey[600],
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF2E2756) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: const Text(
                'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
                style: TextStyle(fontSize: 13.5),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          final authProv = Provider.of<AuthProvider>(context, listen: false);
                          final success = await authProv.deleteUserAccount();

                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account deleted successfully.'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            context.go('/login');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProv.errorMessage ?? 'Failed to delete account.'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGetInTouchSupportDialog(
    BuildContext context,
    String defaultName,
    String defaultEmail,
    String defaultPhone,
  ) {
    final nameCtrl = TextEditingController(text: defaultName);
    final emailCtrl = TextEditingController(text: defaultEmail);
    final phoneCtrl = TextEditingController(text: defaultPhone);
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 580),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF130D2B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                        : const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Get in Touch',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Row 1: Name * & Email *
                      Row(
                        children: [
                          Expanded(
                            child: _buildStyledFormField(
                              controller: nameCtrl,
                              label: 'Name *',
                              hint: 'Enter full name',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStyledFormField(
                              controller: emailCtrl,
                              label: 'Email *',
                              hint: 'Enter email address',
                              keyboardType: TextInputType.emailAddress,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 2: Phone * & Subject *
                      Row(
                        children: [
                          Expanded(
                            child: _buildStyledFormField(
                              controller: phoneCtrl,
                              label: 'Phone *',
                              hint: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStyledFormField(
                              controller: subjectCtrl,
                              label: 'Subject *',
                              hint: 'Enter query subject',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 3: Message
                      _buildStyledFormField(
                        controller: messageCtrl,
                        label: 'Message',
                        hint: 'Write your issue or inquiry details here...',
                        maxLines: 4,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 22),

                      // Full-Width Purple Submit Button: Send
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  final email = emailCtrl.text.trim();
                                  final phone = phoneCtrl.text.trim();
                                  final subject = subjectCtrl.text.trim();

                                  if (name.isEmpty || email.isEmpty || phone.isEmpty || subject.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please fill in all required fields marked with *'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isSubmitting = true);

                                  try {
                                    final apiClient = ApiClient();
                                    int userId = 22;
                                    final currentUser = LocalStorageRepositoryImpl().getUser();
                                    if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
                                      final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
                                      if (digitsOnly.isNotEmpty) {
                                        userId = int.tryParse(digitsOnly) ?? 22;
                                      }
                                    }
                                    if (userId == 22) {
                                      final storedUserId = await SecureStorageService().read(StorageKeys.userId);
                                      if (storedUserId != null && storedUserId.isNotEmpty) {
                                        final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
                                        if (digitsOnly.isNotEmpty) {
                                          userId = int.tryParse(digitsOnly) ?? 22;
                                        }
                                      }
                                    }

                                    await apiClient.post(
                                      ApiEndpoints.getQrCode,
                                      options: Options(validateStatus: (status) => status != null && status < 500),
                                      data: {
                                        'action': 'send_enquiry',
                                        'name': name,
                                        'email': email,
                                        'phone': phone,
                                        'sub': subject,
                                        'msg': messageCtrl.text.trim(),
                                        'user_id': userId,
                                      },
                                    );

                                    if (!context.mounted) return;
                                    Navigator.of(ctx).pop();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.white),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Enquiry sent successfully for $name!',
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    setDialogState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to send enquiry: ${e.toString()}'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Send',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStyledFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 13.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.black38,
              fontSize: 13,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF221A44).withValues(alpha: 0.8) : const Color(0xFFF8F7FF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF433575).withValues(alpha: 0.6) : const Color(0xFFDDD6FE),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.currentUser;

    final userName = user?.name ?? 'Apex Premier User';
    final userEmail = user?.email ?? 'user@apex888.com';
    final userPhone = user?.phone ?? '+91 98765 43210';
    final userId = user?.id ?? 'USR-888-9921';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0C20) : const Color(0xFFF7F7FD),
      body: SafeArea(
        child: Column(
          children: [
            // Dark Header Banner matching Dashboard & Chat tabs
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0C0720),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  if (context.canPop()) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D0D45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF3C2373),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF26105E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFFA78BFA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Player account and settings',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showLogoutDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D0D45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF3C2373),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. User Header & Avatar Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2128) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: isDark ? const Color(0xFF2C2F36) : const Color(0xFFF1F5F9),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Text(
                            'VIP',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.userAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PLAYER ACCOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.userAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: $userId',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showEditProfileDialog(context, userName, userEmail, userPhone),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, size: 12, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'EDIT PROFILE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Account Overview Metrics Cards
            Row(
              children: [
                _buildOverviewCard(
                  title: 'Wallet Balance',
                  value: _isLoadingBalance
                      ? '...'
                      : '₹${_successfulRechargeBalance.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFFFD700),
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildOverviewCard(
                  title: 'ID Orders',
                  value: _isLoadingBalance
                      ? '...'
                      : '$_successfulOrdersCount ${_successfulOrdersCount == 1 ? "Item" : "Items"}',
                  icon: Icons.sports_esports_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Read-Only Account Details Section
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2128) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.phone_rounded,
                    label: 'Phone Number',
                    value: userPhone,
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.email_rounded,
                    label: 'Email Address',
                    value: userEmail,
                    isDark: isDark,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.verified_user_rounded,
                    label: 'Account Status',
                    value: 'Active • KYC Verified',
                    isDark: isDark,
                    valueColor: AppColors.success,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Member Since',
                    value: 'August 2026',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Quick Actions (Support & Logout)
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Support Chat Action Button
            InkWell(
              onTap: () => _showGetInTouchSupportDialog(context, userName, userEmail, userPhone),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Support Helpdesk',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Chat live with customer support & recharge agent',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Update Password Action Button
            InkWell(
              onTap: () => _showUpdatePasswordDialog(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: Color(0xFFF97316), size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update Password',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF97316)),
                          ),
                          Text(
                            'Change your account security password',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFFF97316)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Delete Account Action Button
            InkWell(
              onTap: () => _showDeleteAccountDialog(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: Colors.red, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Account',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                          ),
                          Text(
                            'Permanently delete player account and data',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Logout Action Button
            InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logout',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                          ),
                          Text(
                            'Sign out of account on this device',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.error),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ],
  ),
),
);
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? (isDark ? Colors.grey[300] : Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
