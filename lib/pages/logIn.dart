
import 'package:flutter/material.dart';
import 'package:swe_project/pages/main_navigation_page.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_footer.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'AdminHomePage.dart';
import 'SignUpPage.dart';


class logIn extends StatefulWidget {
  const logIn({super.key});

  @override
  State<logIn> createState() => _logInState();
}

class _logInState extends State<logIn> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 160,),
          Padding(
            padding: EdgeInsets.only(left: 30),
            child:  AppText(
              text: "Welcome Back",
              fontSize: 32,
              color: Color(0xFF10B981), // اللون الأخضر من التصميم
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 20,),

          Padding(
            padding: const EdgeInsets.all( 30),
            child: AppTextField(
              controller: emailController,
              label: "Email Address",
              hint: "Enter your email...",
              icon: Icons.email_outlined,
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.all(30),
            child: AppTextField(
              controller: passwordController,
              label: "Password",
              hint: "Enter your password...",
              icon: Icons.lock_outline,
              isPassword: true,
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.only(left: 60,right: 60),
            child: _logInBtn(context),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppFooterText(
              questionText: "Don't have an account?",
              actionText: "Create",
              onActionTap: () {
                // التنقل إلى صفحة التسجيل
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()), // تأكد من استيراد الملف
                );
              },
            ),
          ),




        ],
      ),
    );
  }

  AppButton _logInBtn(BuildContext context) {
    return AppButton(
            text: "Login",
            isLoading: _isLoading,
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  // 1. تسجيل الدخول الأساسي
                  final res = await supabase.auth.signInWithPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                  );

                  if (res.user != null) {
                    // 2. جلب رتبة المستخدم من جدول الـ profiles
                    final userData = await supabase
                        .from('profiles')
                        .select('role')
                        .eq('id', res.user!.id)
                        .single();

                    String role = userData['role'];

                    if (mounted) {
                      // تغذية راجعة بالنجاح
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Welcome back! Logging in as $role')),
                      );

                      // 3. التوجيه بناءً على الرتبة
                      if (role == 'admin') {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) => AdminHomePage()));
                      } else {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) => const MainNavigationPage()));
                      }
                    }
                  }
                } on AuthException catch (error) {
                  // تغذية راجعة في حال خطأ من Supabase (مثل كلمة مرور خاطئة)
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.message), backgroundColor: Colors.red),
                    );
                  }
                } catch (e) {
                  print(e.toString());
                  // تغذية راجعة لأي خطأ تقني آخر
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  // إيقاف التحميل في كل الأحوال
                  if (mounted) setState(() => _isLoading = false);
                }
              },
          );
  }
}

