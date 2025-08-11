import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'login_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  bool hasError = false;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String downloadFileName = '';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
            });

            print('Page started: $url');

            // Check for logout URLs
            if (url.contains('/mob_start.aspx') ||
                url.contains('/logout') ||
                url.endsWith('/x') ||
                url.endsWith('/X') ||
                url.toLowerCase().contains('/x9f4xf')) {
              _handleAutoLogout();
            }

            // Check if URL is a direct file download
            if (_isDownloadableFile(url)) {
              _downloadFile(url);
              return;
            }
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check if the request is for a downloadable file
            if (_isDownloadableFile(request.url)) {
              _downloadFile(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      if (await Permission.storage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  bool _isDownloadableFile(String url) {
    // List of file extensions that should be downloaded
    final downloadableExtensions = [
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.txt', '.csv', '.zip', '.rar', '.jpg', '.jpeg', '.png', '.gif',
      '.mp4', '.mp3', '.avi', '.mov', '.wav'
    ];

    String lowerUrl = url.toLowerCase();
    return downloadableExtensions.any((ext) => lowerUrl.contains(ext));
  }

  String _getFileExtension(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      return path.substring(path.lastIndexOf('.')).toLowerCase();
    } catch (e) {
      return '';
    }
  }

  String _getFileName(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      String fileName = path.substring(path.lastIndexOf('/') + 1);
      if (fileName.isEmpty) {
        String extension = _getFileExtension(url);
        fileName = 'download_${DateTime.now().millisecondsSinceEpoch}$extension';
      }
      return fileName;
    } catch (e) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<String> _getDownloadPath() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Try to get the Downloads directory
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    return directory?.path ?? '';
  }

  Future<void> _downloadFile(String url) async {
    try {
      setState(() {
        isDownloading = true;
        downloadProgress = 0.0;
        downloadFileName = _getFileName(url);
      });

      String downloadPath = await _getDownloadPath();
      String filePath = '$downloadPath/$downloadFileName';

      // Create Dio instance for downloading
      Dio dio = Dio();

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        isDownloading = false;
        downloadProgress = 0.0;
      });

      // Show success message and option to open file
      _showDownloadCompleteDialog(filePath);

    } catch (e) {
      setState(() {
        isDownloading = false;
        downloadProgress = 0.0;
      });

      _showErrorDialog('Download failed: ${e.toString()}');
    }
  }

  void _showDownloadCompleteDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Complete'),
          content: Text('File downloaded successfully: $downloadFileName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openFile(filePath);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8ac63e),
                foregroundColor: Colors.white,
              ),
              child: const Text('Open File'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        // If can't open with default app, show message
        _showErrorDialog('No app found to open this file type');
      }
    } catch (e) {
      _showErrorDialog('Error opening file: ${e.toString()}');
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ApiService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _handleRefresh() {
    controller.reload();
  }

  void _handleAutoLogout() {
    // Clear everything except API key
    ApiService.logoutKeepApiKey();

    // Navigate to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  void _fallbackToLogin() {
    ApiService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          title: const Text('Reality Public School'),
          foregroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
        ),
      ),
      body: Stack(
        children: [
          if (hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load page',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your internet connection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _handleRefresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8ac63e),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _fallbackToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: controller),

          // Loading indicator
          if (isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8ac63e)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Download progress indicator
          if (isDownloading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.download,
                          size: 48,
                          color: Color(0xFF8ac63e),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Downloading: $downloadFileName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: downloadProgress,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8ac63e)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(downloadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
