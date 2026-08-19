class LaterBoxAuthState {
  const LaterBoxAuthState({this.userId, this.email});

  final String? userId;
  final String? email;

  bool get isAuthenticated => userId != null;
}
