import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'models/canteen.dart';
import 'models/menu_item.dart';
import 'models/order.dart';
import 'services/api_service.dart';

void main() {
  runApp(const CollegeCantinStudentApp());
}

class CollegeCantinStudentApp extends StatelessWidget {
  const CollegeCantinStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollegeCantin Student',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFEFAF3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFE724C),
          primary: const Color(0xFFFE724C),
          secondary: const Color(0xFFFFC529),
          surface: const Color(0xFFFEFAF3),
        ),
        fontFamily: 'Roboto',
      ),
      home: const StudentAppHomeScreen(),
    );
  }
}

class StudentAppHomeScreen extends StatefulWidget {
  const StudentAppHomeScreen({super.key});

  @override
  State<StudentAppHomeScreen> createState() => _StudentAppHomeScreenState();
}

class _StudentAppHomeScreenState extends State<StudentAppHomeScreen> {
  // Navigation Screens: 'COLLEGE_CODE', 'CANTEEN_SELECT', 'MENU', 'ORDER_TICKET'
  String currentScreen = 'COLLEGE_CODE';
  final TextEditingController codeController = TextEditingController(text: 'CMRTC');

  List<CanteenModel> canteens = [];
  CanteenModel? selectedCanteen;

  List<MenuItemModel> menuItems = [];
  String selectedCategory = 'ALL';
  bool isVegOnly = false;
  bool isLoadingMenu = false;

  // Cart Items
  List<CartItem> cart = [];

  // Checkout Student Info Controllers
  final TextEditingController nameController = TextEditingController(text: 'Santosh Margam');
  final TextEditingController rollNoController = TextEditingController(text: '21CMRTC104');
  final TextEditingController phoneController = TextEditingController(text: '9876543210');
  final TextEditingController emailController = TextEditingController(text: 'student@cmrtc.edu');

