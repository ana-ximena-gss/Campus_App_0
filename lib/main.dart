// This imports the AuthGate class from another file in our project.
//
// "import" means we are bringing code from another file/package
// into this file so that we can use it.
//
// The path starts with "package:campus_app" because this is code
// from our own Flutter project.
//
// AuthGate will eventually decide which screen the user should see
// based on whether they are logged in and what type of user they are.
import 'package:campus_app/auth/auth_gate.dart';


// This imports Flutter's Material Design library.
//
// Flutter is the framework we are using to build the application.
//
// The Material library gives us many of the basic Flutter classes
// used to create the user interface, such as:
//
// - Widget
// - StatelessWidget
// - MaterialApp
// - Scaffold
// - Text
// - Icon
// - Column
// - etc.
//
// "as" is not being used here. The library is imported normally,
// so we can directly use its classes.
import 'package:flutter/material.dart';


// This imports Riverpod.
//
// Riverpod is a state-management package.
//
// "State" means information that can change while the application
// is running.
//
// Examples of state in our app could be:
//
// - whether a user is logged in
// - which activities exist
// - which activity the user selected
// - information loaded from Supabase
//
// ProviderScope, which we use later, comes from Riverpod.
import 'package:flutter_riverpod/flutter_riverpod.dart';


// This imports the Mapbox Flutter package.
//
// Mapbox provides the map functionality for our application.
//
// This allows us to use things such as:
//
// - maps
// - map markers
// - map locations
// - map controls
//
// We need to give Mapbox an access token before we can use it.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';


// This imports the Supabase Flutter package.
//
// Supabase is the backend service used by this application.
//
// The backend is the part of an application that handles things
// behind the scenes, such as:
//
// - user authentication
// - databases
// - storing information
// - communicating with the server
//
// In this project, Supabase is responsible for things such as
// logging users in and storing application data.
import 'package:supabase_flutter/supabase_flutter.dart';


// "main" is the starting point of a Dart program.
//
// When we run our Flutter application, execution starts here.
//
// The parentheses "()" mean that main is a function.
//
// "Future<void>" tells us two important things:
//
// "Future"
// --------
// A Future represents a value or result that will become available
// later.
//
// This is needed because some of the things we do while starting
// the application take time, such as connecting to Supabase.
//
// "void"
// ------
// This means that the function does not return a useful value.
//
// So:
//
// Future<void> main()
//
// basically means:
//
// "Start the program, perform some work that may take time,
// and don't return a value when finished."
Future<void> main() async {

  // Flutter normally needs to prepare its framework before we
  // perform certain operations before runApp().
  //
  // "WidgetsFlutterBinding" is part of Flutter's system that
  // connects our Dart code with the Flutter framework.
  //
  // "ensureInitialized()" makes sure that this connection has
  // been initialized before we continue.
  //
  // This is especially important because we are doing setup
  // before calling runApp().
  WidgetsFlutterBinding.ensureInitialized();


  // "const" means this value is a compile-time constant.
  //
  // A constant is a value that is known ahead of time and
  // cannot change.
  //
  // "mapboxToken" is the name of the variable.
  //
  // A variable is a named place where we store a value.
  //
  // "String" means the value is text.
  //
  // String.fromEnvironment() reads a value that was provided
  // when the application was started/built.
  //
  // Here we are looking for a value called:
  //
  // ACCESS_TOKEN
  //
  // The Mapbox token is therefore not written directly into
  // this line of code. Instead, it is supplied when running
  // the application using --dart-define.
  const mapboxToken = String.fromEnvironment('ACCESS_TOKEN');


  // This checks whether the Mapbox token is missing.
  //
  // ".isEmpty" checks whether a String contains zero characters.
  //
  // For example:
  //
  // ''.isEmpty
  //
  // is true.
  //
  // While:
  //
  // 'hello'.isEmpty
  //
  // is false.
  //
  // "if" means:
  //
  // "Only execute the code inside these braces if this condition
  // is true."
  if (mapboxToken.isEmpty) {

    // runApp() is one of the most important Flutter functions.
    //
    // It starts the Flutter user interface.
    //
    // Whatever Widget we give to runApp() becomes the root
    // (top-level) widget of the application.
    //
    // Here we are NOT starting the normal application.
    //
    // Instead, we are starting a special screen that tells the
    // developer that the Mapbox token is missing.
    runApp(

      // ProviderScope comes from Riverpod.
      //
      // Riverpod uses ProviderScope as the area in which its
      // providers and state can be accessed.
      //
      // You can think of it as setting up Riverpod for the
      // application underneath it.
      //
      // Any widgets inside ProviderScope can use Riverpod.
      const ProviderScope(

        // "child" means:
        //
        // "Put this widget inside ProviderScope."
        //
        // Our child is MissingMapboxTokenApp.
        child: MissingMapboxTokenApp(),
      ),
    );


    // "return" stops the current function.
    //
    // This is important here.
    //
    // We discovered that the Mapbox token is missing, so there
    // is no reason to continue initializing Mapbox and Supabase.
    //
    // Without this return, the program would continue running
    // the code below.
    return;
  }


  // At this point, we know the Mapbox token exists.
  //
  // MapboxOptions is a class provided by the Mapbox package.
  //
  // ".setAccessToken()" is a method (a function belonging to
  // an object/class) that tells Mapbox which access token to use.
  //
  // We give it the token we retrieved above.
  //
  // After this line, Mapbox knows which token it should use
  // when our application communicates with Mapbox.
  MapboxOptions.setAccessToken(mapboxToken);


  // Now we initialize Supabase.
  //
  // "await" is important here.
  //
  // Supabase.initialize() performs asynchronous work.
  //
  // Asynchronous work means work that can take some amount of
  // time to finish, such as communicating with a server.
  //
  // "await" means:
  //
  // "Wait for this operation to finish before continuing."
  //
  // Without await, the application could continue before
  // Supabase has finished setting itself up.
  await Supabase.initialize(

    // "url" tells the Supabase package where our Supabase project
    // is located.
    //
    // This is the URL of our project's Supabase backend.
    url: 'https://njtpfiigzvxytwivipxs.supabase.co',


    // "anonKey" is the public client key used by this application
    // to communicate with Supabase.
    //
    // Supabase uses keys and its security rules to determine
    // what the application is allowed to access.
    //
    // Important distinction:
    //
    // This is a client-side/public key, not a secret server key.
    // Actual access should still be protected by Supabase's
    // authentication and Row Level Security rules.
    anonKey: 'sb_publishable_yJkW8eLqJ9Vod48IthOSQw_x_tSWc8c',
  );


  // Now that Flutter, Mapbox, and Supabase have been prepared,
  // we can finally start our actual application.
  runApp(

    // Again, ProviderScope gives the application access to
    // Riverpod.
    //
    // Everything inside ProviderScope can use Riverpod providers.
    const ProviderScope(

      // CampusApp is our actual main application widget.
      child: CampusApp(),
    ),
  );
}


