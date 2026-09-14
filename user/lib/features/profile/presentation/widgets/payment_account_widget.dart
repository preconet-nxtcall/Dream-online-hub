import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/payment_account_repository.dart';
import '../../../../storage/local_storage_repository.dart';
import '../../../../storage/secure_storage_service.dart';

class PaymentAccountWidget extends StatefulWidget {
  final PaymentAccountRepository? repository;
  final dynamic userId;
  final bool isReadOnly;
  final bool isPendingApproval;
  final VoidCallback? onClose;

  const PaymentAccountWidget({
    super.key,
    this.repository,
    this.userId,
    this.isReadOnly = false,
    this.isPendingApproval = false,
    this.onClose,
  });

  @override
  State<PaymentAccountWidget> createState() => _PaymentAccountWidgetState();
}

class _PaymentAccountWidgetState extends State<PaymentAccountWidget> {
  late final PaymentAccountRepository _repository;

  final _accountNameCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _ifscCodeCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();

  File? _selectedImageFile;
  String? _existingImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  late bool _isEditing;
  late bool _isPendingApproval;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditing = !widget.isReadOnly;
    _isPendingApproval = widget.isPendingApproval;
    _repository = widget.repository ?? PaymentAccountRepositoryImpl();
    _loadPaymentAccount();
  }

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _accountNoCtrl.dispose();
    _bankNameCtrl.dispose();
    _ifscCodeCtrl.dispose();
    _upiIdCtrl.dispose();
    super.dispose();
  }

  Future<dynamic> _resolveUserId() async {
    if (widget.userId != null && widget.userId.toString().trim().isNotEmpty) {
      return widget.userId.toString().trim();
    }

    // 1. Fetch dynamically from active AuthProvider session
    try {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final user = authProv.currentUser;
      if (user?.id != null && user!.id.trim().isNotEmpty) {
        return user.id.trim();
      }
    } catch (_) {}

    // 2. Fetch dynamically from local Hive storage cache
    final currentUser = LocalStorageRepositoryImpl().getUser();
    if (currentUser?.id != null && currentUser!.id.trim().isNotEmpty) {
      return currentUser.id.trim();
    }

    // 3. Fetch dynamically from secure storage
    final storedUserId = await SecureStorageService().read(StorageKeys.userId);
    if (storedUserId != null && storedUserId.trim().isNotEmpty) {
      return storedUserId.trim();
    }

    return null;
  }

  Future<void> _loadPaymentAccount() async {
    setState(() => _isLoading = true);
    try {
      final userId = await _resolveUserId();
      final account = await _repository.getPaymentAccount(userId);

      if (mounted && account != null) {
        setState(() {
          _accountNameCtrl.text = account.accountName;
          _accountNoCtrl.text = account.accountNo;
          _bankNameCtrl.text = account.bankName;
          _ifscCodeCtrl.text = account.ifscCode;
          _upiIdCtrl.text = account.upiId;
          _existingImageUrl = account.image;
          _isPendingApproval = account.isPendingApproval;
          _isLoading = false;
        });
      } else if (mounted) {
        // Default prefill account holder name from current user model
        final currentUser = LocalStorageRepositoryImpl().getUser();
        if (currentUser?.name != null && currentUser!.name.isNotEmpty) {
          _accountNameCtrl.text = currentUser.name;
        }
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    if (_isPendingApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot update your payment account detail while approval is pending.'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _clearSelectedImage() {
    if (!_isEditing) return;
    if (_isPendingApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot update your payment account detail while approval is pending.'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _selectedImageFile = null;
    });
  }

  Future<void> _savePaymentAccount() async {
    if (_isPendingApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('You cannot update your payment account detail while approval is pending.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final accountName = _accountNameCtrl.text.trim();
    final accountNo = _accountNoCtrl.text.trim();
    final bankName = _bankNameCtrl.text.trim();
    final ifscCode = _ifscCodeCtrl.text.trim();
    final upiId = _upiIdCtrl.text.trim();
    final hasImage = _selectedImageFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    String? missingFieldMessage;
    if (accountName.isEmpty) {
      missingFieldMessage = 'Please enter Account Holder Name.';
    } else if (accountNo.isEmpty) {
      missingFieldMessage = 'Please enter Account Number.';
    } else if (bankName.isEmpty) {
      missingFieldMessage = 'Please enter Bank Name.';
    } else if (ifscCode.isEmpty) {
      missingFieldMessage = 'Please enter IFSC Code.';
    } else if (upiId.isEmpty) {
      missingFieldMessage = 'Please enter UPI ID.';
    } else if (!hasImage) {
      missingFieldMessage = 'Please choose a QR Code or Passbook Image.';
    }

    if (missingFieldMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(missingFieldMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await _resolveUserId();
      String? imageBase64;

      if (_selectedImageFile != null && await _selectedImageFile!.exists()) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final ext = _selectedImageFile!.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : (ext == 'jpg' || ext == 'jpeg' ? 'jpeg' : 'png');
        imageBase64 = 'data:image/$mimeType;base64,${base64Encode(bytes)}';
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        imageBase64 = _existingImageUrl;
      }

      final success = await _repository.updatePaymentAccount(
        userId: userId,
        accountName: accountName,
        accountNo: accountNo,
        ifscCode: ifscCode,
        bankName: bankName,
        upiId: upiId,
        imageBase64: imageBase64,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        if (success && imageBase64 != null) {
          _existingImageUrl = imageBase64;
          _isEditing = false; // Return to clean view mode after successful save
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Payment Account details saved successfully!'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save Payment Account details. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving account details: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const isDark = true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF070D22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0066FF).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Accent Line
          Container(
            height: 3.5,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0066FF), Color(0xFF00B2FF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Blue Shield Badge & Subtitle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0077FF), Color(0xFF0044CE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Update Payment Account' : 'Payment Account Details',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _isEditing
                                ? 'Modify saved bank, IFSC & UPI payout info'
                                : 'Saved bank & UPI payout details for withdrawals',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF97316)),
                      )
                    else if (widget.onClose != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: widget.onClose,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isPendingApproval
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isPendingApproval
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                : const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPendingApproval ? Icons.hourglass_top_rounded : Icons.verified_rounded,
                              size: 11,
                              color: _isPendingApproval ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _isPendingApproval ? 'PENDING APPROVAL' : 'VERIFIED',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: _isPendingApproval ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_isPendingApproval) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You cannot update your payment account detail while approval is pending.',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Form Fields (Responsive Grid)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 480;

                    return Column(
                      children: [
                        // Row 1: ACCOUNT HOLDER NAME & ACCOUNT NUMBER
                        if (isWide) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'ACCOUNT HOLDER NAME',
                                  controller: _accountNameCtrl,
                                  hint: 'FG',
                                  icon: Icons.person_outline_rounded,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  label: 'ACCOUNT NUMBER',
                                  controller: _accountNoCtrl,
                                  hint: 'Enter account number',
                                  icon: Icons.credit_card_outlined,
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ] else ...[
                          _buildInputField(
                            label: 'ACCOUNT HOLDER NAME',
                            controller: _accountNameCtrl,
                            hint: 'FG',
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildInputField(
                            label: 'ACCOUNT NUMBER',
                            controller: _accountNoCtrl,
                            hint: 'Enter account number',
                            icon: Icons.credit_card_outlined,
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Row 2: BANK NAME & IFSC CODE
                        if (isWide) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'BANK NAME',
                                  controller: _bankNameCtrl,
                                  hint: 'Enter bank name',
                                  icon: Icons.account_balance_outlined,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  label: 'IFSC CODE',
                                  controller: _ifscCodeCtrl,
                                  hint: 'Enter IFSC code',
                                  icon: Icons.edit_outlined,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ] else ...[
                          _buildInputField(
                            label: 'BANK NAME',
                            controller: _bankNameCtrl,
                            hint: 'Enter bank name',
                            icon: Icons.account_balance_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildInputField(
                            label: 'IFSC CODE',
                            controller: _ifscCodeCtrl,
                            hint: 'Enter IFSC code',
                            icon: Icons.edit_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Row 3: UPI ID & QR CODE / PASSBOOK IMAGE
                        if (isWide) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'UPI ID',
                                  controller: _upiIdCtrl,
                                  hint: 'Enter UPI ID (e.g. name@upi)',
                                  icon: Icons.mail_outline_rounded,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFileUploadField(isDark: isDark),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildInputField(
                            label: 'UPI ID',
                            controller: _upiIdCtrl,
                            hint: 'Enter UPI ID (e.g. name@upi)',
                            icon: Icons.mail_outline_rounded,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildFileUploadField(isDark: isDark),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Button Action: "Save Payment Account" for Update mode, or "Close Details" for Read-Only mode
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _isEditing
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: _isPendingApproval
                                ? const LinearGradient(
                                    colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFF0077FF), Color(0xFF0044CE)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (_isPendingApproval ? const Color(0xFF6B7280) : const Color(0xFF0066FF)).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: (_isSaving || _isPendingApproval) ? null : _savePaymentAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isSaving)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                else
                                  Icon(
                                    _isPendingApproval ? Icons.lock_rounded : Icons.save_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _isSaving ? 'Saving...' : 'Save Payment Account',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onClose != null) {
                              widget.onClose!();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Close Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadowColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool isFieldEnabled = _isEditing && !_isPendingApproval;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00B2FF),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: !isFieldEnabled,
          enabled: isFieldEnabled,
          cursorColor: const Color(0xFF00B2FF),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: const Color(0xFF050B1E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            suffixIcon: Icon(
              icon,
              color: const Color(0xFF00B2FF),
              size: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00B2FF),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImagePreviewDialog() {
    if (_selectedImageFile != null) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Passbook / QR Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.file(_selectedImageFile!, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      final imgUrl = _existingImageUrl!;
      Widget imgWidget;
      if (imgUrl.startsWith('data:image')) {
        try {
          final base64Str = imgUrl.split(',').last;
          final bytes = base64Decode(base64Str);
          imgWidget = Image.memory(bytes, fit: BoxFit.contain);
        } catch (_) {
          imgWidget = const Icon(Icons.broken_image_rounded, color: Colors.white, size: 48);
        }
      } else {
        imgWidget = Image.network(
          imgUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white, size: 48),
        );
      }

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Passbook / QR Image Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: InteractiveViewer(
                    child: imgWidget,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFileUploadField({required bool isDark}) {
    final hasNewFile = _selectedImageFile != null;
    final hasExistingFile = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    final fileName = hasNewFile
        ? _selectedImageFile!.path.split(Platform.pathSeparator).last
        : (hasExistingFile
            ? 'Passbook / QR Image Attached'
            : 'No file chosen');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'QR CODE / PASSBOOK IMAGE',
              style: TextStyle(
                color: Color(0xFF00B2FF),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 3),
            Text(
              '*',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: _isEditing ? _pickImage : (hasExistingFile ? _showImagePreviewDialog : null),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF050B1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (hasNewFile || hasExistingFile)
                    ? const Color(0xFF0066FF).withValues(alpha: 0.6)
                    : const Color(0xFF0066FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Choose File Button Box matching screenshot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A183C),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 13,
                        color: Color(0xFF00B2FF),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Choose File',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B2FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: (hasNewFile || hasExistingFile) ? FontWeight.w600 : FontWeight.normal,
                      color: (hasNewFile || hasExistingFile)
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                if (hasNewFile) ...[
                  const SizedBox(width: 6),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.file(
                          _selectedImageFile!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isEditing)
                        GestureDetector(
                          onTap: _clearSelectedImage,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 9, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ] else if (hasExistingFile) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _showImagePreviewDialog,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_red_eye_outlined, color: Color(0xFFF97316), size: 16),
                        SizedBox(width: 3),
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
