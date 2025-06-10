import 'dart:convert';

import 'package:emergency_alert_app/screens/auth_screen.dart';
import 'package:emergency_alert_app/screens/first_aid_screen.dart';
import 'package:emergency_alert_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:emergency_alert_app/screens/add_contact_dialog.dart';
import 'package:emergency_alert_app/screens/alert_screen.dart';
import 'package:emergency_alert_app/screens/hospital_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSending = false;
  Map<String, dynamic>? _userData;
  bool _loadingUserData = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = widget.user;

    print("here$user");
    if (user == null) {
      setState(() {
        _loadingUserData = false;
      });
      return;
    }

    try {
      QuerySnapshot querySnapshot;

      if (user.providerData.any((info) => info.providerId == 'google.com')) {
        // Google user - query by email
        final email = user.email;
        if (email == null) {
          throw Exception('Google user has no email');
        }
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        _userData = querySnapshot.docs.first.data() as Map<String, dynamic>?;
      } else {
        // Phone user - get by UID
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        _userData = doc.data();
      }

      setState(() {
        _loadingUserData = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _userData = null;
        _loadingUserData = false;
      });
    }
  }

  Future<void> _logoutUser() async {
    try {
      // Close the drawer first
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // If using Google Sign-In
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // Close loading indicator
      Navigator.pop(context);

      // Navigate to AuthScreen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Close loading indicator if there's an error
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
    }
  }

  void _showAddContactDialog() {
    showDialog(context: context, builder: (context) => AddContactDialog());
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location services are disabled. Please enable the services',
          ),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  // Future<void> sendPanicAlert() async {
  //   setState(() {
  //     _isSending = true;
  //   });

  //   bool hasPermission = await _handleLocationPermission();
  //   if (!hasPermission) {
  //     setState(() {
  //       _isSending = false;
  //     });
  //     return;
  //   }

  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) throw Exception("User not logged in");

  //     // Get current location
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     String address = await getAddressFromLatLng(
  //       position.latitude,
  //       position.longitude,
  //     );

  //     // Save to Firestore
  //     await FirebaseFirestore.instance.collection('alerts').add({
  //       'userId': user.uid,
  //       'latitude': position.latitude,
  //       'longitude': position.longitude,
  //       'address': address,
  //       'timestamp': Timestamp.now(),
  //       'status': 'active',
  //     });

  //     // Prepare Google Maps URL
  //     String mapsUrl =
  //         "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

  //     // Fetch emergency contacts
  //     final userDoc = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .get();
  //     final contacts = (userDoc.data()?['contacts'] as List?) ?? [];

  //     for (var contact in contacts) {
  //       final phone = contact['phone'];
  //       if (phone != null && phone.toString().isNotEmpty) {
  //         await sendSmsViaFirebaseFunction(phone, mapsUrl);
  //       }
  //     }

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           '🚨 Alert sent!\n📍 Location: $address',
  //           style: TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     print('Error in sendPanicAlert: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           '❌ Failed to send alert:\n$e',
  //           style: TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //       ),
  //     );
  //   } finally {
  //     setState(() {
  //       _isSending = false;
  //     });
  //   }
  // }

  // Future<void> sendPanicAlert() async {
  //   setState(() {
  //     _isSending = true;
  //   });

  //   bool hasPermission = await _handleLocationPermission();
  //   if (!hasPermission) {
  //     setState(() {
  //       _isSending = false;
  //     });
  //     return;
  //   }

  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) throw Exception("User not logged in");

  //     // Get current location
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );

  //     String address = await getAddressFromLatLng(
  //       position.latitude,
  //       position.longitude,
  //     );

  //     // Save alert data to Firestore
  //     await FirebaseFirestore.instance.collection('alerts').add({
  //       'userId': user.uid,
  //       'latitude': position.latitude,
  //       'longitude': position.longitude,
  //       'address': address,
  //       'timestamp': Timestamp.now(),
  //       'status': 'active',
  //     });

  //     // Prepare Google Maps URL
  //     String mapsUrl =
  //         "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

  //     // Fetch emergency contacts
  //     final userDoc = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .get();
  //     final contacts = (userDoc.data()?['contacts'] as List?) ?? [];

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           '🚨 Alert sent!\n📍 Location: $address\n📩 ',
  //           style: TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         duration: Duration(seconds: 5),
  //       ),
  //     );
  //     List<String> skippedPhones = [];

  //     for (var contact in contacts) {
  //       final phone = contact['phone'];
  //       if (phone != null && phone.toString().isNotEmpty) {
  //         skippedPhones.add(phone.toString());
  //       }
  //     }

  //     if (skippedPhones.isNotEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             '🔕 SMS not sent to: ${skippedPhones.join(", ")}.\nFeature under development.',
  //           ),
  //           duration: Duration(seconds: 7),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error in sendPanicAlert: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           '❌ Failed to send alert:\n$e',
  //           style: TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //       ),
  //     );
  //   } finally {
  //     setState(() {
  //       _isSending = false;
  //     });
  //   }
  // }

  Future<void> sendPanicAlert() async {
    setState(() {
      _isSending = true;
    });

    print('⏳ Starting panic alert process...');

    bool hasPermission = await _handleLocationPermission();
    print('🔐 Location permission: $hasPermission');
    if (!hasPermission) {
      setState(() => _isSending = false);
      _showErrorDialog('❌ Location permission denied. Cannot send alert.');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      print('👤 User logged in: ${user.uid}');

      // Get location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('📍 Location: ${position.latitude}, ${position.longitude}');

      String address = await getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );
      print('🏠 Address: $address');

      // Save to Firestore
      await FirebaseFirestore.instance.collection('alerts').add({
        'userId': user.uid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'timestamp': Timestamp.now(),
        'status': 'active',
      });
      print('💾 Alert saved to Firestore');

      // Get contacts
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final rawContacts = userDoc.data()?['contacts'] as List? ?? [];
      print('📞 Found ${rawContacts.length} emergency contacts');

      final formattedContacts = formatPhoneNumbers(rawContacts);
      print('📲 Formatted numbers: $formattedContacts');

      if (formattedContacts.isNotEmpty) {
        print('📨 Sending WhatsApp alerts...');
        for (String phone in formattedContacts) {
          await sendWhatsAppViaFirebaseFunction(
            name: user.displayName ?? 'Unknown',
            latitude: position.latitude,
            longitude: position.longitude,
            phone: phone,
          );
        }
      } else {
        print('⚠️ No valid contacts found');
      }

      _showSuccessDialog(address);
    } catch (e) {
      print('🚨 Error in sendPanicAlert: $e');
      _showErrorDialog('❌ Failed to send alert:\n$e');
    } finally {
      setState(() => _isSending = false);
      print('🏁 Panic alert process finished.');
    }
  }

  void _showSuccessDialog(String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚨 Emergency Alert Sent!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Your emergency alert has been delivered successfully.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('📍 Location shared:\n$address'),
            SizedBox(height: 20),
            Divider(),
            Text(
              '🔧 Note:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            Text(
              'Some advanced features like SMS notifications, live status tracking, and delivery confirmations are still under development and will be available soon. Stay safe!',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('❌ Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  List<String> formatPhoneNumbers(List<dynamic> contacts) {
    const countryCode = '+91'; // Adjust as needed
    List<String> numbers = [];

    for (var contact in contacts) {
      final rawPhone = contact['phone']?.toString();
      if (rawPhone == null || rawPhone.trim().isEmpty) continue;

      String phone = rawPhone.replaceAll(
        RegExp(r'\D'),
        '',
      ); // Remove non-digits
      phone = phone.replaceAll(RegExp(r'^0+'), ''); // Remove leading 0s

      if (!phone.startsWith(countryCode)) {
        phone = countryCode + phone;
      }

      numbers.add(phone);
    }

    return numbers;
  }

  Future<void> sendSmsViaFirebaseFunction(String phone, String mapsUrl) async {
    final Uri url = Uri.parse(
      'https://us-central1-emergency-alert-system-e0a91.cloudfunctions.net/sendEmergencySMS',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'message': '🚨 Emergency Alert!\nCheck location: $mapsUrl',
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to send SMS to $phone: ${response.body}');
      } else {
        print('✅ SMS sent to $phone');
      }
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        print('Full Placemark data: $place');

        List<String> parts = [];

        if (place.street != null && place.street!.trim().isNotEmpty) {
          parts.add(place.street!.trim());
        }
        if (place.locality != null && place.locality!.trim().isNotEmpty) {
          parts.add(place.locality!.trim());
        }
        if (place.postalCode != null && place.postalCode!.trim().isNotEmpty) {
          parts.add(place.postalCode!.trim());
        }
        if (place.country != null && place.country!.trim().isNotEmpty) {
          parts.add(place.country!.trim());
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        } else {
          return 'Unknown location';
        }
      } else {
        print('No placemarks found.');
        return 'Unknown location';
      }
    } catch (e, stacktrace) {
      print('Error in getAddressFromLatLng: $e');
      print(stacktrace);
      return 'Error fetching address';
    }
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 300,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: _loadingUserData
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            )
          : _userData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 40, color: Colors.white70),
                  SizedBox(height: 16),
                  Text(
                    'No user data available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            _userData!['photoUrl'] != null &&
                                _userData!['photoUrl'].isNotEmpty
                            ? NetworkImage(_userData!['photoUrl'])
                            : null,
                        child:
                            _userData!['photoUrl'] == null ||
                                _userData!['photoUrl'].isEmpty
                            ? Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.blueGrey[300],
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData!['name'] ?? 'No Name',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            _userData!['email'] ?? 'No Email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildInfoTile(
                        Icons.phone_rounded,
                        _userData!['number'] ?? 'No Phone',
                      ),
                      SizedBox(height: 12),
                      _buildInfoTile(
                        Icons.person_outline_rounded,
                        _userData!['gender'] ?? 'Not Specified',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContactList() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'User not logged in.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading contacts',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        final userDoc = snapshot.data;
        if (userDoc == null || !userDoc.exists) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No data found for user.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final contacts = data['contacts'] as List<dynamic>? ?? [];

        if (contacts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No emergency contacts added.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          separatorBuilder: (_, __) => SizedBox(height: 4),
          // separatorBuilder: (_, __) => Divider(height: 1, thickness: 1),
          itemBuilder: (context, index) {
            final contact = contacts[index] as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal.shade800),
                ),
                title: Text(
                  contact['name'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contact['relation'] ?? ''),
                    SizedBox(height: 2),
                    Text(
                      contact['phone'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent.shade200),
                  onPressed: () async {
                    try {
                      final userRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid);

                      await userRef.update({
                        'contacts': FieldValue.arrayRemove([contact]),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Contact deleted'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete contact'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmergencyRow(String label, String number) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text("$label: $number")),
        IconButton(
          icon: Icon(Icons.call, color: Colors.green),
          onPressed: () => _makePhoneCall(number),
        ),
      ],
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open dialer: $e')));
    }
  }


  void showEmergencyPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          SizedBox(width: 8),
          Text("Emergency Numbers", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEmergencyTile(context, icon: Icons.local_hospital, label: "Ambulance", number: "108", emoji: "🚑"),
            _buildEmergencyTile(context, icon: Icons.local_fire_department, label: "Fire Department", number: "101", emoji: "🔥"),
            _buildEmergencyTile(context, icon: Icons.local_police, label: "Police", number: "100", emoji: "🚓"),
            _buildEmergencyTile(context, icon: Icons.call, label: "Emergency", number: "112", emoji: "📞"),
            _buildEmergencyTile(context, icon: Icons.female, label: "Women Helpline", number: "1091", emoji: "👩"),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: Colors.grey),
          label: Text("Close", style: TextStyle(color: Colors.grey)),
        ),
      ],
    ),
  );
}

