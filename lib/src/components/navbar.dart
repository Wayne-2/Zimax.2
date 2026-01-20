import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zimax/src/components/svgicon.dart';
import 'package:zimax/src/pages/chat.dart';
import 'package:zimax/src/pages/home.dart';
import 'package:zimax/src/pages/posts.dart';
import 'package:zimax/src/pages/search.dart';
import 'package:zimax/src/pages/space.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _MainNavState();
}

class _MainNavState extends State<NavBar> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Home(),
    Search(),
    Posts(),
    Chat(),
    Space(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(234, 0, 0, 0),
        selectedLabelStyle: GoogleFonts.poppins( fontWeight: FontWeight.w600,),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500,),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 13,
        unselectedFontSize: 13,
        items: const [
          BottomNavigationBarItem(
            icon: SvgIcon("assets/icons/home.svg", color: Colors.black),
            activeIcon: SvgIcon("assets/icons/home-fill.svg", color: Colors.black),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: SvgIcon("assets/icons/search.svg", color: Colors.black),
            activeIcon: SvgIcon("assets/icons/search-fill.svg", color: Colors.black),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: SvgIcon("assets/icons/post.svg", color: Colors.black),
            activeIcon: SvgIcon("assets/icons/post-fill.svg", color: Colors.black),
            label: "Posts",
          ),
          BottomNavigationBarItem(
            icon: SvgIcon("assets/icons/chat.svg", color: Colors.black),
            activeIcon: SvgIcon("assets/icons/chat-fill.svg", color: Colors.black),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: SvgIcon("assets/icons/space.svg", color: Colors.black),
            activeIcon: SvgIcon("assets/icons/space-fill.svg", color: Colors.black),
            label: "Space",
          ),
        ],
      ),
    );
  }
}