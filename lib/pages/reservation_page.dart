import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_model.dart';
import '../services/database_service.dart';
import '../widgets/custom_text.dart';   // AppText
import '../widgets/custom_button.dart'; // AppButton

class ReservationPage extends StatefulWidget {
  final Schedule trip;

  const ReservationPage({super.key, required this.trip});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  // 1. متغير لتخزين وسيلة الدفع المختارة (0=Card, 1=Apple, 2=Wallet)
  int selectedPaymentMethod = -1;

// 2. متغير لتخزين رصيد المحفظة القادم من الداتابيس
  double userBalance = 0.0;
  bool isLoadingBalance = true;

  final DatabaseService _dbService = DatabaseService(); // تعريف الخدمة للتعامل مع الداتابيس

  @override
  void initState() {
    super.initState();
    _fetchUserBalance();
  }

  Future<void> _fetchUserBalance() async {
    if (!mounted) return;
    setState(() => isLoadingBalance = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint("No user logged in");
        if (mounted) setState(() => isLoadingBalance = false);
        return;
      }

      // استخدم maybeSingle لتجنب الـ Exception إذا لم يوجد سجل
      final data = await Supabase.instance.client
          .from('profiles')
          .select('wallet_balance')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (data != null) {
            userBalance = (data['wallet_balance'] ?? 0.0).toDouble();
          } else {
            debugPrint("No profile found for this user, defaulting to 0");
            userBalance = 0.0;
          }
          isLoadingBalance = false;
        });
      }
    } catch (e) {
      debugPrint("Critical error fetching balance: $e");
      if (mounted) {
        setState(() => isLoadingBalance = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection error. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14181B),
        elevation: 0,
        title: AppText(
          text: "Confirm Booking",
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. كرت ملخص الرحلة
              _buildTripSummary(),

              const SizedBox(height: 30),

              // 2. تفصيل السعر (الفاتورة)
              AppText(text: "Payment Details", fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, onPressed: () {}),
              const SizedBox(height: 15),
              _buildPriceContainer(),

              const SizedBox(height: 30),

              // 3. خيارات الدفع (وهمية للشكل الجمالي)
              AppText(text: "Payment Method", fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, onPressed: () {}),
              const SizedBox(height: 15),
              _buildPaymentMethods(),

              const SizedBox(height: 40),

              // 4. زر التأكيد النهائي
              AppButton(
                text: "Confirm & Pay",
                onPressed: () {
                  // 1. التحقق من اختيار وسيلة دفع
                  if (selectedPaymentMethod == -1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a payment method first")),
                    );
                    return;
                  }

                  // 2. إذا اختار Card أو Apple Pay (الخدمة غير متاحة)
                  if (selectedPaymentMethod == 0 || selectedPaymentMethod == 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("This service is currently unavailable. Try Wallet."),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // 3. إذا اختار المحفظة (Wallet)
                  if (selectedPaymentMethod == 2) {
                    _showWalletConfirmation(); // استدعاء نافذة التأكيد الخاصة بالمحفظة
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ملخص الرحلة (من -> إلى)
  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF262D34)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(text: widget.trip.route?.origin ?? "N/A", fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, onPressed: () {}),
              const Icon(Icons.arrow_forward, color: Color(0xFF10B981)),
              AppText(text: widget.trip.route?.destination ?? "N/A", fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, onPressed: () {}),
            ],
          ),
          const Divider(height: 30, color: Color(0xFF262D34)),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              AppText(text: "Departure: ${widget.trip.departureTime.hour}:${widget.trip.departureTime.minute}", fontSize: 14, color: Colors.white70, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  // حاوية الأسعار
  Widget _buildPriceContainer() {
    final double basePrice = widget.trip.route?.basePrice ?? 0.0;
    final double tax = basePrice * 0.15;
    final double total = basePrice + tax;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _priceRow("Base Price", "$basePrice SAR"),
          _priceRow("VAT (15%)", "${tax.toStringAsFixed(2)} SAR"),
          const Divider(height: 30, color: Color(0xFF262D34)),
          _priceRow("Total Amount", "${total.toStringAsFixed(2)} SAR", isTotal: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, color: isTotal ? Colors.white : Colors.grey, fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, onPressed: () {}),
          AppText(text: value, color: isTotal ? const Color(0xFF10B981) : Colors.white, fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, onPressed: () {}),
        ],
      ),
    );
  }

  // أيقونات طرق الدفع
  Widget _buildPaymentMethods() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _paymentOption(0, Icons.credit_card, "Card"),
        _paymentOption(1, Icons.apple, "Apple Pay"),
        _paymentOption(2, Icons.account_balance_wallet, "Wallet"), // المحفظة
      ],
    );
  }

  Widget _paymentOption(int index, IconData icon, String label) {
    bool isSelected = selectedPaymentMethod == index;

    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = index),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2428),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF262D34),
                width: 2,
              ),
              // إضافة الظل عند الاختيار
              boxShadow: isSelected ? [
                BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 10)
              ] : [],
            ),
            child: Icon(icon, color: isSelected ? const Color(0xFF10B981) : Colors.white),
          ),
          const SizedBox(height: 5),
          AppText(text: label, fontSize: 12, color: isSelected ? Colors.white : Colors.grey, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _payIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262D34)),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }


  void _showWalletConfirmation() {
    if (isLoadingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Loading your balance... please wait")),
      );
      return;
    }

    final double totalPrice = (widget.trip.route?.basePrice ?? 0) * 1.15;
    bool canAfford = userBalance >= totalPrice;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D2428),
        title: AppText(text: "Wallet Payment", fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, onPressed: (){}),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض الرصيد الحقيقي المحدث
            AppText(text: "Your Balance: ${userBalance.toStringAsFixed(2)} SAR", color: Colors.white70, onPressed: (){}),
            const SizedBox(height: 10),
            AppText(text: "Total Due: ${totalPrice.toStringAsFixed(2)} SAR", color: Colors.white, fontWeight: FontWeight.bold, onPressed: (){}),
            const Divider(color: Color(0xFF262D34), height: 30),
            if (!canAfford)
              AppText(text: "⚠️ Insufficient balance. You need ${(totalPrice - userBalance).toStringAsFixed(2)} SAR more.", color: Colors.red, fontSize: 12, onPressed: (){})
            else
              AppText(text: "Do you want to proceed with the payment?", color: Colors.white70, fontSize: 14, onPressed: (){}),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          if (canAfford)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                Navigator.pop(context);
                _processFinalBooking(totalPrice);
              },
              child: const Text("Pay Now"),
            ),
        ],
      ),
    );
  }

  Future<void> _processFinalBooking(double amount) async {
    // 1. تنفيذ عملية الحجز في جدول reservations
    bool bookingSuccess = await _dbService.bookTicket(widget.trip.id, amount);

    if (bookingSuccess) {
      // 2. تنفيذ خصم الرصيد فعلياً من المحفظة
      bool balanceUpdated = await _dbService.updateWalletBalance(amount);

      if (balanceUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful & Balance Updated! 🎉"), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.pop(context); // العودة للهوم
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ticket booked but failed to update balance."), backgroundColor: Colors.orange),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction failed. Try again."), backgroundColor: Colors.red),
      );
    }
  }
}