import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfLib;
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class IdCardScannerScreen extends StatefulWidget {
  @override
  _IdCardScannerScreenState createState() => _IdCardScannerScreenState();
}

class _IdCardScannerScreenState extends State<IdCardScannerScreen> {
  File? _imageFile;
  String? _scannedText;
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _scannedText = null; // Reset scanned text when a new image is selected
        });
        await _processImage(_imageFile!);
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  Future<void> _processImage(File image) async {
    try {
      final text = await FlutterTesseractOcr.extractText(image.path);
      setState(() {
        _scannedText = text;
      });
      if (text != null) {
        await _generatePdf(text);
      }
    } catch (e) {
      _showError('An error occurred while processing image: $e');
    }
  }

  Future<void> _generatePdf(String text) async {
    final pdf = pdfLib.Document();
    pdf.addPage(
      pdfLib.Page(
        build: (context) {
          return pdfLib.Center(
            child: pdfLib.Text(text),
          );
        },
      ),
    );

    // Get the directory for storing PDF file
    final directory = await getApplicationDocumentsDirectory();
    final pdfPath = '${directory.path}/cnic_data.pdf';

    // Write PDF to file
    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());

    // Show PDF in app
    _showPdf(file);
  }

  void _showPdf(File file) {
    // Open PDF in the default viewer
    // Implement the logic to display PDF in the app
    // You can use a PDF viewer package or a WebView to display PDF
    // For simplicity, let's assume we have a function to open PDF in a viewer
    // displayPdf(file);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CNIC Scanner'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _imageFile == null
                  ? Text('No image selected')
                  : Image.file(_imageFile!),
            ),
          ),
          if (_scannedText != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _scannedText!,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _captureImage(ImageSource.camera),
            tooltip: 'Capture Image',
            child: Icon(Icons.camera),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _captureImage(ImageSource.gallery),
            tooltip: 'Upload from Gallery',
            child: Icon(Icons.image),
          ),
        ],
      ),
    );
  }
}
