import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 채팅 입력 바 — 텍스트 입력 + 이미지 첨부 + 전송 버튼 + 이미지 미리보기
class ChatInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final List<XFile> selectedImages;
  final bool isSending;
  final bool hasText;
  final VoidCallback onImageSelect;
  final VoidCallback onSend;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<int> onRemoveImage;

  const ChatInputBar({
    super.key,
    required this.messageController,
    required this.selectedImages,
    required this.isSending,
    required this.hasText,
    required this.onImageSelect,
    required this.onSend,
    required this.onTextChanged,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(
          top: BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: SelectionContainer.disabled(child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: isSending ? null : onImageSelect,
                icon: const Icon(Icons.attach_file),
                color: isSending ? AppColors.gray300 : AppColors.gray600,
                padding: const EdgeInsets.all(10),
              ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onChanged: onTextChanged,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral400,
                    ),
                    filled: true,
                    fillColor: AppColors.neutral0,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.blue500, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      maxHeight: 120,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: (hasText || selectedImages.isNotEmpty) && !isSending
                    ? AppColors.blue600
                    : AppColors.gray300,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: (hasText || selectedImages.isNotEmpty) && !isSending
                      ? onSend
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.neutral0),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            size: 20,
                            color: AppColors.neutral0,
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ChatImagePreviewStrip(
              images: selectedImages,
              onRemove: onRemoveImage,
            ),
          ],
        ],
      )),
    );
  }
}

class _ChatImagePreviewStrip extends StatelessWidget {
  final List<XFile> images;
  final ValueChanged<int> onRemove;

  const _ChatImagePreviewStrip({
    required this.images,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<Uint8List>(
                  future: images[index].readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      width: 64,
                      height: 64,
                      color: AppColors.neutral200,
                      child: const Icon(Icons.image,
                          size: 24, color: AppColors.neutral500),
                    );
                  },
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.neutral500,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.neutral0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
