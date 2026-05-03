import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/payment_service.dart';

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'\s+\b|\b\s'), '');
    if (text.length > 16) text = text.substring(0, 16);

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 4) text = text.substring(0, 4);

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) buffer.write(' / ');
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class PaymentCheckoutSheet extends StatefulWidget {
  final Map<String, dynamic> plan;
  const PaymentCheckoutSheet({super.key, required this.plan});

  @override
  State<PaymentCheckoutSheet> createState() => _PaymentCheckoutSheetState();
}

class _PaymentCheckoutSheetState extends State<PaymentCheckoutSheet> {
  bool _isAddingNewCard = false;
  bool _isLoading = false;
  bool _saveInfo = true;
  String _selectedMethod = 'apple_pay';

  String? _savedCardLast4;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCard();
  }

  Future<void> _loadSavedCard() async {
    final savedLast4 = await _storage.read(key: 'saved_card_last4');
    if (savedLast4 != null && savedLast4.isNotEmpty) {
      setState(() {
        _savedCardLast4 = savedLast4;
        _selectedMethod = 'saved';
      });
    }
  }

  bool _isValidExpiryDate(String expiry) {
    if (expiry.length < 7) return false;
    final parts = expiry.split(' / ');
    if (parts.length != 2) return false;
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null || month < 1 || month > 12) return false;

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return false;
    }
    return true;
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_isAddingNewCard) {
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiry = _expiryController.text.trim();
      final cvc = _cvcController.text.trim();

      if (cardNumber.isEmpty || expiry.isEmpty || cvc.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill all card details.';
          _isLoading = false;
        });
        return;
      }
      if (cardNumber.length < 15) {
        setState(() {
          _errorMessage = 'Invalid card number length.';
          _isLoading = false;
        });
        return;
      }
      if (!_isValidExpiryDate(expiry)) {
        setState(() {
          _errorMessage = 'Invalid or expired card date.';
          _isLoading = false;
        });
        return;
      }
      if (cvc.length < 3) {
        setState(() {
          _errorMessage = 'Invalid CVC.';
          _isLoading = false;
        });
        return;
      }
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      const paymentMethodId = 'pm_card_visa';

      final String actualPriceId = widget.plan['priceId'];
      final isCurrentlyPro = PaymentService.subscriptionSuccessNotifier.isPro;

      await PaymentService.registerStripeCustomer(paymentMethodId);

      if (isCurrentlyPro) {
        await PaymentService.updateSubscription(actualPriceId);
      } else {
        await PaymentService.createSubscription(actualPriceId);
      }

      
      PaymentService.subscriptionSuccessNotifier.setOptimisticPro(
        actualPriceId,
      );

      if (_isAddingNewCard && _saveInfo) {
        final cardNumber = _cardNumberController.text.replaceAll(' ', '');
        final last4 = cardNumber.substring(cardNumber.length - 4);
        await _storage.write(key: 'saved_card_last4', value: last4);
      }

      if (mounted) Navigator.pop(context);
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Payment failed'),
            backgroundColor: AppColors.anger,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.paymentDialogBg.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Purchase successful',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You have successfully completed your order',
                  style: TextStyle(color: AppColors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.iOSBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Ok, got it',
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paymentLightBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isAddingNewCard ? _buildAddCardUI() : _buildSelectorUI(),
      ),
    );
  }

  Widget _buildSelectorUI() {
    return SingleChildScrollView(
      key: const ValueKey('selector'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.black54, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _selectedMethod = 'apple_pay'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.pureBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedMethod == 'apple_pay'
                      ? AppColors.iOSBlue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apple, color: AppColors.whiteSmoke, size: 24),
                  SizedBox(width: 4),
                  Text(
                    'Pay',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedMethod = 'link'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.successGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedMethod == 'link'
                      ? AppColors.iOSBlue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pay with ',
                    style: TextStyle(
                      color: AppColors.pureBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.link, color: AppColors.pureBlack, size: 24),
                  Text(
                    'link',
                    style: TextStyle(
                      color: AppColors.pureBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.black26)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Or pay using',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.black26)),
              ],
            ),
          ),
          if (_savedCardLast4 != null) ...[
            Text(
              'Saved',
              style: TextStyle(
                color: AppColors.pureBlack,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedMethod = 'saved'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.whiteSmoke,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedMethod == 'saved'
                        ? AppColors.iOSBlue
                        : Colors.black12,
                    width: _selectedMethod == 'saved' ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.pureBlack,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.circle,
                          color: AppColors.primaryOrange,
                          size: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '•••• $_savedCardLast4',
                      style: TextStyle(
                        color: AppColors.pureBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'View more',
                      style: TextStyle(color: AppColors.iOSBlue, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'New payment method',
            style: TextStyle(
              color: AppColors.pureBlack,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                ListTile(
                  onTap: () => setState(() => _isAddingNewCard = true),
                  leading: Icon(Icons.credit_card, color: AppColors.pureBlack),
                  title: Text(
                    'New card',
                    style: TextStyle(
                      color: AppColors.pureBlack,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.black12, indent: 48),
                ListTile(
                  onTap: () => setState(() => _selectedMethod = 'cashapp'),
                  leading: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.attach_money,
                      color: AppColors.whiteSmoke,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    'Cash App Pay',
                    style: TextStyle(
                      color: AppColors.pureBlack,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: _selectedMethod == 'cashapp'
                      ? const Icon(Icons.check_circle, color: AppColors.iOSBlue)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: AppColors.anger,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iOSBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.whiteSmoke,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pay EGP ${widget.plan['amount']}',
                          style: TextStyle(
                            color: AppColors.whiteSmoke,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.lock, color: AppColors.whiteSmoke, size: 16),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAddCardUI() {
    return SingleChildScrollView(
      key: const ValueKey('add_card'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _isAddingNewCard = false;
                  _errorMessage = null;
                }),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 4),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.pureBlack,
                    size: 20,
                  ),
                ),
              ),
              Text(
                'Add card',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pureBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Card information',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _cardNumberController,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CardNumberFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Card number',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintStyle: TextStyle(color: Colors.black38),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.pureBlack, fontSize: 16),
                ),
                const Divider(height: 1, color: Colors.black12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ExpiryDateFormatter(),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'MM / YY',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        keyboardType: TextInputType.datetime,
                        style: TextStyle(
                          color: AppColors.pureBlack,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 48, color: Colors.black12),
                    Expanded(
                      child: TextField(
                        controller: _cvcController,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(4),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'CVC',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        style: TextStyle(
                          color: AppColors.pureBlack,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Billing address',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: const Text(
                'Country or region',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              subtitle: Text(
                'Egypt',
                style: TextStyle(fontSize: 16, color: AppColors.pureBlack),
              ),
              trailing: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _saveInfo,
                activeColor: AppColors.iOSBlue,
                onChanged: (val) => setState(() => _saveInfo = val ?? true),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Text(
                  'Save my info for faster checkout with Link',
                  style: TextStyle(fontSize: 14, color: AppColors.pureBlack),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: AppColors.anger,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iOSBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.whiteSmoke,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pay EGP ${widget.plan['amount']}',
                          style: TextStyle(
                            color: AppColors.whiteSmoke,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.lock, color: AppColors.whiteSmoke, size: 16),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
