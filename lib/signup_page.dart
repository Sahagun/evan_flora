import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

class SignUpPage extends StatefulWidget{

  @override
  _SignUpPageState createState() => _SignUpPageState();

}

class _SignUpPageState extends State<SignUpPage>{

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final emailTextFieldController = TextEditingController();
  final displayNameTextFieldController = TextEditingController();
  final passwordTextFieldController = TextEditingController();
  final confirmPasswordTextFieldController = TextEditingController();
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


  String? validateName(String? value){
    RegExp nameRegex = RegExp(r'[A-Za-z0-9]');

    if(value == null || value.isEmpty){
      return 'Please enter a display name.';
    }
    else if(!nameRegex.hasMatch(value)){
      return 'Please enter a valid display name. No special character or spaces.';
    }
    else if(value.length < 3 || value.length > 12){
      return 'Your display name need to have at between 6 and 12 characters.';
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


  String? validateConfirmPassword(String? value){
    if(value == null || value.isEmpty){
      return 'Please enter confirm your password.';
    }
    else if(value != passwordTextFieldController.text){
      return "Your password don't match.";
    }
    return null;
  }


  void onSignUpButtonPressed() async{
    if(submitLock){
      showSnackBar("Please Wait...");
      return;
    }

    submitLock = true;

    if(_formKey.currentState!.validate()){
      try{
        String email = emailTextFieldController.text;
        String password = passwordTextFieldController.text;
        String displayName = displayNameTextFieldController.text;

        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        await userCredential.user!.updateDisplayName(displayName);

        showSnackBar("Registration successful.");
        submitLock = false;

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
        );
      }
      on FirebaseAuthException catch(e){
        if(e.code == "weak-password"){
          showSnackBar("The provided password is too weak.");
        }
        else if (e.code == 'email-already-in-use') {
          showSnackBar("That email is already in use.");
        }
        else if (e.code == 'invalidEmail') {
          showSnackBar("The provided email is invalid.");
        }
        else{
          showSnackBar("Unknown Error.");
        }
      }
    }
    submitLock = false;
  }


  @override
  void dispose(){
    emailTextFieldController.dispose();
    passwordTextFieldController.dispose();
    confirmPasswordTextFieldController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [

            // DisplayName Text Field
            TextFormField(
              controller: displayNameTextFieldController,
              validator: validateName,
              decoration: const InputDecoration(
                hintText: 'Display Name',
                labelText: "Display Name",
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

            // Confirm Password Text Field
            TextFormField(
              controller: confirmPasswordTextFieldController,
              validator: validateConfirmPassword,
              decoration: const InputDecoration(
                hintText: 'Password',
                labelText: "Confirm Password",
              ),
              obscureText: true,
            ),

            ElevatedButton(onPressed: onSignUpButtonPressed, child: const Text("SignUp")),
          ],
        ),
      ),
    );
  }

}