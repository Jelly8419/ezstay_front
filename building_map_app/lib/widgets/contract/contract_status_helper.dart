import 'package:flutter/material.dart';
import '../../models/contract.dart';

/// 계약 상태 표시 헬퍼 (게스트/호스트 공용)
class ContractStatusHelper {
  ContractStatusHelper._();

  /// 상태별 텍스트 색상
  static Color getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return const Color(0xFFA16207);
      case ContractStatus.approvalExpired:
        return Colors.grey;
      case ContractStatus.approved:
        return const Color(0xFF1D4ED8);
      case ContractStatus.paymentExpired:
        return Colors.grey.shade600;
      case ContractStatus.paymentCompleted:
        return const Color(0xFF15803D);
      case ContractStatus.inProgress:
        return const Color(0xFF7E22CE);
      case ContractStatus.completed:
        return Colors.grey;
      case ContractStatus.rejected:
        return const Color(0xFFDC2626);
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
      case ContractStatus.cancelledByAdminWithRefund:
      case ContractStatus.cancelledByAdminNoRefund:
        return Colors.grey;
      case ContractStatus.refunded:
        return const Color(0xFF7E22CE);
      case ContractStatus.cancelRequested:
        return const Color(0xFFEA580C);
    }
  }

  /// 상태별 배경 색상
  static Color getStatusBgColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return const Color(0xFFFEF3C7);
      case ContractStatus.approved:
        return const Color(0xFFDBEAFE);
      case ContractStatus.paymentCompleted:
        return const Color(0xFFDCFCE7);
      case ContractStatus.inProgress:
        return const Color(0xFFF3E8FF);
      case ContractStatus.completed:
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return const Color(0xFFF3F4F6);
      case ContractStatus.rejected:
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  /// 상태별 아이콘
  static Widget getStatusIcon(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return const Icon(Icons.schedule, size: 16);
      case ContractStatus.approved:
      case ContractStatus.paymentCompleted:
      case ContractStatus.completed:
        return const Icon(Icons.check_circle, size: 16);
      case ContractStatus.rejected:
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
        return const Icon(Icons.cancel, size: 16);
      case ContractStatus.inProgress:
        return const Icon(Icons.home, size: 16);
      default:
        return const Icon(Icons.info, size: 16);
    }
  }

  /// 상태별 안내 메시지 (게스트용)
  static String getStatusMessage(ContractStatus status) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return '임대인의 승인/거절을 기다리고 있습니다.';
      case ContractStatus.approved:
        return '임대인이 승인했습니다. 결제를 진행해주세요.';
      case ContractStatus.paymentCompleted:
        return '입주일에 맞춰 방문해주세요.';
      case ContractStatus.inProgress:
        return '';
      default:
        return '';
    }
  }

  /// 상태 뱃지용 텍스트 + 배경색 + 텍스트색 (호스트 카드용)
  static ({String text, Color bgColor, Color textColor}) getStatusBadgeConfig(
    ContractStatus status,
  ) {
    switch (status) {
      case ContractStatus.pendingApproval:
        return (text: '승인 대기', bgColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFA16207));
      case ContractStatus.approved:
        return (text: '결제 대기', bgColor: const Color(0xFFDBEAFE), textColor: const Color(0xFF1D4ED8));
      case ContractStatus.paymentCompleted:
        return (text: '결제 완료', bgColor: const Color(0xFFD1FAE5), textColor: const Color(0xFF065F46));
      case ContractStatus.inProgress:
        return (text: '임대 중', bgColor: const Color(0xFFDBEAFE), textColor: const Color(0xFF1D4ED8));
      case ContractStatus.completed:
        return (text: '계약 종료', bgColor: const Color(0xFFF3F4F6), textColor: const Color(0xFF6B7280));
      case ContractStatus.rejected:
        return (text: '승인 거절', bgColor: const Color(0xFFFEE2E2), textColor: const Color(0xFFDC2626));
      case ContractStatus.cancelledByGuest:
      case ContractStatus.cancelledByHost:
      case ContractStatus.refunded:
      case ContractStatus.approvalExpired:
      case ContractStatus.paymentExpired:
      case ContractStatus.cancelledByAdminWithRefund:
      case ContractStatus.cancelledByAdminNoRefund:
        return (text: '계약 취소', bgColor: const Color(0xFFFEE2E2), textColor: const Color(0xFFDC2626));
      case ContractStatus.cancelRequested:
        return (text: '취소 요청', bgColor: const Color(0xFFFFF7ED), textColor: const Color(0xFFEA580C));
    }
  }

  /// 보증금 환급 완료 여부
  /// - RETURNED: 전액 환급 완료
  /// - RETURN_CONFIRMED: 반환 금액 확정 후 환급 완료
  /// - DEDUCTION_CONFIRMED: 상호합의 하에 차감 후 환급 처리 완료
  static bool isDepositRefundComplete(ContractListItem c) {
    return c.depositStatus == DepositStatus.returned ||
        c.depositStatus == DepositStatus.returnConfirmed ||
        c.depositStatus == DepositStatus.deductionConfirmed;
  }

  /// 탭별 계약 필터링
  static List<ContractListItem> filterByTab(
    List<ContractListItem> contracts,
    String tab,
  ) {
    switch (tab) {
      case 'in_progress':
        return contracts
            .where((c) =>
                _inProgressStatuses.contains(c.status) ||
                (c.status == ContractStatus.completed &&
                    !isDepositRefundComplete(c)))
            .toList();
      case 'completed':
        return contracts
            .where((c) =>
                c.status == ContractStatus.completed &&
                isDepositRefundComplete(c))
            .toList();
      case 'cancelled':
        return contracts
            .where((c) => _cancelledStatuses.contains(c.status))
            .toList();
      default:
        return contracts;
    }
  }

  /// 탭별 계약 개수
  static int countByTab(List<ContractListItem> contracts, String tab) {
    return filterByTab(contracts, tab).length;
  }

  static const _inProgressStatuses = [
    ContractStatus.pendingApproval,
    ContractStatus.approved,
    ContractStatus.paymentCompleted,
    ContractStatus.inProgress,
    ContractStatus.cancelRequested, // 취소 요청 중: 관리자 처리 대기 중이므로 진행중 탭 유지
  ];

  static const _cancelledStatuses = [
    ContractStatus.rejected,
    ContractStatus.cancelledByGuest,
    ContractStatus.cancelledByHost,
    ContractStatus.cancelledByAdminWithRefund,
    ContractStatus.cancelledByAdminNoRefund,
    ContractStatus.refunded,
    ContractStatus.approvalExpired,
    ContractStatus.paymentExpired,
  ];
}
