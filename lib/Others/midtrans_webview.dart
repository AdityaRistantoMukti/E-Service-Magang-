import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class MidtransWebView extends StatefulWidget {
  final String redirectUrl;
  final String orderId;
  final Function(String)? onTransactionFinished;

  const MidtransWebView({
    Key? key,
    required this.redirectUrl,
    required this.orderId,
    this.onTransactionFinished,
  }) : super(key: key);

  @override
  State<MidtransWebView> createState() => _MidtransWebViewState();
}

class _MidtransWebViewState extends State<MidtransWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🌐 [MidtransWebView] Initializing with URL: ${widget.redirectUrl}');
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('📄 [MidtransWebView] Page started: $url');
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            debugPrint('✅ [MidtransWebView] Page finished: $url');
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _checkForPaymentResult(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🔗 [MidtransWebView] Navigation: ${request.url}');

            // Check if this is a callback/finish URL
            if (_isCallbackUrl(request.url)) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ [MidtransWebView] Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  bool _isCallbackUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('/finish') ||
           lowerUrl.contains('/callback') ||
           lowerUrl.contains('transaction_status=') ||
           lowerUrl.contains('status_code=200') ||
           lowerUrl.contains('status_code=201') ||
           (lowerUrl.contains('order_id=') && lowerUrl.contains('status'));
  }

  void _checkForPaymentResult(String url) {
    if (_hasFinished) return;

    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    debugPrint('🔍 [MidtransWebView] Checking URL params: $params');

    // Check for transaction_status in URL
    if (params.containsKey('transaction_status')) {
      final status = params['transaction_status']!;
      debugPrint('💳 [MidtransWebView] Found transaction_status: $status');
      _finishWithStatus(status);
    }
    // Check for status_code
    else if (params.containsKey('status_code')) {
      final statusCode = params['status_code']!;
      debugPrint('💳 [MidtransWebView] Found status_code: $statusCode');
      if (statusCode == '200' || statusCode == '201') {
        _finishWithStatus('success');
      } else if (statusCode == '201') {
        _finishWithStatus('pending');
      }
    }
  }

  void _handleCallback(String url) {
    if (_hasFinished) return;

    debugPrint('🏁 [MidtransWebView] Handling callback URL: $url');

    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    String status = 'unknown';

    // Parse status from URL params
    if (params.containsKey('transaction_status')) {
      status = params['transaction_status']!;
    } else if (params.containsKey('status_code')) {
      final statusCode = params['status_code'];
      if (statusCode == '200') {
        status = 'success';
      } else if (statusCode == '201') {
        status = 'pending';
      } else {
        status = 'error';
      }
    } else if (url.toLowerCase().contains('success') || url.toLowerCase().contains('finish')) {
      status = 'success';
    } else if (url.toLowerCase().contains('pending')) {
      status = 'pending';
    } else if (url.toLowerCase().contains('error') || url.toLowerCase().contains('failure')) {
      status = 'error';
    }

    _finishWithStatus(status);
  }

  void _finishWithStatus(String status) {
    if (_hasFinished) return;
    _hasFinished = true;

    // Normalize status
    String normalizedStatus;
    switch (status.toLowerCase()) {
      case 'capture':
      case 'settlement':
      case 'success':
        normalizedStatus = 'success';
        break;
      case 'pending':
      case 'challenge':
        normalizedStatus = 'pending';
        break;
      case 'deny':
      case 'cancel':
      case 'expire':
      case 'failure':
      case 'error':
        normalizedStatus = 'cancel';
        break;
      default:
        normalizedStatus = status;
    }

    debugPrint('💰 [MidtransWebView] Finishing with status: $normalizedStatus');

    widget.onTransactionFinished?.call(normalizedStatus);

    // Close dialog and return result
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(normalizedStatus);
    }
  }

  void _cancelPayment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Batalkan Pembayaran?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pembayaran ini?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Tidak', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finishWithStatus('cancel');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Ya, Batalkan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      child: WillPopScope(
        onWillPop: () async {
          _cancelPayment();
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0041c3),
            title: Text(
              'Pembayaran',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _cancelPayment,
            ),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF0041c3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat halaman pembayaran...',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
