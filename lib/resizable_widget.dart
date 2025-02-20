import 'package:flutter/material.dart';

class ResizableWidget extends StatefulWidget {
  final Widget child;
  final double Function(double) onResize;

  const ResizableWidget({
    super.key,
    required this.child,
    required this.onResize,
  });

  @override
  State<ResizableWidget> createState() => _ResizableWidgetState();
}

class _ResizableWidgetState extends State<ResizableWidget> {
  double? _height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _height = widget.onResize(
                    (_height ?? context.size?.height ?? 0) - details.delta.dy);
              });
            },
            child: Container(
              height: 4,
              color: Colors.grey[300],
            ),
          ),
        ),
        SizedBox(
          height: _height,
          child: widget.child,
        ),
      ],
    );
  }
}
