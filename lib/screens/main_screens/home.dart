import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:password_manager/models/card_item.dart';
import 'package:password_manager/screens/login_items/add_card.dart';
import 'package:password_manager/screens/login_items/add_note.dart';
import 'package:password_manager/screens/profile/profile_page.dart';
import 'package:password_manager/services/auto_lock_manager.dart';

import '../../models/login_item.dart';
import '../../models/notes_item.dart';
import '../../services/sync_items_service.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../auth/login_password.dart';
import '../login_items/add_login.dart';
import '../login_items/card_item_details.dart';
import '../login_items/login_item_details.dart';
import '../login_items/note_item_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedChip = 'All';
  File? _profileImage;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late final Box<LoginItem> loginBox;
  late final Box<NoteItem> notesBox;
  late final Box<CardItem> cardsBox;
  late final VoidCallback _loginListener;
  late final VoidCallback _noteListener;
  late final VoidCallback _cardListener;

  @override
  void initState() {
    super.initState();
    loginBox = Hive.box<LoginItem>('loginBox');
    notesBox = Hive.box<NoteItem>('notesBox');
    cardsBox = Hive.box<CardItem>('cardsBox');

    _loginListener = () => _onBoxChanged();
    _noteListener = () => _onBoxChanged();
    _cardListener = () => _onBoxChanged();

    loginBox.listenable().addListener(_loginListener);
    notesBox.listenable().addListener(_noteListener);
    cardsBox.listenable().addListener(_cardListener);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      if (results.any((result) => result != ConnectivityResult.none)) {
        await _syncAll();
      }
    });
  }

  Timer? _syncDebounce;

  Future<void> _onBoxChanged() async {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 500), () async {
      final hasDeleted = loginBox.values.any((item) => item.syncStatus == 'deleted') ||
          notesBox.values.any((item) => item.syncStatus == 'deleted') ||
          cardsBox.values.any((item) => item.syncStatus == 'deleted');
      if (hasDeleted) {
        await Future.delayed(const Duration(milliseconds: 200));
        await _syncAll();
      }
      if (mounted) setState(() {});
    });
  }


  Future<void> _syncAll() async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final syncService = SyncService(firestore: firestore);
    await syncService.syncLoginItems(loginBox, userId);
    await syncService.syncNoteItems(notesBox, userId);
    await syncService.syncCardItems(cardsBox, userId);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    _connectivitySubscription?.cancel();
    loginBox.listenable().removeListener(_loginListener);
    notesBox.listenable().removeListener(_noteListener);
    cardsBox.listenable().removeListener(_cardListener);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF328E6E),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.inventory_2_outlined, color: Colors.deepPurple),
        ),
        title: const Text(
          'ConceptX',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ProfilePopup(),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: -100,
            right: -100,
            child: Container(
              height: 250,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(300, 100),
                ),
                color: Color(0xFF328E6E),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search any items',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildChip('All'),
                          const SizedBox(width: 8),
                          _buildChip('Logins'),
                          const SizedBox(width: 8),
                          _buildChip('Notes'),
                          const SizedBox(width: 8),
                          _buildChip('Cards'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: loginBox.listenable(),
                  builder: (context, Box<LoginItem> _, __) {
                    final allLoginItems = loginBox.values.where((item) => item.syncStatus != 'deleted').toList();
                    final allNoteItems = notesBox.values.where((item) => item.syncStatus != 'deleted').toList();
                    final allCardItems = cardsBox.values.where((item) => item.syncStatus != 'deleted').toList();

                    List<dynamic> filteredItems = [];

                    if (_selectedChip == 'All') {
                      filteredItems = [
                        ...allLoginItems.where((item) =>
                        item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            item.username.toLowerCase().contains(_searchQuery.toLowerCase())
                        ),
                        ...allNoteItems.where((item) =>
                        item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            item.content.toLowerCase().contains(_searchQuery.toLowerCase())
                        ),
                        ...allCardItems.where((item) =>
                        item.number.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            item.holderName.toLowerCase().contains(_searchQuery.toLowerCase())
                        ),
                      ];
                    } else if (_selectedChip == 'Logins') {
                      filteredItems = allLoginItems.where((item) =>
                      item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          item.username.toLowerCase().contains(_searchQuery.toLowerCase())
                      ).toList();
                    } else if (_selectedChip == 'Notes') {
                      filteredItems = allNoteItems.where((item) =>
                      item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          item.content.toLowerCase().contains(_searchQuery.toLowerCase())
                      ).toList();
                    } else if (_selectedChip == 'Cards') {
                      filteredItems = allCardItems.where((item) =>
                      (item.type.toLowerCase() == 'card') &&
                          (item.number.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              item.holderName.toLowerCase().contains(_searchQuery.toLowerCase()))
                      ).toList();
                    }

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Image.asset(
                                'assets/no_items.png',
                                width: 150,
                                height: 150,
                                color: const Color(0xFF328E6E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'There are currently no items\nStart adding some!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        if (item is LoginItem) {
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => LoginDetailsBottomSheet(
                                    loginItem: item,
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF90C67C),
                                ),
                              ),
                              subtitle: Text(
                                item.username,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: const Icon(Icons.password_outlined, size: 28),
                            ),
                          );
                        } else if (item is NoteItem) {
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => NoteDetailsBottomSheet(noteItem: item),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF90C67C),
                                ),
                              ),
                              subtitle: Text(
                                item.content.length > 40
                                    ? item.content.substring(0, 40) + '...'
                                    : item.content,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: const Icon(Icons.sticky_note_2_outlined, size: 28),
                            ),
                          );
                        } else if (item is CardItem) {
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => CardDetailsBottomSheet(cardItem: item),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                '•••• •••• •••• ${item.number.substring(item.number.length - 4)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF90C67C),
                                ),
                              ),
                              subtitle: Text(
                                item.holderName,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: const Icon(Icons.credit_card, size: 28),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: const Color(0xFF328E6E),
        foregroundColor: Colors.white,
        spacing: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.key),
            backgroundColor: const Color(0xFF67AE6E),
            foregroundColor: Colors.white,
            label: 'Add Login',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddLoginPopup()),
              );
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.note_add_outlined),
            backgroundColor: const Color(0xFF67AE6E),
            foregroundColor: Colors.white,
            label: 'Add Note',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddNotePopup()),
              );
              setState(() {});
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_card_outlined),
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF67AE6E),
            label: 'Add Card',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) => const AddCardPopup(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _logoutUser() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const EnterPasswordScreen()),
            (route) => false,
      );
    }
  }

  Widget _buildChip(String label) {
    final bool selected = _selectedChip == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : Colors.grey),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedChip = label);
      },
      selectedColor: const Color(0xFF328E6E),
      backgroundColor: Colors.grey[100],
      shape: const StadiumBorder(),
    );
  }
}