// This creates a class called CampusApp.
//
// A class is a blueprint for creating an object.
//
// In Flutter, we use classes to define things such as widgets.
//
// "extends ConsumerWidget" means CampusApp is a type of
// Flutter widget that inherits behavior from ConsumerWidget.
//
// "ConsumerWidget" is provided by Riverpod.
//
// Unlike a normal StatelessWidget, ConsumerWidget gives us
// access to Riverpod inside the build() method.
//
// This will become useful when parts of the application need
// to read information managed by Riverpod.
class CampusApp extends ConsumerWidget {


  // This is the constructor for CampusApp.
  //
  // A constructor is used when creating an instance/object
  // of a class.
  //
  // "const" means Flutter can create this widget as a constant
  // when possible, which can improve efficiency.
  //
  // "{super.key}" is a named parameter.
  //
  // "key" is something Flutter uses to identify widgets when
  // it needs to keep track of them in the widget tree.
  //
  // "super.key" passes that key to the parent class,
  // ConsumerWidget.
  const CampusApp({super.key});


  // "build" is one of the most important methods in Flutter.
  //
  // A widget's build() method describes what its user interface
  // should look like.
  //
  // Flutter calls build() when it needs to create or rebuild
  // the widget's UI.
  //
  // "BuildContext context"
  // ----------------------
  // BuildContext gives Flutter information about where this
  // widget exists in the widget tree.
  //
  // "WidgetRef ref"
  // --------------
  // WidgetRef comes from Riverpod.
  //
  // It allows this widget to interact with Riverpod providers.
  //
  // We don't currently use "ref" inside this build method,
  // but it is available because CampusApp is a ConsumerWidget.
  @override
  Widget build(BuildContext context, WidgetRef ref) {


    // MaterialApp is the main application widget for a
    // Material Design Flutter application.
    //
    // It sets up important things for the application, including:
    //
    // - navigation
    // - themes
    // - application title
    // - the first screen
    //
    // The widget returned from build() becomes part of our
    // application's widget tree.
    return MaterialApp(


      // This is the name of the application.
      //
      // It can be used by the operating system or other parts
      // of the Flutter application as the application's title.
      title: 'UTRGV Campus App',


      // Flutter normally shows a small "DEBUG" banner in the
      // upper-right corner while running a debug build.
      //
      // Setting this to false removes that banner.
      debugShowCheckedModeBanner: false,


      // "theme" controls the visual appearance of the application.
      //
      // ThemeData is an object containing visual settings that
      // can be shared throughout the application.
      theme: ThemeData(


        // Flutter supports Material 3, which is a newer version
        // of Google's Material Design system.
        //
        // true means we want to use Material 3 styling.
        useMaterial3: true,


        // colorSchemeSeed gives Flutter a starting color.
        //
        // Flutter uses this color to generate a color scheme
        // for different UI elements throughout the application.
        //
        // 0xFFF05023 is a hexadecimal color value.
        //
        // The first two digits, FF, represent full opacity.
        // The remaining six digits represent the RGB color.
        colorSchemeSeed: const Color(0xFFF05023),
      ),


      // "home" tells MaterialApp which widget should be displayed
      // as the first screen of the application.
      //
      // AuthGate is important because we don't want to immediately
      // show the same screen to every person.
      //
      // AuthGate can determine things such as:
      //
      // - Is the user logged in?
      // - Is the user a student?
      // - Is the user an admin?
      //
      // It can then send the user to the appropriate screen.
      //
      // So the application flow is roughly:
      //
      // main()
      //   ↓
      // CampusApp
      //   ↓
      // AuthGate
      //   ↓
      // Login / Student App / Admin Dashboard
      home: const AuthGate(),
    );
  }
}


