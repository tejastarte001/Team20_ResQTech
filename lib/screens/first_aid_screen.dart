import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


class FirstAidScreen extends StatelessWidget {
  final List<Map<String, dynamic>> firstAidTopics = [
    {
      'icon': Icons.local_fire_department,
      'title': 'Burns',
      'description': 'Immediate treatment for minor to severe burns',
      'color': Colors.redAccent,
      'content': """
1.  Cool the burn : Hold under cool running water for 10-15 minutes
2.  Remove jewelry/clothing : Gently remove from burned area unless stuck
3.  Apply lotion : Use aloe vera or moisturizer (not butter/oil)
4.  Bandage loosely : Use sterile gauze (no fluffy cotton)
5.  Take pain relievers : Ibuprofen or acetaminophen can help
6.  Seek medical help  for:
   - Burns larger than 3 inches
   - Burns on face, hands, feet or genitals
   - Deep burns (white or charred skin)
"""
    },
    {
      'icon': Icons.favorite,
      'title': 'Heart Attack',
      'description': 'Recognize and respond to cardiac emergencies',
      'color': Colors.pinkAccent,
      'content': """
 Signs of Heart Attack: 
- Chest pain/discomfort (pressure, squeezing)
- Pain in arms, back, neck, jaw
- Shortness of breath
- Cold sweat, nausea, lightheadedness

 What to Do: 
1. Call emergency services immediately
2. Have person sit down and rest
3. Loosen tight clothing
4. Give aspirin if not allergic (chew 325mg)
5. Perform CPR if person becomes unresponsive
6. Use AED if available
"""
    },
    {
      'icon': Icons.health_and_safety,
      'title': 'CPR',
      'description': 'Life-saving procedure for cardiac arrest',
      'color': Colors.blueAccent,
      'content': """
 For Adults: 
1. Check responsiveness
2. Call for help
3. 30 chest compressions (2 inches deep, 100-120/min)
4. 2 rescue breaths
5. Continue until help arrives or AED available

 For Children: 
- Use 1 or 2 hands depending on size
- Compress about 2 inches deep
- Same 30:2 ratio

 For Infants: 
- Use 2 fingers for compressions
- Compress about 1.5 inches deep
- Cover nose and mouth for breaths
"""
    },
    {
      'icon': Icons.coronavirus,
      'title': 'Choking',
      'description': 'Help someone who can\'t breathe',
      'color': Colors.orangeAccent,
      'content': """
 Conscious Adult/Child: 
1. Ask "Are you choking?"
2. Stand behind, wrap arms around waist
3. Make fist, thumb side against abdomen
4. Grasp fist with other hand, give quick upward thrusts
5. Continue until object is expelled or person becomes unconscious

 Infants: 
1. Support head, place face down on forearm
2. Give 5 back blows between shoulder blades
3. Flip over, give 5 chest thrusts
4. Repeat until object is expelled

 Unconscious Person: 
1. Lower to floor
2. Begin CPR (chest compressions first)
"""
    },
    {
      'icon': Icons.bloodtype,
      'title': 'Bleeding',
      'description': 'Control severe bleeding',
      'color': Colors.deepPurpleAccent,
      'content': """
1.  Apply direct pressure : Use clean cloth or bandage
2.  Elevate wound : Raise above heart level if possible
3.  Add more layers : Don't remove soaked bandages
4.  Apply pressure to artery : If bleeding doesn't stop
   - Arm: Brachial artery (inner arm)
   - Leg: Femoral artery (groin area)
5.  Tourniquet last resort :
   - Use wide band (2-3 inches)
   - Note application time
6.  Seek immediate medical care  for:
   - Deep wounds
   - Embedded objects
   - Animal bites
"""
    },
    {
      'icon': Icons.bug_report,
      'title': 'Snake Bites',
      'description': 'Emergency response to venomous bites',
      'color': Colors.green,
      'content': """
 Do: 
1. Stay calm and still
2. Remove jewelry/tight clothing
3. Position limb at or below heart level
4. Clean wound with soap and water
5. Immobilize the affected area
6. Get to medical facility immediately

 Don't: 
- Cut the wound
- Suck out venom
- Apply tourniquet
- Apply ice
- Drink alcohol/caffeine
- Try to catch the snake (take photo if safe)

 Note time of bite  and any symptoms (swelling, pain, nausea)
"""
    },
    {
      'icon': Icons.directions_car,
      'title': 'Accident Trauma',
      'description': 'Stabilize injured persons',
      'color': Colors.amber,
      'content': """
1.  Ensure scene safety  before approaching
2.  Check responsiveness 
3.  Call for emergency help 
4.  Control bleeding 
5.  Immobilize spine  if neck/back injury suspected
   - Don't move unless absolutely necessary
6.  Treat for shock :
   - Lay person down
   - Elevate legs 12 inches
   - Keep warm
7.  Monitor breathing  until help arrives
"""
    },
    {
      'icon': Icons.psychology,
      'title': 'Seizures',
      'description': 'Help during epileptic episodes',
      'color': Colors.indigoAccent,
      'content': """
 During Seizure: 
1. Stay calm and time the seizure
2. Clear area of hard/sharp objects
3. Cushion head if on hard surface
4. Turn person on side (recovery position)
5. Don't restrain or put anything in mouth
6. Loosen tight clothing around neck

 After Seizure: 
1. Stay with person until fully alert
2. Offer reassurance
3. Explain what happened
4. Help get home safely

 Call Emergency If: 
- Seizure lasts >5 minutes
- Repeated seizures
- Difficulty breathing
- Injury occurred
- First-time seizure
"""
    },
    {
      'icon': Icons.mood,
      'title': 'Panic Attacks',
      'description': 'Manage acute anxiety episodes',
      'color': Colors.teal,
      'content': """
 How to Help: 
1. Stay calm and speak in short sentences
2. Move to quiet place if possible
3. Encourage slow, deep breathing:
   - Breathe in for 4 counts
   - Hold for 4 counts
   - Exhale for 6 counts
4. Use grounding techniques:
   - Name 5 things you see
   - 4 things you feel
   - 3 things you hear
   - 2 things you smell
   - 1 thing you taste
5. Offer water
6. Don't dismiss their feelings

 After Attack: 
- Discuss triggers if they want to
- Encourage professional help if frequent
"""
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("First Aid Guide", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.redAccent.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Emergency First Aid Procedures",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: firstAidTopics.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final topic = firstAidTopics[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    shadowColor: topic['color'].withOpacity(0.3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FirstAidDetailScreen(topic: topic),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: topic['color'].withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(topic['icon'], color: topic['color'], size: 28),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    topic['description'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Emergency Numbers"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🚑 Ambulance: 108"),
                  Text("🚒 Fire Department: 101"),
                  Text("🚓 Police: 100"),
                  SizedBox(height: 16),
                  Text("Emergency: 112"),
                  Text("Women Helpline: 1091"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
          );
        },
        icon: Icon(Icons.emergency, color: Colors.white),
        label: Text("Emergency", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 4,
      ),
    );
  }
}

