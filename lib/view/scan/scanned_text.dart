import 'package:flutter/material.dart';
import '../../constants/styles.dart';
import 'package:readit/widget/button_widget.dart';
import '../../viewmodel/scanned_viewmodel.dart';

class ScannedText extends StatefulWidget {
  final String extractedText;

  const ScannedText({super.key, required this.extractedText});

  @override
  State<ScannedText> createState() => _ScannedTextState();
}

class _ScannedTextState extends State<ScannedText> {
  late final ScannedTextViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ScannedTextViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bg,
      appBar: null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text("Scanned Text", style: AppStyles.titleStyle),
            ),
            const SizedBox(height: 20),
            widget.extractedText.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                          color: const Color(0x60414040),
                          borderRadius: BorderRadius.circular(16.0)),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.extractedText,
                          style: AppStyles.subTextSecondary
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Copy Text",
              onTap: () {
                viewModel.copyTextToClipboard(
                  context: context,
                  text: widget.extractedText,
                );
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Save to History",
              onTap: () {
                viewModel
                    .saveToFirebase(widget.extractedText, "Manual Save")
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Text saved to history!")),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error saving: $error")),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
