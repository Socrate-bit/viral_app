# Rules

## Code Quality

- **Cubit > Widget State**: Business logic in cubits, not widgets (except conditional display, controller, animation, navigation)
- **Component Separation**:
    - **Clear Separation**: Scaffold → Page → Conditional state → Components
    - **Single Responsibility**: One purpose per method
    - **50-Line Limit**: Break down large pieces, each `_build` under 50 lines
    - **Composition > Inheritance**: Prefer build methods over hierarchies
- **Consistent Styling**:
    - Use `Theme.of(context)` for Colors/text styles
    - Use `AppColors` for custom colors not in theme
    - Use `AppDimensions` class for spacing and sizing
- **Keep it Simple**: Minimal, focused code

## Widget Architecture

- **Optional Wrappers**: `Scaffold`, `StatefulWidget`, `Cubit` state, `BlocConsumer`/`BlocBuilder` are **tools, not mandates** — use them if the page’s complexity requires it.
- **Scaffold Wrapper**: `[Name]Scaffold` with Scaffold, AppBar, BottomAppBar, etc.
- **Main Page**: `[Name]Page` as Stateless/Stateful widget, state-driven via BLoC when needed
    1. State variables (private)
    2. Simple action methods (if multi-step)
    3. Lifecycle (`initState`, `dispose`)
    4. Main build (clean, readable)
    5. Private `_build[ComponentName]()` methods
- **Reusable Widgets**: Only in `core/widgets/` if shared across files

## State Management

- **Dedicated Cubit**: For complex pages
- **UI Binding**:
    - Use **`BlocBuilder`** if only building UI from state
    - Use **`BlocConsumer`** if you need both state-driven UI and side-effects (e.g., navigation, error handling)
- **All Logic in Cubit**: Widgets = presentation only
- **Error:** Don’t use snack bar for notifying user, manage the error state display conditionally directly

# Example

```dart
class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Page")),
      body: const PageWidget(),
    );
  }
}

class PageWidget extends StatefulWidget {
  const PageWidget({super.key});

  @override
  State<PageWidget> createState() => _PageWidgetState();
}

class _PageWidgetState extends State<PageWidget> {
  // 1. State
  final _controller = TextEditingController();

  // 2. Actions
  void _complexAction() {
    context.read<PageCubit>().performAction(_controller.text);
  }

  // 3. Lifecycle
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 4. Builder
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PageCubit, PageState>(
      listener: (context, state) {
        // handle side-effects (snackbars, navigation)
      },
      builder: (context, state) {
        return switch (state.status) {
          PageStatus.initial => _buildEmpty(),
          PageStatus.loading => _buildLoading(),
          PageStatus.success => _buildLoaded(state),
          PageStatus.failure => _buildError(),
        };
      },
    );
  }

  // 5. Components
  Widget _buildEmpty() => const Center(child: Text("Nothing here yet"));
  Widget _buildLoading() => const Center(child: CircularProgressIndicator());
  Widget _buildError() => const Center(child: Text("Something went wrong"));

  Widget _buildLoaded(PageState state) {
    return Column(
      children: [
        _buildHeader(state),
        TextField(controller: _controller),
        _buildActions(),
      ],
    );
  }

  Widget _buildHeader(PageState state) =>
      Text('Header', style: Theme.of(context).textTheme.titleLarge);

  Widget _buildActions() => ElevatedButton(
        onPressed: _complexAction,
        child: Text('Submit', style: Theme.of(context).textTheme.labelLarge),
      );
}

```

---