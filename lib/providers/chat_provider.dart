import 'package:flutter/foundation.dart';
import '../core/models/all_models.dart';
import '../core/services/firestore_service.dart';

class ChatAppProvider extends ChangeNotifier {
  final _service = FirestoreService();
  
  // Future methods for chat management could go here
  // Currently used more for centralized interaction handling
}
