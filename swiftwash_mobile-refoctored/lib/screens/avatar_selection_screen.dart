import 'package:flutter/material.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  int? selectedAvatarIndex;
  int? selectedColorIndex;

  final List<Map<String, dynamic>> avatars = [
    // Women avatars
    {
      'type': 'woman',
      'name': 'Sophia',
      'color': const Color(0xFFFFC5D0), // Light pink
      'features': {'hair': 'long_wavy', 'accessory': 'glasses', 'expression': 'smiling'},
    },
    {
      'type': 'woman',
      'name': 'Emma',
      'color': const Color(0xFFB5E8D5), // Mint green
      'features': {'hair': 'ponytail', 'accessory': 'headband', 'expression': 'confident'},
    },
    {
      'type': 'woman',
      'name': 'Ava',
      'color': const Color(0xFFE6C9F5), // Lavender
      'features': {'hair': 'curly', 'accessory': 'earrings', 'expression': 'warm'},
    },
    // Men avatars
    {
      'type': 'man',
      'name': 'Liam',
      'color': const Color(0xFFA8D8F8), // Light blue
      'features': {'hair': 'short_spiky', 'beard': 'stubble', 'accessory': 'watch', 'expression': 'cool'},
    },
    {
      'type': 'man',
      'name': 'Noah',
      'color': const Color(0xFFFFD4A3), // Peach
      'features': {'hair': 'medium_curled', 'beard': 'mustache', 'accessory': 'glasses', 'expression': 'thoughtful'},
    },
    {
      'type': 'man',
      'name': 'Oliver',
      'color': const Color(0xFFC4F7C4), // Light green
      'features': {'hair': 'messy', 'beard': 'short_beard', 'accessory': 'earbuds', 'expression': 'creative'},
    },
  ];

  final List<Color> avatarColors = [
    const Color(0xFFFFC5D0), // Light pink
    const Color(0xFFB5E8D5), // Mint green
    const Color(0xFFE6C9F5), // Lavender
    const Color(0xFFA8D8F8), // Light blue
    const Color(0xFFFFD4A3), // Peach
    const Color(0xFFC4F7C4), // Light green
    const Color(0xFFFFDBB5), // Cream
    const Color(0xFFE8A8F8), // Purple
    const Color(0xFFA3F8D4), // Cyan
  ];

  Widget _buildWomanAvatar(Color color, Map<String, dynamic> features) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base face
          Container(
            width: 35,
            height: 35,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          // Hair styles
          if (features['hair'] == 'long_wavy')
            Positioned(
              top: 8,
              left: 15,
              child: Container(
                width: 25,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          if (features['hair'] == 'ponytail')
            Positioned(
              top: 8,
              left: 20,
              child: Container(
                width: 20,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF654321),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          if (features['hair'] == 'curly')
            Positioned(
              top: 6,
              left: 12,
              child: Container(
                width: 28,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F1B14),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          // Accessories
          if (features['accessory'] == 'glasses')
            Positioned(
              top: 18,
              left: 12,
              child: Container(
                width: 28,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          if (features['accessory'] == 'headband')
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF69B4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (features['accessory'] == 'earrings')
            Positioned(
              top: 25,
              left: 8,
              child: Container(
                width: 4,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManAvatar(Color color, Map<String, dynamic> features) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base face
          Container(
            width: 35,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          // Hair styles
          if (features['hair'] == 'short_spiky')
            Positioned(
              top: 10,
              left: 15,
              child: Container(
                width: 25,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F1B14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFF2F1B14),
                  size: 8,
                ),
              ),
            ),
          if (features['hair'] == 'medium_curled')
            Positioned(
              top: 12,
              left: 14,
              child: Container(
                width: 28,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF654321),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          if (features['hair'] == 'messy')
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                width: 32,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          // Beard/Facial hair
          if (features['beard'] == 'stubble')
            Positioned(
              top: 36,
              left: 20,
              child: Container(
                width: 14,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F1B14),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          if (features['beard'] == 'mustache')
            Positioned(
              top: 34,
              left: 18,
              child: Container(
                width: 20,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F1B14),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA500),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          if (features['beard'] == 'short_beard')
            Positioned(
              top: 38,
              left: 16,
              child: Container(
                width: 24,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F1B14),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          // Accessories
          if (features['accessory'] == 'glasses')
            Positioned(
              top: 18,
              left: 10,
              child: Container(
                width: 32,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          if (features['accessory'] == 'watch')
            Positioned(
              top: 50,
              left: 6,
              child: Container(
                width: 8,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: Container(
                  margin: const EdgeInsets.only(left: 1),
                  width: 2,
                  color: Colors.white,
                ),
              ),
            ),
          if (features['accessory'] == 'earbuds')
            Positioned(
              top: 20,
              left: 6,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color, bool isSelected) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(
          color: const Color(0xFF04D6F7),
          width: 3,
        ) : Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  void _selectAvatar(int index) {
    setState(() {
      selectedAvatarIndex = index;
      selectedColorIndex = 0; // Default to first color
    });
  }

  void _selectColor(int index) {
    setState(() {
      selectedColorIndex = index;
    });
  }

  void _confirmPFP() {
    if (selectedAvatarIndex != null && selectedColorIndex != null) {
      final selectedAvatar = avatars[selectedAvatarIndex!];
      final selectedColor = avatarColors[selectedColorIndex!];

      Navigator.of(context).pop({
        'avatarIndex': selectedAvatarIndex,
        'color': selectedColor,
        'avatarType': selectedAvatar['type'],
        'avatarName': selectedAvatar['name'],
        'features': selectedAvatar['features'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Choose Profile Picture'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Avatar Preview
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF04D6F7),
                      width: 4,
                    ),
                  ),
                  child: ClipOval(
                    child: selectedAvatarIndex != null
                        ? avatars[selectedAvatarIndex!]['type'] == 'woman'
                            ? _buildWomanAvatar(avatarColors[selectedColorIndex ?? 0], avatars[selectedAvatarIndex!]['features'])
                            : _buildManAvatar(avatarColors[selectedColorIndex ?? 0], avatars[selectedAvatarIndex!]['features'])
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                  ),
                ),
                if (selectedAvatarIndex != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    avatars[selectedAvatarIndex!]['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    avatars[selectedAvatarIndex!]['type'][0].toUpperCase() + avatars[selectedAvatarIndex!]['type'].substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Avatar Selection
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Characters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: avatars.length,
                    itemBuilder: (context, index) {
                      final avatar = avatars[index];
                      final isSelected = selectedAvatarIndex == index;

                      return GestureDetector(
                        onTap: () => _selectAvatar(index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? const Color(0xFF04D6F7) : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              avatar['type'] == 'woman'
                                  ? _buildWomanAvatar(avatar['color'], avatar['features'])
                                  : _buildManAvatar(avatar['color'], avatar['features']),
                              const SizedBox(height: 4),
                              Text(
                                avatar['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF04D6F7) : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  if (selectedAvatarIndex != null) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Colors',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(
                        avatarColors.length,
                        (index) => GestureDetector(
                          onTap: () => _selectColor(index),
                          child: _buildColorOption(
                            avatarColors[index],
                            selectedColorIndex == index,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: (selectedAvatarIndex != null && selectedColorIndex != null)
                  ? _confirmPFP
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF04D6F7),
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Profile Picture',
                style: TextStyle(
                  color: (selectedAvatarIndex != null && selectedColorIndex != null)
                      ? Colors.white
                      : Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
