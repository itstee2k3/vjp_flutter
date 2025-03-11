import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  final Function(String)? onSearch;
  final Function(String)? onFlagChanged;

  const SearchWidget({
    Key? key, 
    this.onSearch,
    this.onFlagChanged,
  }) : super(key: key);

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  String selectedFlag = 'vn';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 15),

          // Ô tìm kiếm
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,

              decoration: const InputDecoration(
                hintText: 'Tìm kiếm doanh nghiệp...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 15),
              ),
              onSubmitted: widget.onSearch,
            ),
          ),

          const SizedBox(height: 15),

          // Row chứa cờ và nút tìm kiếm
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFlagButton(
                flag: 'vn',
                imageUrl: 'https://vjp-connect.com/images/logo2.png',
              ),
              const SizedBox(width: 10),
              _buildFlagButton(
                flag: 'jp',
                imageUrl: 'https://vjp-connect.com/images/logo4.png',
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => widget.onSearch?.call(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Tìm doanh nghiệp',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlagButton({required String flag, required String imageUrl}) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedFlag = flag);
        widget.onFlagChanged?.call(flag);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedFlag == flag ? Colors.blue : Colors.grey.shade300,
            width: selectedFlag == flag ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.network(
          imageUrl,
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 