import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

/// 게스트 모드 홈 화면
class GuestHomePage extends StatelessWidget {
  const GuestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('EZStay'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              } else if (value == 'switch_to_host') {
                _switchToHostMode(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'switch_to_host',
                child: Row(
                  children: [
                    Icon(Icons.home_work, color: Color(0xFF27AE60)),
                    SizedBox(width: 8),
                    Text('호스트 모드로 전환'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('로그아웃'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  // 사용자 프로필 카드
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // 프로필 아이콘
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 사용자 정보
                          Text(
                            '안녕하세요, ${user?.name ?? '게스트'}님!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              '게스트 모드',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A90E2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 메인 기능 버튼
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4DB5BD), Color(0xFF667EEA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          offset: const Offset(0, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/map');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 32,
                            color: Colors.white,
                          ),
                          SizedBox(width: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '숙소 검색하기',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '지도에서 원하는 숙소를 찾아보세요',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 부가 기능들
                  Row(
                    children: [
                      // 즐겨찾기
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.favorite_outline,
                          title: '즐겨찾기',
                          subtitle: '저장된 숙소',
                          onTap: () {
                            _showComingSoonDialog(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 예약 내역
                      Expanded(
                        child: _buildFeatureCard(
                          icon: Icons.book_outlined,
                          title: '예약 내역',
                          subtitle: '내 예약 확인',
                          onTap: () {
                            _showComingSoonDialog(context);
                          },
                        ),
                      ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: const Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).logout();
                Navigator.pop(context);
              },
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }

  void _switchToHostMode(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('호스트 모드로 전환'),
          content: const Text('호스트 모드로 전환하시겠습니까?\n숙소 등록 및 관리 기능을 사용할 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).switchUserMode(UserMode.host);
                Navigator.pop(context);
              },
              child: const Text('전환하기'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('준비 중'),
          content: const Text('해당 기능은 준비 중입니다.\n곧 만나보실 수 있어요!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}