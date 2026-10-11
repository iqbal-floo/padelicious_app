import '../models/session_summary.dart';
import 'mock_data.dart';

abstract class SessionRepository {
  Future<List<SessionSummary>> fetchActiveSessions();
  Future<List<SessionSummary>> fetchPastSessions();
}

class MockSessionRepository implements SessionRepository {
  @override
  Future<List<SessionSummary>> fetchActiveSessions() async => MockData.activeSessions;

  @override
  Future<List<SessionSummary>> fetchPastSessions() async => MockData.pastSessions;
}
