import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;

  const SvgIcon(
    this.asset, {
    super.key,
    this.size = 18,   // default size 16
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
