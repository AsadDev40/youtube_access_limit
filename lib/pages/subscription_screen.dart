// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/pages/home/home_page.dart';
import 'package:kidsafe_youtube/theme/colors.dart';
import 'package:provider/provider.dart';

import '../providers/subscription.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  String? _selectedPlanId;
  bool _isLoading = true;
  bool _available = true;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isTrialAvailable = true;

  final List<ProductDetails> _dummyProducts = [
    ProductDetails(
      id: 'monthly_plan',
      title: 'Monthly Plan',
      description: 'Get access for one month.',
      price: '\$9.99',
      rawPrice: 9.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
    ProductDetails(
      id: 'yearly_plan',
      title: 'Yearly Plan ',
      description: 'Get access for one year.',
      price: '\$99.99',
      rawPrice: 99.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
    ProductDetails(
      id: 'lifetime_plan',
      title: 'Lifetime Plan ',
      description: 'Get access for one year.',
      price: '\$300',
      rawPrice: 300,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlanId = 'yearly_plan';
    _checkTrialAvailability();
    _initializeInAppPurchase();
  }

  Future<void> _checkTrialAvailability() async {
    final provider = Provider.of<Subscriptionprovider>(context, listen: false);
    await provider.checkSubscriptionStatus(userId!);

    // Retrieve user data from Firestore to check isShowButton field
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;

      var trial = userData['isShowButton'];
      setState(() {
        _isTrialAvailable = trial; // Default to true if isShowButton is null
      });
    }
  }

  // Initialize In-App Purchase
  Future<void> _initializeInAppPurchase() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      setState(() {
        _available = false;
        _products = _dummyProducts; // Set dummy products
        _isLoading = false;
      });
      return;
    }

    const Set<String> productIds = {
      'monthly_plan',
      'yearly_plan',
      'lifetime_plan'
    };

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(productIds);

    // Check if no products were found
    if (response.productDetails.isEmpty) {
      setState(() {
        _products = _dummyProducts; // Set dummy products if none are found
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _products = response.productDetails; // Use fetched products
      _isLoading = false;
    });

    final purchaseUpdates = _iap.purchaseStream;
    purchaseUpdates.listen(_handlePurchaseUpdate, onError: _handleError);
  }

  // Handle successful purchases
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _confirmSubscription(purchaseDetails.productID);
        _iap.completePurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Purchase Error: ${purchaseDetails.error?.message}')),
        );
      }
    }
  }

  // Handle purchase errors
  void _handleError(error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchase failed: $error')),
    );
  }

  // Confirm subscription and save to Firestore
  void _confirmSubscription(String planId) async {
    final provider = Provider.of<Subscriptionprovider>(context, listen: false);
    await provider.confirmSubscription(userId!, planId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subscription confirmed for $planId!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 370),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _products.isEmpty
                          ? Center(
                              child: Text(
                                "No products available",
                                style: GoogleFonts.lato(),
                              ),
                            )
                          : _buildSubscriptionOptions(),
                ),
                _buildContinueButton(),
                const SizedBox(height: 0),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Terms of use | Privacy Policy | Restore',
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build subscription options
  Widget _buildSubscriptionOptions() {
    return Column(
      children: [
        _buildPlanTile(_products.firstWhere((p) => p.id == 'yearly_plan')),
        Row(
          children: [
            Flexible(
              flex: 1,
              child: _buildPlanTile(
                  _products.firstWhere((p) => p.id == 'monthly_plan')),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 1,
              child: _buildPlanTile(
                  _products.firstWhere((p) => p.id == 'lifetime_plan')),
            ),
          ],
        ),
      ],
    );
  }

  // Build each plan tile
  Widget _buildPlanTile(ProductDetails product,
      {double leftPadding = 0.0, double rightPadding = 0.0}) {
    bool isSelected = _selectedPlanId == product.id;

    // Define different sizes for each plan
    double width;
    double height;

    // Set sizes based on the product id
    if (product.id == 'yearly_plan') {
      width = MediaQuery.of(context).size.width * 0.9; // 90% of screen width
      height = 120.0; // Height for yearly plan
    } else {
      width = MediaQuery.of(context).size.width * 0.45; // 45% of screen width
      height = 120.0; // Height for other plans
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanId = product.id;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            margin: EdgeInsets.symmetric(
                vertical: 10.0, horizontal: isSelected ? 15.0 : 10.0),
            padding: EdgeInsets.symmetric(
                horizontal: 15.0 + leftPadding + rightPadding, vertical: 15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(
                color: isSelected ? pink : pink,
                width: 2.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.id == 'yearly_plan') ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.title,
                          style: GoogleFonts.lato(
                            fontSize: 25.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 20, left: 10, right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                product.price,
                                style: GoogleFonts.lato(
                                  fontSize: 22.0,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '\$9.99/month',
                                style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (product.id == 'monthly_plan') ...[
                  Text(
                    product.title,
                    style: GoogleFonts.lato(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    product.price,
                    style: GoogleFonts.lato(
                      fontSize: 18.0,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    '\$9.99/month',
                    style: GoogleFonts.lato(
                      fontSize: 12.0,
                      color: Colors.black,
                    ),
                  ),
                ] else if (product.id == 'lifetime_plan') ...[
                  Text(
                    product.title,
                    style: GoogleFonts.lato(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    product.price,
                    style: GoogleFonts.lato(
                      fontSize: 18.0,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    'One time pay',
                    style: GoogleFonts.lato(
                      fontSize: 12.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: -5,
              right: -2,
              child: Container(
                decoration: BoxDecoration(
                  color: pink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 27,
                ),
              ),
            ),
          if (product.id == 'yearly_plan')
            Positioned(
              top: 11,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pink,
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(10),
                      topLeft: Radius.circular(10)),
                ),
                child: Text(
                  'Popular',
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Column(
      children: [
        if (_isTrialAvailable)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent.withOpacity(0.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80.0),
            ),
            onPressed: () async {
              EasyLoading.show(status: 'Loading');
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'isTrial': true});
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({'isShowButton': false});
              Utils.pushAndRemovePrevious(context, const HomePage());
              EasyLoading.dismiss();
            },
            child: Text(
              'Start Free trial',
              style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        const SizedBox(
          height: 5,
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: pink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 100.0),
          ),
          onPressed: () {
            if (_selectedPlanId != null) {
              _buyProduct();
            } else {
              return;
            }
          },
          child: Text(
            'Continue',
            style: GoogleFonts.lato(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ],
    );
  }

  // Trigger product purchase
  Future<void> _buyProduct() async {
    final ProductDetails selectedProduct =
        _products.firstWhere((product) => product.id == _selectedPlanId);

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: selectedProduct);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
