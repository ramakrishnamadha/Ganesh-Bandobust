import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/live_tracking_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'change_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoggingIn = false;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() {
      isLoggingIn = true;
    });

    final AuthenticatedUser? user = await AuthService.restoreSession();
    if (user != null) {
      await _onLoginSuccess(user);
    } else {
      if (mounted) {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  Future<void> login() async {
    if (isLoggingIn) {
      return;
    }

    final String employeeId =
        usernameController.text.trim();

    final String password =
        passwordController.text;

    if (employeeId.isEmpty) {
      setState(() {
        errorMessage = 'Employee ID is required.';
      });

      return;
    }

    if (password.isEmpty) {
      setState(() {
        errorMessage = 'Password is required.';
      });

      return;
    }

    setState(() {
      isLoggingIn = true;
      errorMessage = '';
    });

    final LoginResult loginResult =
        await AuthService.login(
      employeeId: employeeId,
      password: password,
    );

    if (!mounted) {
      return;
    }

    if (!loginResult.success ||
        loginResult.user == null) {
      setState(() {
        isLoggingIn = false;

        errorMessage =
            loginResult.error ?? 'Unable to login.';
      });

      return;
    }

    final AuthenticatedUser user =
        loginResult.user!;

    /*
     * FIRST LOGIN PASSWORD CHANGE
     *
     * The common authentication API has already
     * created the login session.
     *
     * AuthService has captured the session cookie.
     * Therefore the password-change screen can use
     * the same authenticated session.
     */
    if (loginResult.requiresPasswordChange) {
      setState(() {
        isLoggingIn = false;
      });

      final bool? passwordChanged =
          await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (
            BuildContext context,
          ) {
            return ChangePasswordScreen(
              employeeId: employeeId,
              currentPassword: password,
            );
          },
        ),
      );

      if (!mounted) {
        return;
      }

      if (passwordChanged == true) {
        passwordController.clear();

        setState(() {
          errorMessage =
              'Password changed successfully. '
              'Please login with your new password.';
        });
      }

      return;
    }

    await AuthService.persistSession();
    await _onLoginSuccess(user);
  }

  Future<void> _onLoginSuccess(AuthenticatedUser user) async {
    /*
     * AUTHENTICATED USER PROFILE
     *
     * These values are taken from the common
     * User Master returned by the API.
     */
    final String officerName =
        user.officerName.isNotEmpty
            ? user.officerName
            : user.username;


    final String role = user.role;

    final String rank = user.rank;

    final String policeStation =
        user.policeStationName ?? '';

    final String sector =
        user.sectorName ?? '';

    /*
     * Some imported users do not yet have the
     * official commissionerate code populated.
     *
     * LiveTrackingService requires a non-null
     * commissionerateCode.
     *
     * HYD is therefore retained as the temporary
     * fallback until the official hierarchy master
     * is connected.
     */
    final String commissionerateCode =
        user.commissionerateCode ?? 'HYD';

    bool trackingSessionCreated = false;
    bool gpsTrackingStarted = false;

    /*
     * CREATE LIVE TRACKING SESSION
     */
    try {
      trackingSessionCreated =
          await LiveTrackingService.instance
              .createTrackingSession(
        userId: user.id,
        userName: officerName,
        role: role,
        rank: rank,
        policeStation: policeStation,
        sector: sector,
        commissionerateCode:
            commissionerateCode,
        rangeCode: user.rangeCode,
        zoneCode: user.zoneCode,
        divisionCode: user.divisionCode,
        deviceId: null,
        deviceName: 'Samsung S22',
        manufacturer: 'Samsung',
        model: 'SM-S901E',
        platform: 'ANDROID',
        osVersion: '16',
        appVersion: '1.0.0',
      );

      /*
       * START GPS TRACKING
       */
      if (trackingSessionCreated) {
        gpsTrackingStarted =
            await LiveTrackingService.instance
                .startTracking(
          interval: const Duration(
            seconds: 30,
          ),
        );
      }
    } catch (_) {
      trackingSessionCreated = false;
      gpsTrackingStarted = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isLoggingIn = false;
    });

    /*
     * Tracking failure should not prevent an
     * authenticated officer from opening the app.
     */
    if (!trackingSessionCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login successful. '
            'Live tracking session could not be started.',
          ),
        ),
      );
    } else if (!gpsTrackingStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login successful. '
            'GPS tracking is unavailable. '
            'Please check location permission and GPS.',
          ),
        ),
      );
    }

    /*
     * OPEN OFFICER DASHBOARD
     */
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (
          BuildContext context,
        ) {
          return DashboardScreen(
            officerName: officerName,
            role: role,
            policeStation: policeStation,
            sector: sector,
            authenticatedUser: user,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Card(
                elevation: 8,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),
                child: Column(
                  children: [
                    /*
                     * HEADER
                     */
                    Container(
                      width: double.infinity,
                      color: const Color(
                        0xFF17365D,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 34,
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.local_police,
                            size: 48,
                            color: Colors.white,
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            'OFFICIAL USE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            'GANESH FESTIVAL',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          Text(
                            'BANDOBUST MANAGEMENT SYSTEM',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Officer Mobile Application',
                            style: TextStyle(
                              color: Color(
                                0xFFBFDBFE,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /*
                     * LOGIN FORM
                     */
                    Padding(
                      padding: const EdgeInsets.all(
                        26,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          const Text(
                            'Official Login',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          const Text(
                            'Authorized officers only',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Color(
                                0xFF64748B,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),

                          /*
                           * EMPLOYEE ID
                           */
                          TextField(
                            controller:
                                usernameController,
                            enabled:
                                !isLoggingIn,
                            keyboardType:
                                TextInputType.number,
                            textInputAction:
                                TextInputAction.next,
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Employee ID',
                              prefixIcon:
                                  const Icon(
                                Icons.badge_outlined,
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

                          /*
                           * PASSWORD
                           */
                          TextField(
                            controller:
                                passwordController,
                            enabled:
                                !isLoggingIn,
                            obscureText:
                                obscurePassword,
                            textInputAction:
                                TextInputAction.done,
                            onSubmitted: (_) {
                              login();
                            },
                            decoration:
                                InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(
                                Icons.lock_outline,
                              ),
                              suffixIcon:
                                  IconButton(
                                onPressed:
                                    isLoggingIn
                                        ? null
                                        : () {
                                            setState(
                                              () {
                                                obscurePassword =
                                                    !obscurePassword;
                                              },
                                            );
                                          },
                                icon: Icon(
                                  obscurePassword
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

                          /*
                           * ERROR / INFORMATION MESSAGE
                           */
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
                                  color: Color(
                                    0xFFB91C1C,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(
                            height: 24,
                          ),

                          /*
                           * LOGIN BUTTON
                           */
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed:
                                  isLoggingIn
                                      ? null
                                      : login,
                              style:
                                  FilledButton
                                      .styleFrom(
                                backgroundColor:
                                    const Color(
                                  0xFF17365D,
                                ),
                              ),
                              child:
                                  isLoggingIn
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2.5,
                                            color:
                                                Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'LOGIN',
                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          const Text(
                            'Login with your official Employee ID',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(
                                0xFF64748B,
                              ),
                            ),
                          ),
                        ],
                      ),
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