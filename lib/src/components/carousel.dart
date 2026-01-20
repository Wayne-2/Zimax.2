import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class GradientCarousel extends StatefulWidget {
  final List<String> images;
  final List<String> titles;

  const GradientCarousel({
    super.key,
    required this.images,
    required this.titles,
  });

  @override
  State<GradientCarousel> createState() => _GradientCarouselState();
}

class _GradientCarouselState extends State<GradientCarousel> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CAROUSEL
        CarouselSlider.builder(
          itemCount: widget.images.length,
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (i, reason) =>
                setState(() => current = i),
          ),
          itemBuilder: (context, index, realIndex) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // IMAGE
                CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.cover,

                  placeholder: (_,_) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(color: Colors.white),
                  ),

                  errorWidget: (_, _, _) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error,
                        size: 40, color: Colors.red),
                  ),
                ),

                // GRADIENT OVERLAY
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color.fromARGB(255, 255, 255, 255),
                      ],
                    ),
                  ),
                ),
                // TEXT
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Text(
                    widget.titles[index],
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color.fromARGB(255, 26, 26, 26),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        // DOT INDICATOR
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: current == i ? 16 : 6,
              decoration: BoxDecoration(
                color: current == i
                    ? Colors.black87
                    : Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