Widget _buildEmergencyTile(BuildContext context, {
  required IconData icon,
  required String label,
  required String number,
  required String emoji,
}) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 6),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.redAccent.shade100,
        child: Text(emoji, style: TextStyle(fontSize: 20)),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Call $number"),
      trailing: IconButton(
        icon: Icon(Icons.call, color: Colors.green),
        onPressed: () => _makePhoneCall(number),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Emergency Alert',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.red),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AlertsListPage()),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          children: [
            _buildDrawerHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _logoutUser,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emergency Button
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isSending ? null : sendPanicAlert,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.emergency, size: 50, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          _isSending ? 'SENDING ALERT...' : 'PANIC BUTTON',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (_isSending)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Contacts Section
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.contacts,
                            size: 24,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Emergency Contacts",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          Spacer(),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection('contacts')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              }
                              final contacts = snapshot.data?.docs ?? [];
                              if (contacts.length >= 3)
                                return const SizedBox.shrink();

                              return IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.teal,
                                ),
                                tooltip: 'Add Contact',
                                onPressed: _showAddContactDialog,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildContactList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.local_hospital,
                      label: "NearBy Hospitals",
                      color: Colors.green,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NearbyHospitalsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.medical_services,
                      label: "First Aid",
                      color: Colors.orange,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FirstAidScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEmergencyPopup(context),

        icon: Icon(Icons.emergency, color: Colors.white),
        label: Text("Emergency", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 4,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
