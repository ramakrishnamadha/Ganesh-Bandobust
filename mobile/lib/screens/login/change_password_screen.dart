import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String employeeId;
  final String currentPassword;

  const ChangePasswordScreen({
    super.key,
    required this.employeeId,
    required this.currentPassword,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  bool isSubmitting = false;

  String errorMessage = '';

  Future<void> changePassword() async {
    if (isSubmitting) {
      return;
    }

    final newPassword =
        newPasswordController.text;

    final confirmPassword =
        confirmPasswordController.text;

    if (newPassword.isEmpty) {
      setState(() {
        errorMessage =
            'New password is required.';
      });
      return;
    }

    if (newPassword.length < 8) {
      setState(() {
        errorMessage =
            'New password must contain at least 8 characters.';
      });
      return;
    }

    if (newPassword ==
        widget.currentPassword) {
      setState(() {
        errorMessage =
            'New password must be different from the current password.';
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        errorMessage =
            'Confirm password is required.';
      });
      return;
    }

    if (newPassword !=
        confirmPassword) {
      setState(() {
        errorMessage =
            'New password and confirm password do not match.';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = '';
    });

    final result =
        await AuthService.changePassword(
      currentPassword:
          widget.currentPassword,
      newPassword:
          newPassword,
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      setState(() {
        isSubmitting = false;

        errorMessage =
            result.error ??
            'Unable to change password.';
      });

      return;
    }

    setState(() {
      isSubmitting = false;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Password Changed',
          ),
          content: Text(
            result.message ??
                'Password changed successfully. Please login again with your new password.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    /*
     * Clear the in-memory Mobile session.
     * User must login again using the
     * newly created password.
     */
    AuthService.clearSession();

    Navigator.of(context).pop(
      true,
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
        ),
        automaticallyImplyLeading:
            false,
      ),
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 430,
              ),
              child: Card(
                elevation: 6,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      const Icon(
                        Icons
                            .lock_reset_outlined,
                        size: 54,
                        color:
                            Color(
                          0xFF17365D,
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      const Text(
                        'Set New Password',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'For security, you must change the default password before continuing.',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFF64748B,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFF1F5F9,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .badge_outlined,
                              color:
                                  Color(
                                0xFF17365D,
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                'Employee ID: ${widget.employeeId}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      TextField(
                        controller:
                            newPasswordController,
                        enabled:
                            !isSubmitting,
                        obscureText:
                            obscureNewPassword,
                        textInputAction:
                            TextInputAction.next,
                        decoration:
                            InputDecoration(
                          labelText:
                              'New Password',
                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline,
                          ),
                          suffixIcon:
                              IconButton(
                            onPressed:
                                isSubmitting
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            obscureNewPassword =
                                                !obscureNewPassword;
                                          },
                                        );
                                      },
                            icon: Icon(
                              obscureNewPassword
                                  ? Icons
                                      .visibility_off
                                  : Icons
                                      .visibility,
                            ),
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      TextField(
                        controller:
                            confirmPasswordController,
                        enabled:
                            !isSubmitting,
                        obscureText:
                            obscureConfirmPassword,
                        textInputAction:
                            TextInputAction.done,
                        onSubmitted: (_) {
                          changePassword();
                        },
                        decoration:
                            InputDecoration(
                          labelText:
                              'Confirm New Password',
                          prefixIcon:
                              const Icon(
                            Icons
                                .verified_user_outlined,
                          ),
                          suffixIcon:
                              IconButton(
                            onPressed:
                                isSubmitting
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            obscureConfirmPassword =
                                                !obscureConfirmPassword;
                                          },
                                        );
                                      },
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons
                                      .visibility_off
                                  : Icons
                                      .visibility,
                            ),
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      if (errorMessage
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 14,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFFEF2F2,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: Text(
                            errorMessage,
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFFB91C1C,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 24,
                      ),

                      SizedBox(
                        height: 52,
                        child:
                            FilledButton(
                          onPressed:
                              isSubmitting
                                  ? null
                                  : changePassword,
                          style:
                              FilledButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF17365D,
                            ),
                          ),
                          child:
                              isSubmitting
                                  ? const SizedBox(
                                      width:
                                          24,
                                      height:
                                          24,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.5,
                                        color:
                                            Colors
                                                .white,
                                      ),
                                    )
                                  : const Text(
                                      'CHANGE PASSWORD',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      const Text(
                        'Minimum 8 characters',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              Color(
                            0xFF64748B,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}