class FirstAidDetailScreen extends StatelessWidget {
  final Map<String, dynamic> topic;

  const FirstAidDetailScreen({Key? key, required this.topic}) : super(key: key);


  void _shareContent(String title, String content) {
  Share.share('$title\n\n$content');
}

void _makePhoneCall(BuildContext context,String phoneNumber) async {
  final Uri uri = Uri(scheme: 'tel', path: phoneNumber);

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open dialer: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topic['title'], style: TextStyle(color: Colors.white)),
        backgroundColor: topic['color'],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: topic['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(topic['icon'], color: topic['color'], size: 32),
                      SizedBox(width: 12),
                      Text(
                        topic['title'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: topic['color'],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    topic['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "First Aid Steps:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              topic['content'],
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 24),
            if (topic['title'] == "CPR") ...[
              Text(
                "CPR Demonstration:",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.play_circle_fill, size: 60, color: Colors.redAccent),
              ),
              SizedBox(height: 12),
              Text(
                "Watch proper CPR technique demonstration",
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.grey[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => _makePhoneCall(context ,"112"),
              icon: Icon(Icons.phone, color: Colors.redAccent),
              label: Text("Call Emergency", style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton.icon(
              onPressed: () => _shareContent(topic['title'], topic['content']),
              icon: Icon(Icons.share, color: Colors.blueAccent),
              label: Text("Share Guide", style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ),
    );
  }
}