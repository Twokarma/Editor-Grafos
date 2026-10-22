import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';

class PanelCard extends StatelessWidget{
  final String title;
  final Widget child;
  final bool scrollable;

  const PanelCard({super.key, required this.title, required this.child, this.scrollable = true});

  @override
  Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(32.0)),
          ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          scrollable? Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: child,
              ),
          ) : child,
        ],
      ),
    );
  }
}