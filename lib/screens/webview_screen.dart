import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'login_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? controller;
  bool isLoading = true;
  bool hasError = false;
  String? currentApiKey;
  bool isInitialized = false;
  Set<String> handledPdfUrls = {}; // To prevent infinite loops

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Get API key for authenticated requests
      currentApiKey = await ApiService.getApiKey();

      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (!mounted) return;
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
            },
            onPageFinished: (String url) {
              if (!mounted) return;
              setState(() {
                isLoading = false;
              });
              print('Page finished: $url');
            },
            onWebResourceError: (WebResourceError error) {
              if (!mounted) return;
              setState(() {
                isLoading = false;
                hasError = true;
              });
              print('WebResource error: ${error.description}');
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;
              print('Navigation request: $url');

              // Check if the URL is a PDF file and hasn't been handled yet
              if (_isPdfUrl(url.toLowerCase()) && !handledPdfUrls.contains(url)) {
                handledPdfUrls.add(url); // Mark as handled to prevent loops
                _handlePdfNavigation(url);
                return NavigationDecision.prevent;
              }

              // Let all other requests proceed normally
              return NavigationDecision.navigate;
            },
          ),
        );

      // Load initial URL with API key if needed
      await _loadUrlWithAuth(widget.url);

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing WebView: $e');
      if (mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
          isInitialized = true;
        });
      }
    }
  }

  bool _isPdfUrl(String url) {
    // Check for PDF file extension
    if (url.endsWith('.pdf')) {
      return true;
    }

    // Check for PDF content type in URL parameters
    if (url.contains('content-type=application/pdf') ||
        url.contains('type=pdf') ||
        url.contains('.pdf?') ||
        url.contains('.pdf#')) {
      return true;
    }

    // Check for common PDF serving patterns
    if (url.contains('/pdf/') ||
        url.contains('viewpdf') ||
        url.contains('downloadpdf') ||
        url.contains('showpdf') ||
        (url.contains('report') && url.contains('pdf')) ||
        url.contains('/WebSrv/Fee/') && url.contains('.pdf')) {
      return true;
    }

    return false;
  }

  Future<void> _loadUrlWithAuth(String url) async {
    if (controller == null) return;

    if (currentApiKey != null && url.contains('fransalianhsjonai.ac.in')) {
      // For school domain URLs, add API key to headers
      await controller!.loadRequest(
        Uri.parse(url),
        headers: {
          'APIKey': currentApiKey!,
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
        },
      );
    } else {
      await controller!.loadRequest(Uri.parse(url));
    }
  }

  Future<void> _handlePdfNavigation(String pdfUrl) async {
    print('Handling PDF navigation: $pdfUrl');

    try {
      // Show immediate feedback
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Loading PDF...'),
      //       duration: Duration(seconds: 2),
      //       backgroundColor: Color(0xFF8ac63e),
      //     ),
      //   );
      // }

      // Try external launch first for better PDF handling
      bool launched = await _tryExternalPdfLaunch(pdfUrl);

      if (!launched) {
        // If external launch failed, load in WebView with Google Docs viewer
        await _loadPdfInWebView(pdfUrl);
      }
    } catch (e) {
      print('Error handling PDF: $e');
      // Final fallback - load directly in WebView
      if (controller != null) {
        await controller!.loadRequest(Uri.parse(pdfUrl));
      }
    }
  }

  Future<bool> _tryExternalPdfLaunch(String pdfUrl) async {
    try {
      final Uri pdfUri = Uri.parse(pdfUrl);

      if (await canLaunchUrl(pdfUri)) {
        await launchUrl(
          pdfUri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening PDF in external app...'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF8ac63e),
            ),
          );
        }
        return true;
      }
    } catch (e) {
      print('External PDF launch failed: $e');
    }
    return false;
  }

  Future<void> _loadPdfInWebView(String pdfUrl) async {
    if (controller == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Use Google Docs viewer for better PDF handling
      String viewerUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(pdfUrl)}';
      await controller!.loadRequest(Uri.parse(viewerUrl));

      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Loading PDF in viewer...'),
      //       duration: Duration(seconds: 2),
      //       backgroundColor: Color(0xFF8ac63e),
      //     ),
      //   );
      // }
    } catch (e) {
      print('PDF WebView loading failed: $e');
      // Direct load as last resort
      await controller!.loadRequest(Uri.parse(pdfUrl));
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
    if (controller == null) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });
    handledPdfUrls.clear(); // Clear handled URLs on refresh
    controller!.reload();
  }

  void _handleAutoLogout() {
    ApiService.logoutKeepApiKey();
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

  Future<bool> _onWillPop() async {
    if (controller != null && await controller!.canGoBack()) {
      controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
            backgroundColor: const Color(0xFF1b375c),
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
        ),
        body: Stack(
          children: [
            if (!isInitialized)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8ac63e)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1b375c),
                      ),
                    ),
                  ],
                ),
              )
            else if (hasError)
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
            else if (controller != null)
                WebViewWidget(controller: controller!),

            if (isLoading && isInitialized)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
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
                          color: Color(0xFF1b375c),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
