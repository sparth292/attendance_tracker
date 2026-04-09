import 'package:flutter/material.dart';
import 'event_details_screen.dart';

class UpcomingEventsScreen extends StatefulWidget {
  const UpcomingEventsScreen({Key? key}) : super(key: key);

  @override
  State<UpcomingEventsScreen> createState() => _UpcomingEventsScreenState();
}

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen> {
  // Track which cards are expanded
  final Map<String, bool> _expandedCards = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Upcoming Events'),
      ),
      body: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildEventCard(
              context,
              'Symphony',
              'assets/images/Symphony_img.jpeg',
              'A wonderful music event where students will get vibe with some songs',
            ),
            const SizedBox(height: 16),
            _buildEventCard(
              context,
              'Abhiyantriki',
              'assets/images/Abhiyantriki.png',
              'Technical festival featuring robotics, coding competitions, and workshops',
            ),
            const SizedBox(height: 16),
            _buildEventCard(
              context,
              'Techmaze',
              'assets/images/techmaze.png',
              'Inter-college technical competition with various engineering challenges',
            ),
            const SizedBox(height: 16),
            _buildEventCard(
              context,
              'Sports Meet',
              'assets/images/Sports_meet.jpg',
              'Annual sports day with various athletic events and competitions',
            ),
            const SizedBox(height: 16),
            _buildEventCard(
              context,
              'Hackathon',
              'assets/images/Hackathon.png',
              '24-hour coding challenge to innovate and create solutions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, String eventName, String imagePath, String description) {
    final isExpanded = _expandedCards[eventName] ?? false;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isExpanded) {
              // If already expanded, navigate to full details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsScreen(
                    eventName: eventName,
                    imagePath: imagePath,
                    description: description,
                  ),
                ),
              );
            } else {
              // First click - expand the card
              _expandedCards[eventName] = true;
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: isExpanded ? 250 : 180,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                  onError: (error, stackTrace) {
                    // If image fails to load, use a placeholder
                  },
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                    top: 0.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event name and description - always at bottom left
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 8),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: isExpanded ? 1.0 : 0.0,
                                child: Text(
                                  description,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
