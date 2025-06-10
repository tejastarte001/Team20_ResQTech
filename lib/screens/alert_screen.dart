import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlertsListPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No timestamp';
    final date = timestamp.toDate();
    return DateFormat.yMMMMd().add_jm().format(date);
  }

  Future<String?> getCorrectUid() async {
    final user = _auth.currentUser;

    print("user in alert screen $user");
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return null;

    // final correctUid = userDoc.data()?['uid'] as String?;
    final correctUid = user.uid;
    print('Correct UID fetched from Firestore user profile: $correctUid');
    return correctUid;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Your Alerts')),
        body: Center(child: Text('⚠️ You are not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Alerts'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<String?>(
        future: getCorrectUid(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text('⚠️ Unable to find user UID for alerts.'),
            );
          }

          final correctUid = snapshot.data!;
          print("correct Uid $correctUid");

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('alerts')
                .where('userId', isEqualTo: correctUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('❌ Error loading alerts.'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('📭 No alerts found.'));
              }

              final alerts = snapshot.data!.docs;

              alerts.sort((a, b) {
                final aTime = (a['timestamp'] as Timestamp?)?.toDate();
                final bTime = (b['timestamp'] as Timestamp?)?.toDate();
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alertData =
                      alerts[index].data()! as Map<String, dynamic>;

                  final lat = alertData['latitude'] != null
                      ? (alertData['latitude'] as num).toStringAsFixed(5)
                      : 'N/A';
                  final lng = alertData['longitude'] != null
                      ? (alertData['longitude'] as num).toStringAsFixed(5)
                      : 'N/A';
                  final address = alertData['address'] ?? 'No address provided';
                  final timestamp = formatTimestamp(alertData['timestamp']);

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        address,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('📍 Lat: $lat, Lng: $lng\n🕒 $timestamp'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Delete Alert'),
                              content: Text(
                                'Are you sure you want to delete this alert?',
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                ),
                                ElevatedButton(
                                  child: Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await snapshot.data!.docs[index].reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('🗑️ Alert deleted.')),
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
        },
      ),
    );
  }
}
