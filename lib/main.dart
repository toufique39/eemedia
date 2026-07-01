import 'package:eemedia/features/auth/screens/chat_list_screen.dart';
import 'package:eemedia/features/auth/screens/comment_screen.dart';
import 'package:eemedia/features/auth/screens/create_post_screen.dart';
import 'package:eemedia/features/auth/screens/edit_profile_screen.dart';
import 'package:eemedia/features/auth/screens/friends_list_screen.dart';
import 'package:eemedia/features/auth/screens/notification_screen.dart';
import 'package:eemedia/features/auth/screens/presence_service.dart';
import 'package:eemedia/features/auth/screens/profile_screen.dart';
import 'package:eemedia/features/auth/screens/reels_feed_screen.dart';
import 'package:eemedia/features/auth/screens/search_screen.dart';
import 'package:eemedia/features/auth/screens/share_screen.dart';
import 'package:eemedia/features/auth/screens/student_level_screen.dart';
import 'package:eemedia/features/auth/screens/user_profile_screen.dart';
import 'package:eemedia/features/home/student_home_screen.dart';
import 'package:eemedia/providers/tracking_provider.dart';
import 'package:eemedia/services/friend_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eemedia/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/account_type_screen.dart';
import 'features/auth/screens/student_screen.dart';
import 'features/auth/screens/professional_screen.dart';
import 'features/auth/screens/student_screen_time.dart';
import 'features/auth/screens/tracking_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PresenceService.setOnline();
  runApp(const MyApp());

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://nykwzngasqeikiavtdlr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im55a3d6bmdhc3FlaWtpYXZ0ZGxyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExNzQ0MTIsImV4cCI6MjA5Njc1MDQxMn0.3c7WoEgsZ8C_hPpVpBIZNfmClTxdy4bBzSTIgCOol4M',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EEmedia',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const LoginScreen(),

        routes: {
          '/register': (context) => const RegisterScreen(),
          '/account-type': (context) => const AccountTypeScreen(),
          '/student-dashboard': (context) => const StudentScreen(),
          '/professional-dashboard': (context) => const ProfessionalScreen(),
          '/student-level': (context) => const StudentLevelScreen(),
          '/tracking': (context) => const TrackingScreen(),
          '/student-home': (context) => const StudentHomeScreen(),
          '/screen-time': (context) => const ScreenTimeScreen(),
          '/create-post': (context) => const CreatePostScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/search': (context) => const SearchScreen(),
          '/login': (context) => const LoginScreen(),
          '/friend-requests': (context) => const FriendRequestsScreen(),
          '/friends': (context) => const FriendsListScreen(),
          '/user-profile': (context) =>
              const UserProfileScreen(userId: '', userData: {}),
          '/chat-list': (context) => const ChatListScreen(),
          '/reels': (context) => const ReelsFeedScreen(isActive: true),
          '/comments': (context) {
            final postId =
                ModalRoute.of(context)?.settings.arguments as String?;
            return CommentScreen(postId: postId ?? '');
          },
          '/share': (context) => const ShareScreen(),
        },
      ),
    );
  }
}
