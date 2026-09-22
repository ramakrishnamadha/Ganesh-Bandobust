import 'package:flutter/material.dart';

class IdolVerificationScreen extends StatefulWidget {
  final String applicationId;

  const IdolVerificationScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<IdolVerificationScreen> createState() =>
      _IdolVerificationScreenState();
}

class _IdolVerificationScreenState
    extends State<IdolVerificationScreen> {
  String idolInstalled = '';
  String purchaseVerified = '';
  String purchaseWithinPs = '';
  String dimensionsVerified = '';

  final TextEditingController heightController =
      TextEditingController();

  final TextEditingController widthController =
      TextEditingController();

  String material = '';
  String remarks = '';

  String errorMessage = '';
  String successMessage = '';

  @override
  void dispose() {
    heightController.dispose();
    widthController.dispose();
    super.dispose();
  }

  /* =========================================================
     SAVE VERIFICATION
  ========================================================= */

  void saveVerification() {
    setState(() {
      errorMessage = '';
      successMessage = '';
    });

    if (idolInstalled.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer: Idol Installed or Not?';
      });

      return;
    }

    if (idolInstalled == 'NO') {
      if (remarks.trim().isEmpty) {
        setState(() {
          errorMessage =
              'Reason / Remarks are mandatory when Idol Installed is NO.';
        });

        return;
      }

      setState(() {
        successMessage =
            'Saved as Idol Not Installed and marked for NO / Pending monitoring.';
      });

      return;
    }

    if (purchaseVerified.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer: Place of Purchase Verified?';
      });

      return;
    }

    if (purchaseVerified == 'NO' &&
        remarks.trim().isEmpty) {
      setState(() {
        errorMessage =
            'Reason / Remarks are mandatory when Place of Purchase is not verified.';
      });

      return;
    }

    if (purchaseWithinPs.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer: Place of Purchase Falls Within This PS Limits?';
      });

      return;
    }

    /*
      IMPORTANT:
      purchaseWithinPs = NO is allowed
      WITHOUT mandatory remarks.
    */

    if (dimensionsVerified.isEmpty) {
      setState(() {
        errorMessage =
            'Please answer: Idol Height, Width and Material Verified?';
      });

      return;
    }

    if (dimensionsVerified == 'NO') {
      if (remarks.trim().isEmpty) {
        setState(() {
          errorMessage =
              'Reason / Remarks are mandatory when Height, Width and Material are not verified.';
        });

        return;
      }

      setState(() {
        successMessage =
            'Idol verification saved with Height / Width / Material pending.';
      });

      return;
    }

    if (heightController.text.trim().isEmpty) {
      setState(() {
        errorMessage =
            'Please enter the Actual Height of Idol during field visit.';
      });

      return;
    }

    if (widthController.text.trim().isEmpty) {
      setState(() {
        errorMessage =
            'Please enter the Actual Width of Idol during field visit.';
      });

      return;
    }

    if (material.isEmpty) {
      setState(() {
        errorMessage =
            'Please select Idol Material.';
      });

      return;
    }

    setState(() {
      successMessage =
          'Idol-Based Verification saved successfully.';
    });
  }

  /* =========================================================
     YES / NO BUTTONS
  ========================================================= */

  Widget yesNoButtons({
    required String value,
    required void Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              onChanged('YES');
            },
            style: FilledButton.styleFrom(
              backgroundColor: value == 'YES'
                  ? Colors.green
                  : const Color(0xFFE2E8F0),
              foregroundColor: value == 'YES'
                  ? Colors.white
                  : Colors.black87,
            ),
            child: const Text('YES'),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: FilledButton(
            onPressed: () {
              onChanged('NO');
            },
            style: FilledButton.styleFrom(
              backgroundColor: value == 'NO'
                  ? Colors.red
                  : const Color(0xFFE2E8F0),
              foregroundColor: value == 'NO'
                  ? Colors.white
                  : Colors.black87,
            ),
            child: const Text('NO'),
          ),
        ),
      ],
    );
  }

  /* =========================================================
     BUILD
  ========================================================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Idol-Based Verification'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            /* APPLICATION DETAILS */

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Application ID',
                      style: TextStyle(
                        color:
                            Color(0xFF64748B),
                      ),
                    ),

                    Text(
                      widget.applicationId,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF17365D),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            /* =================================================
               POINT 1 — IDOL INSTALLED
            ================================================= */

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    const Text(
                      'Point 1 — Idol Installed or Not?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    yesNoButtons(
                      value: idolInstalled,

                      onChanged: (value) {
                        setState(() {
                          idolInstalled =
                              value;
                        });
                      },
                    ),

                    if (idolInstalled ==
                        'NO') ...[
                      const SizedBox(
                          height: 18),

                      const Text(
                        'NO-type Reason / Remarks *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        maxLines: 4,

                        onChanged: (value) {
                          remarks = value;
                        },

                        decoration:
                            const InputDecoration(
                          hintText:
                              'Enter reason why Idol is not installed',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Status will be recorded as Idol Not Installed.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (idolInstalled == 'YES') ...[
              const SizedBox(height: 14),

              /* =================================================
                 POINT 2 — PURCHASE VERIFIED
              ================================================= */

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      const Text(
                        'Point 2 — Place of Purchase Verified?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      yesNoButtons(
                        value: purchaseVerified,

                        onChanged: (value) {
                          setState(() {
                            purchaseVerified =
                                value;
                          });
                        },
                      ),

                      if (purchaseVerified ==
                          'NO') ...[
                        const SizedBox(
                            height: 18),

                        const Text(
                          'NO-type Reason / Remarks *',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          maxLines: 4,

                          onChanged: (value) {
                            remarks = value;
                          },

                          decoration:
                              const InputDecoration(
                            hintText:
                                'Enter reason',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /* =================================================
                 POINT 3 — PURCHASE WITHIN PS
              ================================================= */

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      const Text(
                        'Point 3 — Place of Purchase Falls Within This PS Limits?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      yesNoButtons(
                        value: purchaseWithinPs,

                        onChanged: (value) {
                          setState(() {
                            purchaseWithinPs =
                                value;
                          });
                        },
                      ),

                      if (purchaseWithinPs ==
                          'NO') ...[
                        const SizedBox(
                            height: 14),

                        Container(
                          padding:
                              const EdgeInsets
                                  .all(12),

                          decoration:
                              BoxDecoration(
                            color: const Color(
                                0xFFEFF6FF),
                            borderRadius:
                                BorderRadius
                                    .circular(10),
                          ),

                          child: const Text(
                            'Purchase location is outside this Police Station limits. This NO does not require mandatory NO-type remarks.',
                            style: TextStyle(
                              color:
                                  Color(
                                      0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /* =================================================
                 POINT 4 — HEIGHT / WIDTH / MATERIAL
              ================================================= */

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      const Text(
                        'Point 4 — Idol Height, Width and Material Verified?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      yesNoButtons(
                        value:
                            dimensionsVerified,

                        onChanged: (value) {
                          setState(() {
                            dimensionsVerified =
                                value;
                          });
                        },
                      ),

                      if (dimensionsVerified ==
                          'YES') ...[
                        const SizedBox(
                            height: 20),


                        /* MANUAL FIELD MEASUREMENTS */

                        TextField(
                          controller: heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText:
                                'Actual Height of Idol during field visit (ft.) *',
                            hintText: 'Enter height manually',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: widthController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText:
                                'Actual Width of Idol during field visit (ft.) *',
                            hintText: 'Enter width manually',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue:
                              material.isEmpty ? null : material,
                          decoration: const InputDecoration(
                            labelText: 'Material *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'CLAY',
                              child: Text('Clay'),
                            ),
                            DropdownMenuItem(
                              value: 'POP',
                              child: Text('POP'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              material = value ?? '';
                            });
                          },
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'The height and width entered by the officer during the field visit will be treated as the final field measurements for future reference.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                      if (dimensionsVerified ==
                          'NO') ...[
                        const SizedBox(
                            height: 18),

                        const Text(
                          'NO-type Reason / Remarks *',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          maxLines: 4,

                          onChanged: (value) {
                            remarks = value;
                          },

                          decoration:
                              const InputDecoration(
                            hintText:
                                'Enter reason',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            /* ERROR */

            if (errorMessage.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.all(12),

                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFFEE2E2),

                  borderRadius:
                      BorderRadius.circular(
                          10),
                ),

                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

            /* SUCCESS */

            if (successMessage.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.all(12),

                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFDCFCE7),

                  borderRadius:
                      BorderRadius.circular(
                          10),
                ),

                child: Text(
                  successMessage,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

            /* SAVE */

            FilledButton.icon(
              onPressed:
                  saveVerification,

              icon: const Icon(
                Icons.save_outlined,
              ),

              label: const Text(
                'Save Idol Verification',
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
