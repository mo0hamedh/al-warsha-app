import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Starting points reset...');
  
  try {
    final firestore = FirebaseFirestore.instance;
    final usersSnapshot = await firestore.collection('users').get();
    
    final batch = firestore.batch();
    int count = 0;

    for (var doc in usersSnapshot.docs) {
      batch.update(doc.reference, {
        'monthlyPoints': 0,
        'totalPoints': 0,
        'weeklyFocusPoints': 0 // Optional: reset this too to fully clear ranking points
      });
      count++;
      
      // Firestore batches support up to 500 operations
      if (count % 400 == 0) {
        await batch.commit();
        print('Committed $count updates...');
      }
    }

    if (count % 400 != 0) {
      await batch.commit();
    }

    print('Successfully reset points for $count users.');
  } catch (e) {
    print('Error resetting points: $e');
  }
}
