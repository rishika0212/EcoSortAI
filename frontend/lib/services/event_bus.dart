import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  
  factory EventBus() => _instance;
  
  EventBus._internal();
  
  // Use a broadcast controller to allow multiple listeners
  final _pointsUpdatedController = StreamController<int>.broadcast();
  
  // Leaderboard update event
  final _leaderboardUpdatedController = StreamController<bool>.broadcast();
  
  // Track the last emitted points value
  int _lastEmittedPoints = 0;
  
  // Store subscriptions to allow cancellation
  final Map<Object, StreamSubscription> _pointsSubscriptions = {};
  final Map<Object, StreamSubscription> _leaderboardSubscriptions = {};
  
  // Getter to access the last emitted points value
  int get lastPoints => _lastEmittedPoints;
  
  Stream<int> get onPointsUpdated => _pointsUpdatedController.stream;
  Stream<bool> get onLeaderboardUpdated => _leaderboardUpdatedController.stream;
  
  // Subscribe to points updates
  void listenToPointsUpdated(Function(int) callback, [Object? key]) {
    final subscriptionKey = key ?? callback;
    // Cancel existing subscription if any
    _pointsSubscriptions[subscriptionKey]?.cancel();
    // Add new subscription
    _pointsSubscriptions[subscriptionKey] = _pointsUpdatedController.stream.listen(callback);
    print("EventBus: Added points update listener with key: $subscriptionKey");
  }
  
  // Unsubscribe from points updates
  void offPointsUpdated([Object? key]) {
    if (key != null) {
      _pointsSubscriptions[key]?.cancel();
      _pointsSubscriptions.remove(key);
      print("EventBus: Removed points update listener with key: $key");
    } else {
      // Cancel all subscriptions if no key is provided
      for (final subscription in _pointsSubscriptions.values) {
        subscription.cancel();
      }
      _pointsSubscriptions.clear();
      print("EventBus: Removed all points update listeners");
    }
  }
  
  // Subscribe to leaderboard updates
  void listenToLeaderboardUpdated(Function(bool) callback, [Object? key]) {
    final subscriptionKey = key ?? callback;
    // Cancel existing subscription if any
    _leaderboardSubscriptions[subscriptionKey]?.cancel();
    // Add new subscription
    _leaderboardSubscriptions[subscriptionKey] = _leaderboardUpdatedController.stream.listen(callback);
    print("EventBus: Added leaderboard update listener with key: $subscriptionKey");
  }
  
  // Unsubscribe from leaderboard updates
  void offLeaderboardUpdated([Object? key]) {
    if (key != null) {
      _leaderboardSubscriptions[key]?.cancel();
      _leaderboardSubscriptions.remove(key);
      print("EventBus: Removed leaderboard update listener with key: $key");
    } else {
      // Cancel all subscriptions if no key is provided
      for (final subscription in _leaderboardSubscriptions.values) {
        subscription.cancel();
      }
      _leaderboardSubscriptions.clear();
      print("EventBus: Removed all leaderboard update listeners");
    }
  }
  
  void emitPointsUpdated(int points) {
    print("EventBus: Emitting points updated event with $points points");
    
    // Only emit if the points have changed
    if (points != _lastEmittedPoints) {
      print("EventBus: Points changed from $_lastEmittedPoints to $points, emitting event");
      _pointsUpdatedController.add(points);
      _lastEmittedPoints = points;
      
      // Also emit a leaderboard update event since points have changed
      emitLeaderboardUpdated();
    } else {
      print("EventBus: Points unchanged at $points, not emitting event");
    }
  }
  
  void emitLeaderboardUpdated() {
    print("EventBus: Emitting leaderboard updated event");
    _leaderboardUpdatedController.add(true);
  }
  
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _pointsSubscriptions.values) {
      subscription.cancel();
    }
    for (final subscription in _leaderboardSubscriptions.values) {
      subscription.cancel();
    }
    _pointsSubscriptions.clear();
    _leaderboardSubscriptions.clear();
    
    // Close controllers
    _pointsUpdatedController.close();
    _leaderboardUpdatedController.close();
  }
}