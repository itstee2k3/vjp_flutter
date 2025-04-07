import 'package:flutter/material.dart';
import '../../../data/models/company.dart';
import '../../../data/sample_data/companies_data.dart';
import '../../../features/home/screens/company_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../main/cubits/main_cubit.dart';

class CompanyVnWidget extends StatefulWidget {
  const CompanyVnWidget({Key? key}) : super(key: key);

  @override
  State<CompanyVnWidget> createState() => _CompanyVnWidgetState();
}

class _CompanyVnWidgetState extends State<CompanyVnWidget> with TickerProviderStateMixin {
  // Thêm biến để theo dõi trạng thái hover cho từng nút
  final Map<String, bool> _isHovering = {};
  late AnimationController _controller; // Thêm controller

  @override
  void initState() {
    super.initState();
    // Khởi tạo animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Khởi tạo trạng thái hover cho tất cả các công ty
    for (var company in sampleCompanies) {
      _isHovering[company.id] = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Giải phóng controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tiêu đề với gạch ngang
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 1,
                color: Colors.blue,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "CÔNG TY ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: "VIỆT NAM",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 1,
                color: Colors.blue,
              ),
            ],
          ),
        ),

        // Danh sách công ty
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: sampleCompanies.map((company) {
              return Container(
                width: 350,
                height: 560,
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(136, 165, 191, 0.30),
                      spreadRadius: 0,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFFB2C1E5),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Phần logo và tên công ty
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        height: 120,
                        child: Row(
                          children: [
                            // Logo chính của công ty
                            Container(
                              height: 120,
                              width: 120,
                              padding: const EdgeInsets.all(8),
                              child: Image.network(
                                company.logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.business, size: 60, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tên công ty
                            Expanded(
                              child: Text(
                                company.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.left,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider giữa header và content
                      Divider(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      
                      // Phần thông tin chi tiết có background image
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage('https://vjp-connect.com/images/background2.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Thông tin công ty
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow('Năm thành lập:', company.establishedYear),
                                      _buildInfoRow('Số nhân viên:', company.employees),
                                      _buildInfoRow('Vốn điều lệ:', company.capital),
                                      _buildInfoRow('Địa chỉ:', company.address, maxLines: 2),
                                      _buildInfoRow('Ngành nghề:', company.industry),
                                      _buildInfoRow('Nhu cầu kết nối:', company.requirement, maxLines: 3),
                                    ],
                                  ),
                                ),
                              ),

                              // Badges và nút xem chi tiết
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 2 logo đối tác
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Logo VJP Connect (logo chung)
                                        Container(
                                          height: 40,
                                          child: Image.network(
                                            'https://vjp-connect.com/_next/static/media/logo1.3907871c.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        // Logo công ty
                                        Container(
                                          height: 40,
                                          child: Image.network(
                                            company.logoPartner,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Badges
                                  Container(
                                    height: 40,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: company.badges.map((badge) => Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Chip(
                                            label: Text(
                                              badge,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Color(0xFFB2C1E5),
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                  ),

                                  // Nút chi tiết
                                  Container(
                                    alignment: Alignment.center,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      onEnter: (_) => setState(() => _isHovering[company.id] = true),
                                      onExit: (_) => setState(() => _isHovering[company.id] = false),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            // Use go_router to navigate
                                            context.push('/company/${company.id}');
                                          },

                                          splashColor: const Color(0xFF002C90).withOpacity(0.1),
                                          highlightColor: const Color(0xFF002C90).withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            transform: Matrix4.identity()
                                              ..scale(_isHovering[company.id] == true ? 1.0 : 1.0),
                                            width: 120,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _isHovering[company.id] == true 
                                                  ? const Color(0xFF002C90) 
                                                  : Colors.white,
                                              border: Border.all(
                                                color: const Color(0xFFB2C1E5),
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Chi tiết',
                                                style: TextStyle(
                                                  color: _isHovering[company.id] == true 
                                                      ? Colors.white 
                                                      : Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Chiều rộng cố định cho label
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}