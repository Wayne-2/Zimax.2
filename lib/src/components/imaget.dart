import 'package:flutter/material.dart';


class ImageDisplay extends StatefulWidget {
  const ImageDisplay({super.key});

  @override
  State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> slide1;
  late Animation<double> slide2;
  late Animation<double> slide3;
  late Animation<double> slide4;
  late Animation<double> slideCenter;

  late Animation<double> fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    const curve = Curves.easeInOutCubic;

    // 🎯 New shorter slide distances
    slide1 = Tween<double>(begin: 35, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    slide2 = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    slide3 = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    slide4 = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    slideCenter = Tween<double>(begin: 45, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    // 🎨 Fade 0 → 1
    fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Opacity(
          opacity: fade.value, // fade entire stack smoothly
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            height: 130,
            child: Stack(
              children: [

                // Image 1 left
                Positioned(
                  top: 25,
                  bottom: 25,
                  left: 0,
                  child: Transform.translate(
                    offset: Offset(0, slide1.value),
                    child: Imaget(
                      width: 80,
                      height: 83,
                      imagename: 'assets/images/img3.png',
                    ),
                  ),
                ),

                // Image 1 right
                Positioned(
                  top: 25,
                  bottom: 25,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, slide2.value),
                    child: Imaget(
                      width: 80,
                      height: 83,
                      imagename: 'assets/images/img6.png',
                    ),
                  ),
                ),

                // Image 2 left
                Positioned(
                  top: 18,
                  bottom: 18,
                  left: 40,
                  child: Transform.translate(
                    offset: Offset(0, slide3.value),
                    child: Imaget(
                      width: 100,
                      height: 95,
                      imagename: 'assets/images/img5.png',
                    ),
                  ),
                ),

                // Image 2 right
                Positioned(
                  top: 18,
                  bottom: 18,
                  right: 40,
                  child: Transform.translate(
                    offset: Offset(0, slide4.value),
                    child: Imaget(
                      width: 100,
                      height: 95,
                      imagename: 'assets/images/img4.png',
                    ),
                  ),
                ),

                // Center image
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, slideCenter.value),
                    child: Center(
                      child: Imaget(
                        width: 135,
                        height: 130,
                        imagename: 'assets/images/img2.png',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Imaget extends StatelessWidget {
  final double width;
  final double height;
  final String imagename;

  const Imaget({super.key, required this.width, required this.height, required this.imagename});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 4,
            color: const Color.fromARGB(112, 0, 0, 0)
          )
        ],
         image: DecorationImage(
           image: AssetImage(imagename),
           fit: BoxFit.cover
         ))
    );
  }
}