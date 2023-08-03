import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'rest-client.dart';

class Registration extends StatefulWidget {
  const Registration({super.key, required this.title});

  final String title;

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  RestClient restClient = RestClient();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordRepeatController = TextEditingController();
  bool _passwordObscured = true;
  // int _statusCode = -1;
  String _responseText = '';
  bool _isResponseError = false;

  //late Future<String> respPong;

  @override
  void initState() {
    super.initState();
    _passwordObscured = true;
    // _statusCode = -1;
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_responseText,
                  style: TextStyle(
                      color: _isResponseError ? Colors.red : Colors.green,
                      fontSize: theme.primaryTextTheme.bodyLarge?.fontSize)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: TextFormField(
                  controller: nameController,
                  //style: theme.textTheme.labelSmall,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: TextFormField(
                  //style: theme.textTheme.labelSmall,
                  controller: emailController,
                  decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.mail, color: theme.colorScheme.primary),
                      border: OutlineInputBorder(),
                      labelText: "Email"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  //mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        //style: theme.textTheme.labelSmall,
                        controller: passwordController,
                        obscureText: _passwordObscured,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.key,
                                color: theme.colorScheme.primary),
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
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        //style: theme.textTheme.labelSmall,
                        controller: passwordRepeatController,
                        obscureText: _passwordObscured,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: "Repeat"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please repeat your password';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords are not the same!';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_isVisitor) {
                          restClient
                              .signUpVisitor(nameController.text,
                                  emailController.text, passwordController.text)
                              .then((value) {
                            dynamic bodyJSON;

                            if (value.statusCode == 200) {
                              setState(() {
                                _responseText = "Registration successful";
                                _isResponseError = false;
                              });
                            } else if (value.statusCode == 500) {
                              setState(() {
                                bodyJSON = jsonDecode(value.body);
                                _responseText = "ERROR: ${bodyJSON['message']}";
                                _isResponseError = true;
                              });
                            } else {
                              setState(() {
                                _responseText = "ERROR: ${value.body}";
                                _isResponseError = true;
                              });
                            }
                          });
                        }
                        else {
                          restClient
                              .signUpCoach(nameController.text,
                                  emailController.text, passwordController.text)
                              .then((value) {
                            dynamic bodyJSON;

                            if (value.statusCode == 200) {
                              //bodyJSON = jsonDecode(value.body);
                              setState(() {
                                _responseText = "Registration successful";
                                _isResponseError = false;
                              });
                            } else if (value.statusCode == 500) {
                              setState(() {
                                bodyJSON = jsonDecode(value.body);
                                _responseText = "ERROR: ${bodyJSON['message']}";
                                _isResponseError = true;
                              });
                            } else {
                              setState(() {
                                _responseText = "ERROR: ${value.body}";
                                _isResponseError = true;
                              });
                            }
                          });
                        }

                        // if (false) {
                        //   String eml =
                        //       String.fromCharCodes(emailController.text.runes);
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) => HomePage(
                        //               email: eml,
                        //               isVisitor: _isVisitor,
                        //             )),
                        //   );
                        //   emailController.text = '';
                        //   passwordController.text = '';
                        // }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill input')),
                        );
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      //style: defaultStyle,
                      children: <TextSpan>[
                        TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: Colors.black)),
                        TextSpan(
                            text: 'Sign in!',
                            style: TextStyle(color: theme.colorScheme.primary),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pop(context);
                              }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isVisitor = false;
}
