import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

/// 호스트 모드 홈 화면
class HostHomePage extends StatelessWidget {
  const HostHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('EZStay 호스트'),
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              } else if (value == 'switch_to_guest') {
                _switchToGuestMode(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'switch_to_guest',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF4A90E2)),
                    SizedBox(width: 8),
                    Text('게스트 모드로 전환'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: const Color(0xFF27AE60).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 사용자 정보
                        Text(
                          '안녕하세요, ${user?.name ?? '호스트'}님!',
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
                            color: const Color(0xFF27AE60).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '호스트 모드',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF27AE60),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 메인 액션 - 숙소 등록
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
                      context.go('/host/room-registration');
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
                          Icons.add_home,
                          size: 32,
                          color: Colors.white,
                        ),
                        SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '숙소 등록하기',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '새로운 숙소를 등록하세요',
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

                const SizedBox(height: 32),

                // 섹션 제목
                const Text(
                  '호스트 관리',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),

                // 관리 기능 그리드
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildManagementCard(
                      icon: Icons.home_work_outlined,
                      title: '내 숙소',
                      subtitle: '등록된 숙소 관리',
                      color: const Color(0xFF4A90E2),
                      onTap: () => _showComingSoonDialog(context),
                    ),
                    _buildManagementCard(
                      icon: Icons.calendar_today_outlined,
                      title: '예약 관리',
                      subtitle: '예약 현황 확인',
                      color: const Color(0xFFE67E22),
                      onTap: () => _showComingSoonDialog(context),
                    ),
                    _buildManagementCard(
                      icon: Icons.attach_money_outlined,
                      title: '수익 관리',
                      subtitle: '매출 및 정산',
                      color: const Color(0xFF9B59B6),
                      onTap: () => _showComingSoonDialog(context),
                    ),
                    _buildManagementCard(
                      icon: Icons.reviews_outlined,
                      title: '리뷰 관리',
                      subtitle: '게스트 리뷰',
                      color: const Color(0xFFF39C12),
                      onTap: () => _showComingSoonDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 통계 카드
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이번 달 요약',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                title: '등록된 숙소',
                                value: '0',
                                icon: Icons.home,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            Expanded(
                              child: _buildStatItem(
                                title: '예약 건수',
                                value: '0',
                                icon: Icons.book,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            Expanded(
                              child: _buildStatItem(
                                title: '총 수익',
                                value: '₩0',
                                icon: Icons.payments,
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
          ),
        );
        },
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
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

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF27AE60),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

  void _switchToGuestMode(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('게스트 모드로 전환'),
          content: const Text('게스트 모드로 전환하시겠습니까?\n숙소 검색 및 예약 기능을 사용할 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).switchUserMode(UserMode.guest);
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