import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget{
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  void signOut() async{
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }


  Widget body(){
    return Column(
      children: [
        Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Icon(Icons.account_circle, size: 120,),
                    Text(FirebaseAuth.instance.currentUser!.displayName!),

                    Container(height: 50),

                    Row(
                      children: [
                        Text("Email"),
                        Spacer(),
                        Text(FirebaseAuth.instance.currentUser!.email!),
                      ],
                    )

                  ],
                )
              ),
            )
        ),
        ElevatedButton(onPressed: signOut, child: Text("Sign out")),
      ],
    );
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
      ),
      body: body(),
    );
  }
}