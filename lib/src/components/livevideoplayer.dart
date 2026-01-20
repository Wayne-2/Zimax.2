// // import 'package:better_player/better_player.dart';

// class LiveVideoSection extends StatefulWidget {
//   final String url;
//   const LiveVideoSection({super.key, required this.url});

//   @override
//   _LiveVideoSectionState createState() => _LiveVideoSectionState();
// }

// class _LiveVideoSectionState extends State<LiveVideoSection> {
//   late BetterPlayerController _betterPlayerController;

//   @override
//   void initState() {
//     super.initState();

//     BetterPlayerDataSource dataSource = BetterPlayerDataSource(
//       BetterPlayerDataSourceType.network,
//       widget.url,
//       liveStream: true,
//     );

//     _betterPlayerController = BetterPlayerController(
//       BetterPlayerConfiguration(
//         aspectRatio: 16 / 9,
//         autoPlay: true,
//         controlsConfiguration: BetterPlayerControlsConfiguration(
//           showControls: true,
//         ),
//       ),
//       betterPlayerDataSource: dataSource,
//     );
//   }

//   @override
//   void dispose() {
//     _betterPlayerController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BetterPlayer(controller: _betterPlayerController);
//   }
// }
