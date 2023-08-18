// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({Key key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            ListTile(
              title: const Text('viejon'),
              onTap: () {
                print('viejon');
              },
            ),
          ],
        ),
      ),
    );
  }
}
