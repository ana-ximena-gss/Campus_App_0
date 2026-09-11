import 'dart:typed_data';
import 'package:campus_app/widgets/logout_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

//Making Data for each markers 
class LocationData {
  final String title;
  final String description;
  final Position coordinates;

  LocationData({
    required this.title,
    required this.description,
    required this.coordinates,
  });
}

class _MapScreenState extends State<MapScreen> {
  static final Point utrgvEdinburgCampus = Point(
    coordinates: Position(
      -98.174165, //logitude
      26.304551,  //latitude
    ),
  );
  
  // Coordinates for UTRGV Brownsville Campus
  static final Point utrgvBrownsvilleCampus = Point(
  coordinates: Position(
    -97.48619, // longitude
    25.89151,  // latitude
  ),
);


  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  //Boolean to track if the user is on the Brownsville campus
  bool _isBrownsville = false;

  ViewportState _viewport = CameraViewportState(
    center: utrgvEdinburgCampus,
    zoom: 16.0,
    pitch: 45.0,
    bearing: 0.0,
  );

  bool _isRequestingLocation = false;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _enableLiveLocation();
    await _addCustomMarkers();  
  }

  //Lists of all the coordinates where to add a marker (W.I.P,)
  final List<LocationData> customLocations = [
    LocationData(
      title: 'Utrgv Sign',
      description: 'A big sign what reads UTRGV', 
      coordinates: Position(-98.177886, 26.304073),
    ),
    LocationData(
    title: 'Utrgv Fountian', 
    description: 'Edinburg Cool looking fountain', 
    coordinates: Position(-98.176061, 26.304802)
    ),
    LocationData(
      title: 'Utrgv Statue',
      description: '[PlaceHolder Fun Fact]',
      coordinates: Position(-98.174068, 26.304240)
    ),
    LocationData(
      title: 'Utrgv Quad',
      description: 'PlaceHolder here :3', 
      coordinates: Position(-98.175415, 26.306487)
    ),
    LocationData(
      title: 'Sundial', 
      description: '[Testing a long description to see how it works if the ai fun facts wants to yap a lot or not lol]', 
      coordinates: Position(-98.170984, 26.306127)
    ),
  ];

  //This Map is to link Mapbox's auto-generated IDs to the custom location data
  final Map<String, LocationData> _annotationDataMap = {};

  Future<void> _addCustomMarkers() async {
    if (_mapboxMap == null) return;

    // Initialize the annotation manager
    _pointAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();

    // Load the custom marker image from the assets folder
    final ByteData bytes = await rootBundle.load('assets/test_marker.png');
    final Uint8List imageData = bytes.buffer.asUint8List();

    // Loop through the list of coords and make a marker for each one & properties
    List<PointAnnotationOptions> allMarkerOptions = customLocations.map((loc) {
      return PointAnnotationOptions(
        geometry: Point(coordinates: loc.coordinates),
        image: imageData,
        iconSize: 0.3,
        textField: loc.title,
        textOffset: [0.0, 1.5],
      );
    }).toList();
    // Add the markers to the map simultaneously & make annotation and IDs
    final annotations = await _pointAnnotationManager?.createMulti(allMarkerOptions);

    // Link the generated ID to locationData
    if (annotations != null) {
      for (int i =0; i < annotations.length; i++) {
        //extract the ID
        final annotationId = annotations[i]?.id;
        //Only add to map if ID does exists
        if (annotationId != null) {
          _annotationDataMap[annotationId] = customLocations[i];
        }
      }
    }

    // Handle using the taps 
    _pointAnnotationManager?.tapEvents(
      onTap: (annotation) {
        //Look up the location marker that was tapped from its ID
        final locationInfo = _annotationDataMap[annotation.id];
        if (locationInfo != null) {
          _showLocationModal(locationInfo);
        }
      }
    );
  }

