```dart
// ============================================================
// AUTH_GATE.DART
// ============================================================
//
// PURPOSE OF THIS FILE:
//
// AuthGate is the "traffic controller" for authentication.
//
// When the application starts, this widget asks:
//
//   1. Is somebody currently logged in?
//   2. If nobody is logged in:
//        -> show LoginScreen
//
//   3. If somebody IS logged in:
//        -> find out whether they are a "student" or "admin"
//
//   4. If they are a student:
//        -> show MainScreen
//
//   5. If they are an admin:
//        -> show AdminDashboard
//
//   6. If something goes wrong:
//        -> show an error screen
//
// So conceptually:
//
//                  App starts
//                      |
//                      v
//                 AuthGate
//                      |
//              Is user logged in?
//                /            \
//              NO              YES
//              |                |
//              v                v
//        LoginScreen       Load user's role
//                              |
//                       /------+------\
//                      /       |       \
//                 student     admin    invalid
//                    |          |         |
//                    v          v         v
//               MainScreen  AdminDash  ErrorScreen
//
// This file is therefore a bridge between:
//      Flutter UI
//          +
//      Supabase authentication
//          +
//      Supabase database
//          +
//      the rest of the application.
//
// ============================================================


// ------------------------------------------------------------
// IMPORTS
// ------------------------------------------------------------

// Dart has a built-in library called "async".
//
// "async" contains tools for asynchronous programming.
//
// Asynchronous programming is important when our application
// has to wait for something that takes time, such as:
//
//   - talking to Supabase
//   - reading from a database
//   - waiting for authentication changes
//   - making a network request
//
// "StreamSubscription" later in this file comes from this
// library.
import 'dart:async';


// This imports the LoginScreen widget from our own application.
//
// The package name "campus_app" comes from pubspec.yaml.
//
// The path:
//
//     auth/login_screen.dart
//
// means:
//
//     lib/
//       auth/
//         login_screen.dart
//
// Flutter/Dart lets us import files from our own project this way.
import 'package:campus_app/auth/login_screen.dart';


// Import the screen that administrators see.
import 'package:campus_app/screens/admin_dashboard.dart';


// Flutter's Material library.
//
// Material provides Flutter's standard UI building blocks,
// such as:
//
//   Scaffold
//   Text
//   Icon
//   FilledButton
//   TextButton
//   CircularProgressIndicator
//   Theme
//
// It also provides important Flutter classes such as:
//
//   Widget
//   BuildContext
//   StatefulWidget
//   StatelessWidget
//   State
//
// Basically, a large part of the Flutter UI framework we use
// in this file comes from this import.
import 'package:flutter/material.dart';


// This imports Supabase's Flutter library.
//
// Supabase is the backend service this application is using.
//
// It provides things such as:
//
//   - authentication
//   - database access
//   - sessions
//   - users
//   - realtime events
//
// The ".dart" file isn't something we created.
// It comes from the Supabase Flutter package installed through
// pubspec.yaml.
import 'package:supabase_flutter/supabase_flutter.dart';


// Import the main screen for normal/student users.
import 'package:campus_app/screens/main_screen.dart';


// ============================================================
// AUTH GATE
// ============================================================
//
// "class" means we are defining a new type/object.
//
// This class is named AuthGate.
//
// "extends StatefulWidget" means AuthGate is a Flutter widget
// that is allowed to have mutable state.
//
// STATE means information that can change while the app runs.
//
// For example:
//
//     user logged out
//          ↓
//     user logged in
//
// The AuthGate needs to react to that change.
//
// Because its information can change, we use StatefulWidget
// instead of StatelessWidget.
//
// ============================================================

class AuthGate extends StatefulWidget {

  // Constructor for AuthGate.
  //
  // "const" means that when possible, Flutter can create this
  // widget as a compile-time constant.
  //
  // "{super.key}" is named-parameter syntax.
  //
  // A "Key" helps Flutter identify widgets when rebuilding
  // widget trees.
  //
  // We don't personally need a key here, but StatefulWidget
  // supports one.
  const AuthGate({super.key});


  // ----------------------------------------------------------
  // createState()
  // ----------------------------------------------------------
  //
  // Every StatefulWidget needs to create an associated State
  // object.
  //
  // The widget itself:
  //
  //     AuthGate
  //
  // owns the configuration.
  //
  // The State object:
  //
  //     _AuthGateState
  //
  // stores the information that changes over time.
  //
  // The underscore "_" at the beginning means this class is
  // private to this Dart file/library.
  //
  // So other files cannot directly access _AuthGateState.
  //
  // "override" means StatefulWidget already defines a
  // createState() method, and we are providing our own
  // implementation of it.
  @override
  State<AuthGate> createState() => _AuthGateState();
}


// ============================================================
// AUTH GATE STATE
// ============================================================
//
// This is where the actual changing information for AuthGate
// is stored.
//
// State<AuthGate> means:
//
// "This State object belongs to an AuthGate widget."
//
// ============================================================

class _AuthGateState extends State<AuthGate> {


  // ----------------------------------------------------------
  // SUPABASE CLIENT
  // ----------------------------------------------------------
  //
  // A "client" is an object that knows how to communicate
  // with a particular service.
  //
  // SupabaseClient is the object we use to communicate with
  // our Supabase backend.
  //
  // Supabase.instance.client means:
  //
  // "Give me the already-initialized Supabase client."
  //
  // The application normally initializes Supabase somewhere
  // before AuthGate is used, usually in main.dart.
  //
  // "final" means this variable can only be assigned once.
  //
  // It does NOT mean the object itself can never change.
  // It means the variable cannot point to a different object.
  //
  // "_supabase" begins with "_" because it is private to this
  // Dart file.
  final SupabaseClient _supabase = Supabase.instance.client;


  // ----------------------------------------------------------
  // AUTHENTICATION STREAM SUBSCRIPTION
  // ----------------------------------------------------------
  //
  // Supabase can provide a Stream of authentication events.
  //
  // A Stream is basically a source that can produce multiple
  // values/events over time.
  //
  // For example:
  //
  //     user logs in
  //          ↓
  //     auth event
  //
  //     user logs out
  //          ↓
  //     auth event
  //
  //     session refreshes
  //          ↓
  //     auth event
  //
  // StreamSubscription represents our connection/listener
  // to that stream.
  //
  // The "?":
  //
  //     StreamSubscription<AuthState>?
  //
  // means the variable is allowed to contain null.
  //
  // Dart has "null safety", meaning Dart makes us explicitly
  // say when something may not exist.
  //
  // Initially, there is no subscription yet, so null is
  // appropriate.
  StreamSubscription<AuthState>? _authSubscription;


  // ----------------------------------------------------------
  // CURRENT USER SESSION
  // ----------------------------------------------------------
  //
  // A Supabase Session represents the current authenticated
  // session.
  //
  // It contains information about the authenticated user and
  // authentication tokens/session information.
  //
  // If nobody is logged in:
  //
  //     _session == null
  //
  // If somebody is logged in:
  //
  //     _session != null
  //
  // Again, the "?" means this variable can be null.
  Session? _session;


  // ----------------------------------------------------------
  // ROLE REQUEST
  // ----------------------------------------------------------
  //
  // This stores a Future<String>.
  //
  // A Future represents a value that will become available
  // later.
  //
  // For example, Supabase needs to go to the database and ask:
  //
  //     "What role does this user have?"
  //
  // We don't immediately know the answer.
  //
  // So instead we get a Future<String>.
  //
  // Eventually the Future will contain something like:
  //
  //     "student"
  //
  // or:
  //
  //     "admin"
  //
  // The "?" means this Future itself can be null.
  //
  // Before we need to load a role, there may be no request.
  Future<String>? _roleRequest;


  // ----------------------------------------------------------
  // AUTHENTICATION STREAM ERROR
  // ----------------------------------------------------------
  //
  // Object? means:
  //
  // "This variable may contain any kind of Dart object,
  // including an error, or it may be null."
  //
  // We use it to remember if listening to Supabase's
  // authentication stream caused an error.
  //
  // null means:
  //
  //     "There is currently no authentication stream error."
  //
  Object? _authStreamError;


  // ==========================================================
  // initState()
  // ==========================================================
  //
  // initState() is a special Flutter lifecycle method.
  //
  // A lifecycle method is a method Flutter calls automatically
  // at a particular point in a widget's life.
  //
  // initState() runs once when this State object is first
  // created.
  //
  // It is commonly used for:
  //
  //   - initializing variables
  //   - starting subscriptions
  //   - starting API/database requests
  //   - setting up listeners
  //
  // It should NOT normally be used to build UI.
  //
  // ==========================================================

  @override
  void initState() {
    // Call the implementation from the parent State class.
    //
    // It is important to call super.initState().
    super.initState();


    // --------------------------------------------------------
    // GET CURRENT SESSION
    // --------------------------------------------------------
    //
    // Supabase's auth.currentSession gives us the session
    // that currently exists.
    //
    // This is different from waiting for a future auth event.
    //
    // We are asking immediately:
    //
    //     "Do we already have a logged-in user?"
    //
    // The result can be:
    //
    //     Session object
    //
    // OR:
    //
    //     null
    //
    _session = _supabase.auth.currentSession;


    // --------------------------------------------------------
    // LOAD THE ROLE IF A USER IS ALREADY LOGGED IN
    // --------------------------------------------------------
    //
    // The "if" checks whether _session is NOT null.
    //
    // "!=" means "not equal to".
    //
    // So:
    //
    //     if (_session != null)
    //
    // means:
    //
    //     "If there is currently a logged-in session..."
    //
    if (_session != null) {

      // _session!.user.id
      //
      // The "!" is called the "null assertion operator".
      //
      // We just checked:
      //
      //     _session != null
      //
      // so we know it exists at this point.
      //
      // The "!" tells Dart:
      //
      //     "I guarantee this is not null."
      //
      // ".user" gets the Supabase User object.
      //
      // ".id" gets that user's unique ID.
      //
      // Then we pass that ID to _loadRole().
      //
      // _loadRole() returns a Future<String>.
      //
      // That Future is saved in _roleRequest.
      _roleRequest = _loadRole(_session!.user.id);
    }


    // ========================================================
    // LISTEN FOR AUTHENTICATION CHANGES
    // ========================================================
    //
    // Supabase provides:
    //
    //     _supabase.auth.onAuthStateChange
    //
    // This is a Stream.
    //
    // We use ".listen()" to subscribe to it.
    //
    // Every time Supabase tells us authentication changed,
    // the function inside listen() gets called.
    //
    // The returned StreamSubscription is saved so that we can
    // cancel it later when this widget is destroyed.
    //
    // This is extremely important because leaving a listener
    // active after a widget is destroyed can cause memory leaks
    // or callbacks trying to update widgets that no longer exist.
    //
    _authSubscription = _supabase.auth.onAuthStateChange.listen(

      // ------------------------------------------------------
      // AUTH EVENT CALLBACK
      // ------------------------------------------------------
      //
      // This function is called whenever Supabase reports an
      // authentication state change.
      //
      // authState contains information about the event.
      //
      // For example, the event might represent:
      //
      //     signedIn
      //     signedOut
      //     tokenRefreshed
      //     etc.
      //
      (authState) {

        // ----------------------------------------------------
        // CHECK WHETHER THE WIDGET STILL EXISTS
        // ----------------------------------------------------
        //
        // "mounted" is a property provided by Flutter's State
        // class.
        //
        // mounted == true:
        //     this State object is currently attached to the
        //     widget tree.
        //
        // mounted == false:
        //     the widget has been removed/destroyed.
        //
        // If the widget is gone, we should NOT call setState().
        //
        // "return" exits this callback immediately.
        //
        if (!mounted) return;


        // ----------------------------------------------------
        // REMEMBER THE PREVIOUS USER
        // ----------------------------------------------------
        //
        // We save the current user's ID before replacing the
        // session.
        //
        // "_session?.user.id"
        //
        // The "?" here is called the null-aware access operator.
        //
        // If _session is null:
        //
        //     _session?.user.id
        //
        // evaluates to null instead of crashing.
        //
        // If _session exists:
        //
        //     it gets user.id.
        //
        final previousUserId = _session?.user.id;


        // Get the session from the new authentication event.
        //
        // The event's session can also be null.
        //
        // For example, after logout:
        //
        //     authState.session == null
        //
        final nextSession = authState.session;


        // ----------------------------------------------------
        // UPDATE FLUTTER STATE
        // ----------------------------------------------------
        //
        // setState() tells Flutter:
        //
        //     "Some information used by my UI changed.
        //      Rebuild this widget."
        //
        // Without setState(), changing the variables here
        // would not necessarily cause Flutter to redraw the
        // screen.
        //
        setState(() {

          // A successful auth state event means we no longer
          // want to display the previous auth-stream error.
          _authStreamError = null;


          // Replace the old session with the new one.
          _session = nextSession;


          // --------------------------------------------------
          // IF THE USER LOGGED OUT
          // --------------------------------------------------
          //
          // If nextSession is null, there is no authenticated
          // user.
          //
          // Therefore we don't need a role request anymore.
          //
          if (nextSession == null) {
            _roleRequest = null;


          // --------------------------------------------------
          // IF THERE IS A NEW/DIFFERENT USER
          // --------------------------------------------------
          //
          // This condition has two parts.
          //
          // Part 1:
          //
          //     previousUserId != nextSession.user.id
          //
          // This asks:
          //
          //     "Is this a different user?"
          //
          // OR:
          //
          // Part 2:
          //
          //     _roleRequest == null
          //
          // This asks:
          //
          //     "Do we not currently have a role request?"
          //
          // "||" means OR.
          //
          // Therefore:
          //
          //     if user changed OR there is no role request
          //
          // then load the user's role.
          //
          } else if (previousUserId != nextSession.user.id ||
              _roleRequest == null) {

            // Start a database request to retrieve the new
            // user's role.
            _roleRequest = _loadRole(nextSession.user.id);
          }
        });
      },


      // ======================================================
      // ERROR CALLBACK
      // ======================================================
      //
      // listen() can also receive an onError callback.
      //
      // If the authentication stream itself produces an error,
      // this function runs.
      //
      // "Object error" means the error can be various types.
      //
      // "StackTrace" contains information about where in the
      // program the error happened.
      //
      onError: (Object error, StackTrace stackTrace) {

        // Again, don't update a widget that has already been
        // removed from the widget tree.
        if (!mounted) return;


        // Tell Flutter that our state has changed.
        setState(() {

          // Save the error so build() can display an error
          // screen.
          _authStreamError = error;
        });
      },
    );
  }


  // ==========================================================
  // _loadRole()
  // ==========================================================
  //
  // This function asks Supabase:
  //
  //     "What role does this user have?"
  //
  // It is asynchronous because it has to communicate with
  // Supabase over the network.
  //
  // "Future<String>" means:
  //
  //     "This function will eventually produce a String."
  //
  // Example:
  //
  //     Future<String>
  //             |
  //             v
  //        "student"
  //
  // or:
  //
  //        "admin"
  //
  // ==========================================================

  Future<String> _loadRole(String userId) async {

    // --------------------------------------------------------
    // QUERY THE SUPABASE DATABASE
    // --------------------------------------------------------
    //
    // This chain constructs a database query.
    //
    // Let's break it down:
    //
    //     _supabase
    //
    // is our Supabase client.
    //
    //     .from('profiles')
    //
    // says:
    //
    //     "Work with the profiles table."
    //
    //     .select('role')
    //
    // says:
    //
    //     "Retrieve the role column."
    //
    //     .eq('id', userId)
    //
    // means:
    //
    //     "Only return the row where the id column equals
    //      this user's ID."
    //
    // eq = equals.
    //
    //     .single()
    //
    // says:
    //
    //     "I expect exactly one row."
    //
    // Because this is a network/database operation, Dart
    // needs to wait for the response.
    //
    // --------------------------------------------------------
    //
    // "await" means:
    //
    //     "Pause this asynchronous function until the result
    //      is available, without blocking the entire app."
    //
    // This distinction is important.
    //
    // The application UI can continue operating while this
    // network request is happening.
    //
    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();


    // --------------------------------------------------------
    // GET THE ROLE FROM THE DATABASE RESULT
    // --------------------------------------------------------
    //
    // profile is essentially a map/dictionary containing the
    // returned database columns.
    //
    // For example, the database might return something like:
    //
    //     {
    //       "role": "student"
    //     }
    //
    // profile['role']
    //
    // gets the value associated with the "role" key.
    //
    // "as String?" tells Dart:
    //
    //     "Treat this value as a nullable String."
    //
    // So role can be:
    //
    //     "student"
    //     "admin"
    //     null
    //
    final role = profile['role'] as String?;


    // --------------------------------------------------------
    // VALIDATE THE ROLE
    // --------------------------------------------------------
    //
    // We don't want the application to continue if the role
    // doesn't exist.
    //
    // This condition checks TWO things:
    //
    //     role == null
    //
    // OR:
    //
    //     role.isEmpty
    //
    // "||" means OR.
    //
    if (role == null || role.isEmpty) {

      // "throw" means:
      //
      //     "Stop this operation and report an error."
      //
      // StateError is a Dart error type used when something
      // is in an invalid state.
      //
      // In this case:
      //
      //     The user exists,
      //     but the application cannot find a valid role.
      //
      throw StateError('No account role was found for this user.');
    }


    // Return the role to whoever called _loadRole().
    //
    // This completes the Future<String>.
    //
    // Example:
    //
    //     return "student";
    //
    // The Future now successfully contains "student".
    return role;
  }


  // ==========================================================
  // RETRY ROLE LOOKUP
  // ==========================================================
  //
  // This function is called when the user presses:
  //
  //     "Try again"
  //
  // after a role-loading error.
  //
  // ==========================================================

  void _retryRoleLookup() {

    // Get the currently logged-in user.
    //
    // Because _session can be null, we use "?."
    //
    // If there is no session:
    //
    //     user == null
    //
    // Otherwise:
    //
    //     user contains the Supabase User.
    //
    final user = _session?.user;


    // If there is no logged-in user, there is nothing to retry.
    //
    // "return" exits the function.
    if (user == null) return;


    // Tell Flutter that state is changing.
    setState(() {

      // Start a completely new role lookup.
      //
      // user.id is the unique ID of the current user.
      //
      // The new Future replaces the previous failed Future.
      _roleRequest = _loadRole(user.id);
    });
  }


  // ==========================================================
  // SIGN OUT
  // ==========================================================
  //
  // This function logs the user out through Supabase.
  //
  // It returns Future<void> because signing out is an
  // asynchronous operation.
  //
  // "void" means there is no useful value returned after the
  // operation completes.
  //
  // ==========================================================

  Future<void> _signOut() async {

    // Ask Supabase to sign out the current user.
    //
    // "await" waits for Supabase to finish the operation.
    await _supabase.auth.signOut();
  }


  // ==========================================================
  // dispose()
  // ==========================================================
  //
  // dispose() is another Flutter lifecycle method.
  //
  // It runs when this State object is permanently removed.
  //
  // It is where we clean up resources.
  //
  // This is particularly important here because we created
  // a StreamSubscription in initState().
  //
  // ==========================================================

  @override
  void dispose() {

    // Cancel the authentication listener.
    //
    // "?." means:
    //
    //     "Only call cancel() if _authSubscription is not null."
    //
    // Without cancelling this subscription, the listener could
    // continue receiving events after AuthGate is destroyed.
    //
    _authSubscription?.cancel();


    // Tell Flutter's parent State class that we are being
    // disposed.
    super.dispose();
  }


  // ==========================================================
  // build()
  // ==========================================================
  //
  // build() is one of the most important Flutter methods.
  //
  // Flutter calls build() whenever the widget needs to produce
  // its UI.
  //
  // The method returns a Widget.
  //
  // Think of build() as:
  //
  //     "Given the current state of the application,
  //      what should be displayed on the screen?"
  //
  // ==========================================================

  @override
  Widget build(BuildContext context) {


    // --------------------------------------------------------
    // CASE 1: NO LOGGED-IN USER
    // --------------------------------------------------------
    //
    // If _session is null, nobody is logged in.
    //
    // Therefore we show the LoginScreen.
    //
    if (_session == null) {
      return const LoginScreen();
    }


    // --------------------------------------------------------
    // CASE 2: AUTH STREAM ERROR
    // --------------------------------------------------------
    //
    // If _authStreamError isn't null, something went wrong
    // while listening for authentication changes.
    //
    if (_authStreamError != null) {

      // Display our custom error screen.
      return _ErrorScreen(

        // Text displayed as the error title.
        title: 'Authentication error',

        // Convert the error object into text.
        //
        // ".toString()" produces a String representation.
        message: _authStreamError.toString(),

        // Pass the retry function into the error screen.
        //
        // This is a CALLBACK.
        //
        // A callback is simply a function given to another
        // piece of code so that it can call it later.
        onRetry: _retryRoleLookup,

        // Give the error screen our sign-out function.
        onSignOut: _signOut,
      );
    }


    // ========================================================
    // FUTURE BUILDER
    // ========================================================
    //
    // At this point:
    //
    //     - we have a logged-in user
    //     - there is no auth stream error
    //
    // But we still need to know the user's role.
    //
    // _roleRequest is a Future<String>.
    //
    // FutureBuilder is a Flutter widget specifically designed
    // to build different UI depending on the state of a Future.
    //
    // There are essentially three stages:
    //
    //     1. Future is still running
    //
    //     2. Future finished successfully
    //
    //     3. Future finished with an error
    //
    // ========================================================

    return FutureBuilder<String>(

      // Give FutureBuilder the Future we want it to watch.
      future: _roleRequest,


      // ------------------------------------------------------
      // BUILDER CALLBACK
      // ------------------------------------------------------
      //
      // Flutter calls this function whenever the Future's
      // state changes.
      //
      // "context" tells Flutter where this widget exists in
      // the widget tree.
      //
      // "snapshot" contains information about the Future.
      //
      // A snapshot can tell us things such as:
      //
      //     Has it finished?
      //     Did it produce an error?
      //     What data did it return?
      //
      builder: (context, snapshot) {


        // ----------------------------------------------------
        // FUTURE IS STILL RUNNING
        // ----------------------------------------------------
        //
        // connectionState tells us the state of the Future.
        //
        // ConnectionState.done means the Future finished.
        //
        // So:
        //
        //     != ConnectionState.done
        //
        // means:
        //
        //     "The Future hasn't finished yet."
        //
        if (snapshot.connectionState != ConnectionState.done) {

          // Show a loading spinner.
          return const _LoadingScreen();
        }


        // ----------------------------------------------------
        // FUTURE FINISHED WITH AN ERROR
        // ----------------------------------------------------
        //
        // snapshot.hasError tells us whether the Future
        // completed unsuccessfully.
        //
        if (snapshot.hasError) {

          // Display our custom error screen.
          return _ErrorScreen(
            title: 'Unable to load account',

            // Explain what happened.
            //
            // ${...} is string interpolation.
            //
            // It inserts a value into a String.
            message:
                'The app could not retrieve this user’s student or admin role.\n\n'
                '${snapshot.error}',

            // Let the user retry.
            onRetry: _retryRoleLookup,

            // Let the user sign out.
            onSignOut: _signOut,
          );
        }


        // ====================================================
        // FUTURE SUCCESSFULLY RETURNED A ROLE
        // ====================================================
        //
        // snapshot.data contains the value returned by the
        // Future.
        //
        // In our case:
        //
        //     "student"
        //
        // or:
        //
        //     "admin"
        //
        // We use a switch statement to decide what screen
        // should be displayed.
        //
        switch (snapshot.data) {


          // --------------------------------------------------
          // STUDENT
          // --------------------------------------------------
          //
          // If the role is exactly "student":
          //
          // show MainScreen.
          //
          case 'student':
            return const MainScreen();


          // --------------------------------------------------
          // ADMIN
          // --------------------------------------------------
          //
          // If the role is exactly "admin":
          //
          // show AdminDashboard.
          //
          case 'admin':
            return const AdminDashboard();


          // --------------------------------------------------
          // ANYTHING ELSE
          // --------------------------------------------------
          //
          // "default" catches every value that wasn't handled
          // above.
          //
          // For example:
          //
          //     "teacher"
          //     "unknown"
          //     null
          //     "administrator"
          //
          // would reach this section.
          //
          default:
            return _ErrorScreen(
              title: 'Invalid account role',

              // Tell the user the account doesn't have one
              // of the roles this application understands.
              message:
                  'This account does not have a valid student or admin role.',

              // Allow another database lookup.
              onRetry: _retryRoleLookup,

              // Allow the user to sign out.
              onSignOut: _signOut,
            );
        }
      },
    );
  }
}


// ============================================================
// LOADING SCREEN
// ============================================================
//
// This is a private widget because its class name starts with
// "_".
//
// It extends StatelessWidget because its UI doesn't contain
// any changing state.
//
// Its only job is to display a loading spinner.
//
// ============================================================

class _LoadingScreen extends StatelessWidget {

  // Constructor.
  //
  // const is appropriate because this widget has no mutable
  // configuration/state.
  const _LoadingScreen();


  // Every StatelessWidget must implement build().
  @override
  Widget build(BuildContext context) {

    // Scaffold provides a basic Material page structure.
    //
    // It gives us things such as a body area.
    return const Scaffold(

      // body is the main content of the page.
      body: Center(

        // Center places its child in the center of the available
        // space.
        child: CircularProgressIndicator(),
      ),
    );
  }
}


// ============================================================
// ERROR SCREEN
// ============================================================
//
// This widget displays errors encountered by AuthGate.
//
// It is reusable because AuthGate can encounter different
// errors.
//
// Instead of writing the entire error UI multiple times,
// we create one widget:
//
//     _ErrorScreen
//
// and give it different:
//
//     title
//     message
//     onRetry
//     onSignOut
//
// ============================================================

class _ErrorScreen extends StatelessWidget {


  // ----------------------------------------------------------
  // CONSTRUCTOR
  // ----------------------------------------------------------
  //
  // "required" means whoever creates _ErrorScreen MUST provide
  // these values.
  //
  // Example:
  //
  //     _ErrorScreen(
  //       title: 'Something went wrong',
  //       message: '...',
  //       onRetry: someFunction,
  //       onSignOut: anotherFunction,
  //     )
  //
  // Named parameters make code easier to read than positional
  // parameters.
  //
  const _ErrorScreen({
    required this.title,
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });


  // ----------------------------------------------------------
  // DATA USED BY THIS WIDGET
  // ----------------------------------------------------------

  // The title displayed at the top.
  //
  // final means it cannot be changed after the object is
  // created.
  final String title;


  // The longer explanation displayed underneath the title.
  final String message;


  // Function to call when the user presses "Try again".
  //
  // VoidCallback is a Flutter/Dart type representing a function
  // that:
  //
  //     takes no arguments
  //     returns nothing
  //
  // Essentially:
  //
  //     () -> void
  //
  final VoidCallback onRetry;


  // Function to call when the user presses "Sign out".
  //
  // This function is asynchronous, so it returns:
  //
  //     Future<void>
  //
  // rather than just void.
  final Future<void> Function() onSignOut;


  // ==========================================================
  // BUILD THE ERROR SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    // Scaffold creates the basic Material screen.
    return Scaffold(

      // SafeArea prevents content from being hidden behind
      // things such as:
      //
      //     notches
      //     status bars
      //     system UI
      //
      body: SafeArea(

        // Center puts the entire error content in the center
        // of the screen.
        child: Center(

          // SingleChildScrollView allows the content to scroll
          // if the error message becomes too large for the
          // available screen height.
          child: SingleChildScrollView(

            // Padding adds 24 logical pixels of space around
            // the content.
            padding: const EdgeInsets.all(24),

            // Column arranges widgets vertically.
            child: Column(

              // Normally a Column tries to take available
              // vertical space.
              //
              // mainAxisSize.min tells it:
              //
              // "Only be as tall as your children require."
              //
              mainAxisSize: MainAxisSize.min,

              // The children are the widgets inside the Column.
              children: [


                // ------------------------------------------------
                // ERROR ICON
                // ------------------------------------------------
                //
                // const means this Icon can be created as a
                // compile-time constant.
                //
                const Icon(
                  Icons.error_outline,

                  // Size of the icon.
                  size: 64,
                ),


                // ------------------------------------------------
                // SPACE
                // ------------------------------------------------
                //
                // SizedBox creates empty space.
                //
                // Here it creates 20 pixels of vertical space.
                const SizedBox(height: 20),


                // ------------------------------------------------
                // ERROR TITLE
                // ------------------------------------------------
                //
                // Text displays a string.
                Text(
                  title,

                  // Center-align the title.
                  textAlign: TextAlign.center,

                  // Get the application's current theme and
                  // use its "headlineSmall" text style.
                  //
                  // ?. means:
                  //
                  // "If headlineSmall exists, continue."
                  //
                  // If it doesn't, the result is null.
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(

                    // Make the title bold.
                    fontWeight: FontWeight.bold,
                  ),
                ),


                // More vertical space.
                const SizedBox(height: 12),


                // ------------------------------------------------
                // ERROR MESSAGE
                // ------------------------------------------------
                //
                // Display the actual explanation of the error.
                Text(
                  message,

                  // Center-align the message.
                  textAlign: TextAlign.center,
                ),


                // More vertical space.
                const SizedBox(height: 24),


                // ------------------------------------------------
                // RETRY BUTTON
                // ------------------------------------------------
                //
                // FilledButton is a Material button with a filled
                // background.
                FilledButton(

                  // onPressed expects a function.
                  //
                  // We give it the callback that AuthGate passed
                  // into this widget.
                  //
                  // When the user taps this button:
                  //
                  //     onRetry()
                  //
                  // is executed by Flutter.
                  onPressed: onRetry,

                  // The child is the content inside the button.
                  child: const Text('Try again'),
                ),


                // ------------------------------------------------
                // SIGN OUT BUTTON
                // ------------------------------------------------
                //
                // TextButton is a less visually prominent button.
                TextButton(

                  // Call the asynchronous sign-out function when
                  // the user presses the button.
                  onPressed: onSignOut,

                  // Text displayed inside the button.
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
