import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/widgets/ui/pressable.dart';

import '../../theme/app_colors.dart';

enum PillButtonStyle{
  outline(AppColors.white, AppColors.darkBlue, 1.5, AppColors.darkBlue),
  accent(AppColors.blue, null, null, AppColors.white),
  dark(AppColors.darkBlue, null, null, AppColors.white);

  const PillButtonStyle(this.background, this.strokeColor, this.strokeWidth, this.textColor);

  final Color background;
  final Color? strokeColor;
  final double? strokeWidth;
  final Color textColor;
}

class PillButton extends StatelessWidget{
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final PillButtonStyle style;
  final bool fullWidth;

  const PillButton({super.key, required this.label, this.onTap, this.icon, required this.style, this.fullWidth = false});

  @override
  Widget build(BuildContext context){
    return Pressable(
      onTap: onTap,
      child: Opacity(
          opacity: onTap != null? 1.0 : 0.45,
          child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: ShapeDecoration(
              color: style.background,
              shape: StadiumBorder(
                side: style.strokeWidth != null? BorderSide(
                  color: style.strokeColor!,
                  width: style.strokeWidth!,
                ) : BorderSide.none,
              ),
          ),
          child: Row(
              mainAxisSize: fullWidth? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(icon != null)
                  Icon(
                      icon,
                      color: style.textColor,
                  ),
                if(icon != null)
                  const SizedBox(width: 8.0,),
                Flexible(child:
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: style.textColor,
                    ),
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }

}