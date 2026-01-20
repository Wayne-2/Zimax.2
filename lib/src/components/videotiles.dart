import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class VideoTileRow extends StatelessWidget {
  final List<String> videoThumbnails;

  const VideoTileRow({
    super.key,
    required this.videoThumbnails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
          child: Text('Zimax Trending', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),),
        ),
        SizedBox(
          height: 180, 
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videoThumbnails.length,
            separatorBuilder: (_, _) => const SizedBox(width: 1),
            itemBuilder: (context, index) {
              final thumb = videoThumbnails[index];
        
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                                         
                    AspectRatio(
                      aspectRatio: 10 / 16, 
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,


                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              color: Colors.white,
                            ),
                          ),

                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                    ),

                        
                      Positioned.fill(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          color: Colors.black26,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('2m ago', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 11),),
                                  Icon(Icons.more_vert, color: Colors.white, size: 13)
                                ],
                              )
                            ],
                          )
                          
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
