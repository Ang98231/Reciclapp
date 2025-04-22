import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  Location location = Location();

  LatLng _initialPosition = const LatLng(19.4326, -99.1332); // Valor por defecto
  bool _loading = true;
  int _selectedIndex = 0;


  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;

  final Color _primaryColor = Colors.green;
  final Color _accentColor = Colors.lightGreen;
  
  // Conjunto de marcadores para el mapa
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() => _loading = false);
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _loading = false);
          return;
        }
      }

      final currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        LatLng newPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);

        // Agregar un marcador en la ubicación actual
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: newPosition,
            infoWindow: const InfoWindow(
              title: 'Mi ubicación',
              snippet: 'Estás aquí',
            ),
          ),
        );

        setState(() {
          _initialPosition = newPosition;
          _loading = false;
        });

        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _initialPosition, zoom: 15),
            ),
          );
        }
      }
    } catch (e) {
      // En caso de error, cargar el mapa con la posición predeterminada
      setState(() => _loading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (!_loading) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialPosition, zoom: 15),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Seleccionaste: ${_getTabName(index)}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  String _getTabName(int index) {
    switch (index) {
      case 0: return 'Juegos';
      case 1: return 'Educación';
      case 2: return 'Perfil';
      default: return '';
    }
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchFocused = false;
    });
  }

  void _centerMap() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialPosition, zoom: 15),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        title: const Text('ReciclApp', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Acerca de ReciclApp'),
                  content: const Text('Esta aplicación te permite explorar ubicaciones de centros de reciclaje y conocer más sobre que reciclar.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Entendido', style: TextStyle(color: _primaryColor)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  const SizedBox(height: 16),
                  const Text('Cargando mapa...'),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false, 
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  markers: _markers,
                ),

                // Barra de búsqueda
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: _primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Buscar centros de reciclaje...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              onTap: () {
                                setState(() {
                                  _isSearchFocused = true;
                                });
                              },
                            ),
                          ),
                          if (_isSearchFocused)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearSearch,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 86,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: "btn_center",
                        backgroundColor: Colors.white,
                        mini: true,
                        onPressed: _centerMap,
                        child: Icon(Icons.my_location, color: _primaryColor),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "btn_layers",
                        backgroundColor: Colors.white,
                        mini: true,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Capas del mapa',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ListTile(
                                    leading: Icon(Icons.nature, color: _primaryColor),
                                    title: const Text('Parques y áreas verdes'),
                                    trailing: Switch(
                                      value: true,
                                      onChanged: (value) {},
                                      activeColor: _primaryColor,
                                    ),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.recycling, color: _primaryColor),
                                    title: const Text('Centros de reciclaje'),
                                    trailing: Switch(
                                      value: false,
                                      onChanged: (value) {},
                                      activeColor: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Icon(Icons.layers, color: _primaryColor),
                      ),
                      const SizedBox(height: 8),
                      
                    ],
                  ),
                ),
              ],
            ),

      // Barra de navegación inferior mejorada
      bottomNavigationBar: BottomNavigationBar(
  elevation: 8,
  backgroundColor: Colors.white,
  selectedItemColor: _primaryColor,
  unselectedItemColor: Colors.grey,
  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
  currentIndex: _selectedIndex,
  onTap: _onItemTapped,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.videogame_asset),
      label: 'Juegos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book),
      label: 'Educación',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ],
),
    );
  }

  // Widget para construir tarjetas de actividades
  
}