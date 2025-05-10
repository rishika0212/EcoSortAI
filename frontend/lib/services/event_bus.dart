import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  
  factory EventBus() => _instance;
  
  EventBus._internal();
  
  // Use a broadcast controller to allow multiple listeners
  final _pointsUpdatedController = StreamController<int>.broadcast();
  
  // Track the last emitted points value
  int _lastEmittedPoints = 0;
  
  // Getter to access the last emitted points value
  int get lastPoints => _lastEmittedPoints;
  
  Stream<int> get onPointsUpdated => _pointsUpdatedController.stream;
  
  void emitPointsUpdated(int points) {
    print("EventBus: Emitting points updated event with $points points");
    
    // Only emit if the points have changed
    if (points != _lastEmittedPoints) {
      print("EventBus: Points changed from $_lastEmittedPoints to $points, emitting event");
      _pointsUpdatedController.add(points);
      _lastEmittedPoints = points;
    } else {
      print("EventBus: Points unchanged at $points, not emitting event");
    }
  }
  
  void dispose() {
    _pointsUpdatedController.close();
  }
}