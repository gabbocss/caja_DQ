import 'package:flutter/material.dart';

/// Lista horizontal con flechas laterales para desplazarse entre ítems.
class ScrollHorizontalConFlechas extends StatefulWidget {
  final double height;
  final EdgeInsetsGeometry? padding;
  final List<Widget> children;
  final double scrollDelta;

  const ScrollHorizontalConFlechas({
    super.key,
    required this.height,
    required this.children,
    this.padding,
    this.scrollDelta = 150,
  });

  @override
  State<ScrollHorizontalConFlechas> createState() =>
      _ScrollHorizontalConFlechasState();
}

class _ScrollHorizontalConFlechasState extends State<ScrollHorizontalConFlechas> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _desplazar(double delta) {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final offset = (_controller.offset + delta).clamp(0.0, max);
    _controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_controller.hasClients && _controller.offset > 0) {
                _desplazar(-widget.scrollDelta);
              }
            },
            icon: const Icon(Icons.chevron_left),
            color: Colors.white70,
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: ListView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: widget.padding,
              children: widget.children,
            ),
          ),
          IconButton(
            onPressed: () {
              if (_controller.hasClients &&
                  _controller.offset <
                      _controller.position.maxScrollExtent) {
                _desplazar(widget.scrollDelta);
              }
            },
            icon: const Icon(Icons.chevron_right),
            color: Colors.white70,
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