// This is another widget.
//
// MissingMapboxTokenApp is displayed when the application
// starts without receiving a Mapbox access token.
//
// It extends StatelessWidget because this particular screen
// does not need to change its own state.
class MissingMapboxTokenApp extends StatelessWidget {


  // Constructor for MissingMapboxTokenApp.
  //
  // "super.key" passes the optional Flutter widget key
  // to StatelessWidget.
  const MissingMapboxTokenApp({super.key});


  // build() describes what this error screen should look like.
  @override
  Widget build(BuildContext context) {


    // MaterialApp creates a small Flutter application for
    // the error screen.
    //
    // We need another MaterialApp here because this widget is
    // being used as the root application when the Mapbox token
    // is missing.
    return MaterialApp(


      // Title for this error application.
      title: 'Missing Configuration',


      // Don't show Flutter's debug banner.
      debugShowCheckedModeBanner: false,


      // Define the theme for this error screen.
      theme: ThemeData(
        useMaterial3: true,
      ),


      // Scaffold provides the basic visual structure of a
      // Material Design screen.
      //
      // A Scaffold can contain things such as:
      //
      // - app bars
      // - body
      // - floating action buttons
      // - navigation drawers
      //
      // Here we only need a body.
      home: const Scaffold(


        // SafeArea prevents the content from being placed
        // underneath system UI such as:
        //
        // - the phone's status bar
        // - a camera/notch area
        // - other system areas
        //
        // This helps make sure our content is visible.
        body: SafeArea(


          // Center places its child in the center of the
          // available space.
          child: Center(


            // Padding adds empty space around its child.
            //
            // "EdgeInsets.all(24)" means add 24 logical pixels
            // of padding on all four sides.
            child: Padding(
              padding: EdgeInsets.all(24),


              // Column places multiple widgets vertically,
              // one above another.
              child: Column(


                // By default, a Column can try to use as much
                // vertical space as possible.
                //
                // MainAxisSize.min tells it:
                //
                // "Only take as much vertical space as your
                // children actually need."
                mainAxisSize: MainAxisSize.min,


                // These are the widgets inside the Column.
                children: [


                  // Icon displays a Material icon.
                  //
                  // Icons.warning_amber_rounded is the specific
                  // warning icon we want to display.
                  //
                  // "size: 64" makes the icon 64 logical pixels
                  // large.
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                  ),


                  // SizedBox creates an empty area with a
                  // specific size.
                  //
                  // Here it creates 20 pixels of vertical space
                  // between the icon and the text.
                  SizedBox(height: 20),


                  // Text displays a piece of text on the screen.
                  Text(
                    'Missing Mapbox configuration',


                    // textAlign controls how the text is aligned.
                    //
                    // TextAlign.center centers the text.
                    textAlign: TextAlign.center,


                    // TextStyle controls how the text looks.
                    style: TextStyle(

                      // Make the text 22 logical pixels tall.
                      fontSize: 22,

                      // FontWeight.bold makes the text bold.
                      fontWeight: FontWeight.bold,
                    ),
                  ),


                  // Another 16 pixels of vertical space.
                  SizedBox(height: 16),


                  // This Text widget explains how to fix the problem.
                  Text(

                    // Adjacent strings in Dart can be placed next
                    // to each other like this.
                    //
                    // Dart combines them into one String:
                    //
                    // "Run the app with the ACCESS_TOKEN
                    // --dart-define value."
                    //
                    // The line break in the source code does not
                    // create a line break in the resulting String.
                    'Run the app with the ACCESS_TOKEN '
                    '--dart-define value.',


                    // Center the error message.
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}