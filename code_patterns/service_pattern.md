# Rules:
- Instantiate Firebase services directly as private finals.
- Use async/await for one-off calls; return Future for single fetch/update.
- Use Stream only when data must update reactively (e.g., live UI).
- Always map Firebase docs/snapshots to domain models inside service.
- For Stream, map snapshots using .map in service before returning.
- Do not expose Firebase objects, snapshots, or streams of raw docs.
- Handle known errors by throwing typed exceptions.
- Methods should return Future<Model> or Stream<Model>, not raw types.
- All fields and helpers are private.
- Inline doc comments for each non-obvious field or method.

# Exemple:
class FooFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<Foo> fetchFoo(String id) async {
    final doc = await _firestore.collection('foos').doc(id).get();
    if (!doc.exists) throw FooNotFoundFailure();
    return Foo.fromJson(doc.data()!);
  }
  Stream<Foo> fooStream(String id) {
    return _firestore.collection('foos').doc(id).snapshots().map((doc) {
      if (!doc.exists) throw FooNotFoundFailure();
      return Foo.fromJson(doc.data()!);
    });
  }
}
