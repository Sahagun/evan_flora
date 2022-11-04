import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget{

  @override
  _LoginPageState createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage>{
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final emailTextFieldController = TextEditingController();
  final passwordTextFieldController = TextEditingController();

  bool submitLock = false;

  void showSnackBar(String message){
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }


  String? validateEmail(String? value){
    RegExp emailRegex = RegExp(r'\w+@\w+\.\w+');

    if(value == null || value.isEmpty || !emailRegex.hasMatch(value)){
      return 'Please enter a valid email.';
    }
    return null;
  }


  String? validatePassword(String? value){
    if(value == null || value.isEmpty){
      return 'Please enter a password.';
    }
    else if(value.length < 6 || value.length > 12){
      return 'Your Password need to have at between 6 and 12 characters.';
    }
    return null;
  }


  void onSignUpButtonPressed(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => SignUpPage())
    );
  }


  void onLoginButtonPressed() async{
    if(submitLock){
      showSnackBar("Please wait...");
      return;
    }

    submitLock = true;
    String email = emailTextFieldController.text;
    String password = passwordTextFieldController.text;

    if(_formKey.currentState!.validate()){
      try{
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        showSnackBar("Login successful...");
        submitLock = false;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
        );
      }
      on FirebaseAuthException catch(e){
        if(e.code == 'user-not-found') {
          showSnackBar("No account found for that email.");
        }
        else if(e.code == 'wrong-password') {
          showSnackBar("Password is incorrect.");
        }
        else{
          showSnackBar("Unknown Error.");
        }


      }

      showSnackBar("Valid Input");
    }
    submitLock = false;

  }


  @override
  void dispose(){
    emailTextFieldController.dispose();
    passwordTextFieldController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(right: 20, left: 20,),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Title Text
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Flora Finder",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Email Text Field
                TextFormField(
                  controller: emailTextFieldController,
                  validator: validateEmail,
                  decoration: const InputDecoration(
                    hintText: 'username@example.com',
                    labelText: "Email",
                  ),
                ),

                // Password Text Field
                TextFormField(
                  controller: passwordTextFieldController,
                  validator: validatePassword,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    labelText: "Password",
                  ),
                  obscureText: true,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: onLoginButtonPressed, child: const Text("Login")),
                    ElevatedButton(onPressed: onSignUpButtonPressed, child: const Text("SignUp")),
                  ],
                ),

              ],
            ),
          ),
        )
      )
    );
  }
}