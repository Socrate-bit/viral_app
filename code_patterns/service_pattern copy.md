Got it 👍 — here’s your **prompt rewritten with the same formatting**, but improved to match your `FirebaseService` example:

---

# Rules:

- Use **singleton pattern** with `static final` instance, private `._internal` constructor, and `factory` for global access.
- Instantiate external / API services (e.g. `FirebaseFirestore`, `FirebaseStorage`) as **private finals**.
- Use `async/await` for one-off calls; return `Future<T>` for single fetch/update operations.
- Use `Stream<T>` only when data must update reactively (e.g. live UI).
- Handle known errors by catching and throwing **typed exceptions** or meaningful `Exception` messages.
- Methods should return `Future<Model>`, `List<Model>`, or `Stream<Model>` if model existing (If not keep simple), map snapshots using `.map` in the service before returning.
- Inline `///` doc comments for each **non-obvious field or method**.

# Exemple:

```dart
class FooFirestoreService {
  static final FooFirestoreService _instance = FooFirestoreService._internal();
  factory FooFirestoreService() => _instance;
  FooFirestoreService._internal();

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
```

---

Do you want me to also **add an example with FirebaseStorage** (like your upload/download image use case) under this same format so your prompt covers both Firestore and Storage?