  // Active Order & Realtime Status Timer
  OrderModel? activeOrder;
  Timer? statusPollingTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialCanteens();
  }

  @override
  void dispose() {
    statusPollingTimer?.cancel();
    codeController.dispose();
    nameController.dispose();
    rollNoController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialCanteens() async {
    final list = await ApiService.fetchCanteens();
    setState(() {
      canteens = list;
    });
  }

  void _selectCanteen(CanteenModel canteen) async {
    setState(() {
      selectedCanteen = canteen;
      isLoadingMenu = true;
      currentScreen = 'MENU';
      cart.clear();
    });

    final items = await ApiService.fetchMenuItems(canteen.id);
    setState(() {
      menuItems = items;
      isLoadingMenu = false;
    });
  }

  void _addToCart(MenuItemModel item) {
    final idx = cart.indexWhere((c) => c.id == item.id);
    setState(() {
      if (idx >= 0) {
        cart[idx].quantity += 1;
      } else {
        cart.add(CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: 1,
          isVeg: item.isVeg,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${item.name} to cart!'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFFFE724C),
      ),
    );
  }

  double get cartSubtotal => cart.fold(0, (sum, i) => sum + (i.price * i.quantity));
  double get platformFee => (cartSubtotal * 0.04).roundToDouble();
  double get cartTotal => cartSubtotal + platformFee;

  void _submitOrder() async {
    if (selectedCanteen == null || cart.isEmpty) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFE724C))),
    );

    final order = await ApiService.submitOrder(
      tenantId: selectedCanteen!.id,
      studentName: nameController.text.isEmpty ? 'Student' : nameController.text,
      rollNo: rollNoController.text,
      phone: phoneController.text,
      email: emailController.text,
      cartItems: cart,
      subtotal: cartSubtotal,
      platformFee: platformFee,
      totalAmount: cartTotal,
    );

    Navigator.of(context).pop(); // Close loading

    if (order != null) {
      setState(() {
        activeOrder = order;
        cart.clear();
        currentScreen = 'ORDER_TICKET';
      });

      // Start Realtime Order Status Polling (Checks if scanned at kiosk)
      _startStatusPolling(order.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order failed. Please try again.')),
      );
    }
  }

  void _startStatusPolling(String orderId) {
    statusPollingTimer?.cancel();
    statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final updated = await ApiService.checkOrderStatus(orderId);
      if (updated != null && (updated.status == 'PRINTED' || updated.qrUsedAt != null)) {
        setState(() {
          activeOrder = updated;
        });
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (currentScreen) {
      case 'COLLEGE_CODE':
        return _buildCollegeCodeScreen();
      case 'CANTEEN_SELECT':
        return _buildCanteenSelectScreen();
      case 'MENU':
        return _buildMenuScreen();
      case 'ORDER_TICKET':
        return _buildOrderTicketScreen();
      default:
        return _buildCollegeCodeScreen();
    }
  }

  // 1. COLLEGE CODE INPUT SCREEN
  Widget _buildCollegeCodeScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFE724C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.storefront_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'CollegeCantin',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF272D2F)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your College Code to view canteens & order food online.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
                decoration: InputDecoration(
                  labelText: 'College Code (e.g. CMRTC)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.numbers, color: Color(0xFFFE724C)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE724C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    setState(() {
                      currentScreen = 'CANTEEN_SELECT';
                    });
                  },
                  child: const Text('Find College Canteens', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. CANTEEN SELECTOR SCREEN
  Widget _buildCanteenSelectScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Canteen Outlet', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => currentScreen = 'COLLEGE_CODE'),
        ),
      ),
      body: canteens.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFE724C)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: canteens.length,
              itemBuilder: (ctx, i) {
                final canteen = canteens[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFFAF0), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.restaurant, color: Color(0xFFFE724C)),
                    ),
                    title: Text(canteen.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('${canteen.collegeName} • ${canteen.location}'),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFFE724C)),
                    onTap: () => _selectCanteen(canteen),
                  ),
                );
              },
            ),
    );
  }

  // 3. FOOD MENU SCREEN WITH CART BADGE
  Widget _buildMenuScreen() {
    final filteredItems = menuItems.where((item) {
      if (isVegOnly && !item.isVeg) return false;
      if (selectedCategory != 'ALL' && item.categoryId != selectedCategory) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CollegeCantin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF272D2F))),
            Text(selectedCanteen?.name ?? 'Canteen', style: const TextStyle(fontSize: 12, color: Color(0xFFFE724C), fontWeight: FontWeight.bold)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF272D2F)),
          onPressed: () => setState(() => currentScreen = 'CANTEEN_SELECT'),
        ),
      ),
      body: isLoadingMenu
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFE724C)))
          : Column(
              children: [
                // Filter Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('🥦 Veg Only'),
                        selected: isVegOnly,
                        onSelected: (val) => setState(() => isVegOnly = val),
                        selectedColor: Colors.green.shade100,
                      ),
                    ],
                  ),
                ),
                // Food Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (ctx, i) {
                      final item = filteredItems[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                item.imageUrl,
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('₹${item.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFFFE724C))),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 36,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFE724C),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _addToCart(item),
                                      child: const Text('+ Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF272D2F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showCheckoutBottomSheet,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text('${cart.length} Items | ₹${cartTotal.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Text('View Cart & Pay →', style: TextStyle(color: Color(0xFFFFC529), fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // 4. CHECKOUT BOTTOM SHEET MODAL
  void _showCheckoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Confirm Order & Pay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Student Name')),
                  TextField(controller: rollNoController, decoration: const InputDecoration(labelText: 'Roll Number')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('₹${cartSubtotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform Fee:'),
                      Text('₹${platformFee.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('₹${cartTotal.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFFE724C))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE724C)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _submitOrder();
                      },
                      child: const Text('Pay via UPI & Get QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 5. LIVE PICKUP QR TICKET SCREEN
  Widget _buildOrderTicketScreen() {
    if (activeOrder == null) return const SizedBox();
    final isClaimed = activeOrder!.status == 'PRINTED' || activeOrder!.qrUsedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup QR Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => currentScreen = 'MENU'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isClaimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('✅ QR CODE CLAIMED AT COUNTER!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('ORDER #${activeOrder!.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFFFE724C))),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: isClaimed ? 0.3 : 1.0,
                      child: QrImageView(
                        data: activeOrder!.qrToken,
                        version: QrVersions.auto,
                        size: 220.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(activeOrder!.userStudentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Roll No: ${activeOrder!.studentRollNo}', style: const TextStyle(color: Colors.grey)),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Paid:'),
                        Text('₹${activeOrder!.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFFFE724C))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => currentScreen = 'MENU'),
              child: const Text('Order More Items'),
            ),
          ],
        ),
      ),
    );
  }
}
