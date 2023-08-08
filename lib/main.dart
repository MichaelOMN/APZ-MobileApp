import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:loginapp1/rest-client.dart';
import 'home.dart';
import 'signup.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Login(title: 'Login Page'),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key, required this.title});

  final String title;
  
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  var restClient = RestClient();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _passwordObscured = true;
  String _responseText = '';
  bool _isResponseError = false;
  String _responseStatus = '';
  
  @override
  void initState() {
    
    super.initState();
    _passwordObscured = true;
    _responseText = '';
    _isResponseError = false;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(_responseStatus,
                style: TextStyle(
                    fontSize: theme.textTheme.bodyLarge?.fontSize,
                    color: _isResponseError ? Colors.red : Colors.green)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.person, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(),
                    labelText: "Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: passwordController,
                obscureText: _passwordObscured,
                decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.key, color: theme.colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordObscured
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Theme.of(context).primaryColorDark,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordObscured = !_passwordObscured;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                    labelText: "Password"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    Checkbox(
                        onChanged: (newValue) {
                          setState(() {
                            _isVisitor = newValue!;
                          });
                        },
                        value: _isVisitor),
                    const Text("Visitor?")
                  ],
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8.0),
              child: Center(
                  child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_isVisitor) {
                      restClient
                          .signInVisitor(
                              nameController.text, passwordController.text)
                          .then((value) {
                        dynamic bodyJSON;

                        if (value.statusCode == 200) {
                          setState(() {
                            bodyJSON = jsonDecode(value.body);
                            _responseText = bodyJSON['token'];
                            _responseStatus = 'Successful login';
                            _isResponseError = false;

                            goHomePage(context);
                          });
                        } else if (value.statusCode == 500) {
                          setState(() {
                            bodyJSON = jsonDecode(value.body);
                            _responseText = "ERROR: ${bodyJSON['message']}";
                            _responseStatus = "ERROR: ${bodyJSON['message']}";
                            _isResponseError = true;

                            goHomePage(context);
                          });
                        } else {
                          setState(() {
                            _responseText = "ERROR: ${value.body}";
                            _responseStatus = "ERROR: ${value.body}";

                            _isResponseError = true;

                            goHomePage(context);
                          });
                        }
                      });
                    } else {
                      restClient
                          .signInCoach(
                              nameController.text, passwordController.text)
                          .then((value) {
                        dynamic bodyJSON;

                        if (value.statusCode == 200) {
                          setState(() {
                            bodyJSON = jsonDecode(value.body);
                            _responseText = bodyJSON['token'];
                            _responseStatus = 'Successful login';
                            _isResponseError = false;

                            goHomePage(context);
                          });
                        } else if (value.statusCode == 500) {
                          setState(() {
                            bodyJSON = jsonDecode(value.body);
                            _responseText = "ERROR: ${bodyJSON['message']}";
                            _responseStatus = "ERROR: ${bodyJSON['message']}";
                            _isResponseError = true;

                            goHomePage(context);
                          });
                        } else {
                          setState(() {
                            _responseText = "ERROR: ${value.body}";
                            _responseStatus = "ERROR: ${value.body}";
                            _isResponseError = true;

                            goHomePage(context);
                          });
                        }
                      });
                    }
                    //goHomePage(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill input')),
                    );
                  }
                },
                child: const Text('Submit'),
              )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: RichText(
                text: TextSpan(
                  //style: defaultStyle,
                  children: <TextSpan>[
                    const TextSpan(
                        text: "Don't have account? ",
                        style: TextStyle(color: Colors.black)),
                    TextSpan(
                        text: 'Sign up!',
                        style: TextStyle(color: theme.colorScheme.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Registration(
                                        title: 'Registration Page',
                                      )),
                            );
                          }),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void goHomePage(BuildContext context) {
    if (!_isResponseError) {
      print('responseText: $_responseText');
      String name =
          String.fromCharCodes(nameController.text.runes);
      String jwt = String.fromCharCodes(_responseText.runes);
    
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
                  username: name,
                  isVisitor: _isVisitor,
                  JWTToken: jwt,
                )),
      );
      print("passed $jwt");
      nameController.text = '';
      passwordController.text = '';
    }
  }

  bool _isVisitor = false;
}