// Method to slide a modal up from the bottom of the screen
  void _showLocationModal(LocationData data) {
    //Local state for modals counter TEST
    int tapCount = 0;
    bool isUpdating = false;

    showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      // StatefulBuilder allows to update the UI specifically inside the modal
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          //Container for the modal
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  data.description,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                
                //--- Event Table ---
                const Text(
                  'Event Table (W.I.P.)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Hardcoded DataTable here, change this to dynamic por favor :3
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Event Name')),
                    DataColumn(label: Text('Time')),
                  ],
                  rows: const [
                    DataRow(cells: [
                      DataCell(Text('Sample Event 1')),
                      DataCell(Text('11:00 AM')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Sample Event 2')),
                      DataCell(Text('2:00 PM')),
                    ]),
                  ],
                ),

                // --- New Counter Button & UI ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /*Text(   // THIS IS TO TEST THE TAP BUTTON
                      'Taps: $tapCount',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ), */
                    ElevatedButton.icon(
                      onPressed: isUpdating 
                        ? null 
                        : () async {
                            // 1. Show loading state in the modal
                            setModalState(() { isUpdating = true; });
                            
                            // 2. Increment locally
                            tapCount++;

                            /* 3. Update Supabase (IF NEEDED)
                            try {
                              // Assuming you have a table named 'markers' with columns 'title' and 'tap_count'
                              await Supabase.instance.client
                                  .from('markers')
                                  .update({'tap_count': tapCount})
                                  .eq('title', data.title); // Using the title as the identifier
                            } catch (error) {
                              debugPrint('Supabase update failed: $error');
                              // Optional: Revert the counter if the database update fails
                              tapCount--;
                            } */

                            // 4. Hide loading state and refresh modal UI
                            setModalState(() { isUpdating = false; });
                          },
                      icon: isUpdating 
                        ? const SizedBox(
                            width: 16, 
                            height: 16, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Icon(Icons.touch_app),
                      label: const Text('Tap Marker'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      );
    },
  );
}

  Future<void> _enableLiveLocation() async {
    if (_isRequestingLocation) {
      return;
    }

    setState(() {
      _isRequestingLocation = true;
    });

    try {
      final status = await Permission.locationWhenInUse.request();

      if (!mounted) {
        return;
      }

      if (status.isGranted) {
        await _mapboxMap?.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            puckBearingEnabled: true,
            showAccuracyRing: true,
          ),
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _viewport = const FollowPuckViewportState(
            zoom: 17.0,
            pitch: 45.0,
            bearing: FollowPuckViewportStateBearingHeading(),
          );
        });

        return;
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        _showLocationSettingsMessage();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is needed to show your live position.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start live location: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingLocation = false;
        });
      }
    }
  }

void _toggleCampus() {
  setState(() {
    _isBrownsville = !_isBrownsville;

    _viewport = CameraViewportState(
      center: _isBrownsville
          ? utrgvBrownsvilleCampus
          : utrgvEdinburgCampus,
      zoom: 16.0,
      pitch: 45.0,
      bearing: 0.0,
    );
  });
}

  Future<void> _recenterOnUser() async {
    final status = await Permission.locationWhenInUse.status;

    if (!status.isGranted) {
      await _enableLiveLocation();
      return;
    }

    setState(() {
      _viewport = const FollowPuckViewportState(
        zoom: 17.0,
        pitch: 45.0,
        bearing: FollowPuckViewportStateBearingHeading(),
      );
    });
  }

  void _showLocationSettingsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Location access is disabled. Enable it in iPhone Settings.',
        ),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('campus-map'),
            viewport: _viewport,
            onMapCreated: _onMapCreated,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
  onTap: _toggleCampus,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 12,
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on),
        const SizedBox(width: 8),
        Text(
          _isBrownsville
              ? 'Brownsville Campus'
              : 'Edinburg Campus',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.swap_horiz,
          size: 20,
        ),
      ],
    ),
  ),
),
                  const Spacer(),
                  const LogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Center on my location',
        onPressed: _isRequestingLocation ? null : _recenterOnUser,
        child: _isRequestingLocation
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }
}