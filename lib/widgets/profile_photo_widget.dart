import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum ProfilePhotoSize { small, medium, large }

/// Reusable profile photo widget
/// 
/// Displays user profile photo with:
/// - Cached network image with placeholder
/// - Default avatar fallback
/// - Optional edit button overlay
/// - Loading indicator
/// - Multiple size options
class ProfilePhotoWidget extends StatelessWidget {
  final String? photoUrl;
  final String userName;
  final ProfilePhotoSize size;
  final VoidCallback? onEditPressed;
  final bool showEditButton;

  const ProfilePhotoWidget({
    super.key,
    this.photoUrl,
    required this.userName,
    this.size = ProfilePhotoSize.medium,
    this.onEditPressed,
    this.showEditButton = false,
  });

  double get _photoSize {
    switch (size) {
      case ProfilePhotoSize.small:
        return 50;
      case ProfilePhotoSize.medium:
        return 100;
      case ProfilePhotoSize.large:
        return 150;
    }
  }

  double get _iconSize {
    switch (size) {
      case ProfilePhotoSize.small:
        return 16;
      case ProfilePhotoSize.medium:
        return 24;
      case ProfilePhotoSize.large:
        return 32;
    }
  }

  String _getDefaultAvatar() {
    if (userName.isEmpty) {
      return 'https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff&size=200';
    }
    final initials = userName.split(' ').map((part) => part.isNotEmpty ? part[0] : '').take(2).join('');
    return 'https://ui-avatars.com/api/?name=$initials&background=0D8ABC&color=fff&size=200';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: _photoSize,
          height: _photoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: _iconSize,
                        height: _iconSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.network(
                      _getDefaultAvatar(),
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.network(
                    _getDefaultAvatar(),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (showEditButton && onEditPressed != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEditPressed,
              child: Container(
                width: _photoSize * 0.3,
                height: _photoSize * 0.3,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: _photoSize * 0.15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
