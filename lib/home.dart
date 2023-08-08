// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/services.dart';
import 'package:loginapp1/rest-client.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

Map<String, String> dropDownTrainingsMap = {}; //{'Select training': '-1'};
List<DropdownMenuItem<String>> menuList = [];
//List<DropdownMenuItem<String>> menuValueList = [];

class HomeMainPage extends StatefulWidget {
  HomeMainPage(
      {super.key,
      required this.username,
      required this.isVisitor,
      required this.token});

  final String username;
  final bool isVisitor;
  final String token;
  //List<String> menuItemList;

  @override
  State<HomeMainPage> createState() => _HomeMainPageState();
}

class _HomeMainPageState extends State<HomeMainPage> {
  String? firstItem = null;
  RestClient restClient = RestClient();
  late TextEditingController heightController;
  late TextEditingController weightController;

  double? myHeight;
  double? myWeight;

  @override
  void initState() {
    super.initState();
    heightController = TextEditingController();
    weightController = TextEditingController();
    initTrainingsList();
    setVisitorInfoValues(-1, -1);
  }

  void initTrainingsList() {
    restClient.getTrainings(widget.token).then((value) {
      if (value.isNotEmpty) {
        menuList.clear();
        dropDownTrainingsMap.clear();
        dropDownTrainingsMap.addAll({'Select training': '-1'});
        dropDownTrainingsMap.addAll(value);
        dropDownTrainingsMap.forEach((key, value) {
          menuList.add(DropdownMenuItem(value: value, child: Text(key)));
        });
        firstItem = "-1";
        setState(() {});
      } else {
        // empty list
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        children: [
          Center(
            child: Text(
                style: TextStyle(
                    fontSize: 1.7 * theme.textTheme.bodyLarge!.fontSize!),
                widget.isVisitor
                    ? "Hello, visitor ${widget.username}!"
                    : "Hello, coach ${widget.username}!"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Go back!"),
          ),
          SizedBox(
            height: 20,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.5,
            child: Center(
              child: DropdownButton<String>(
                //hint: const Text("Select training"),
                isExpanded: true,
                value: firstItem,
                icon: const Icon(Icons.arrow_drop_down),
                items: menuList,
                onChanged: (String? value) {
                  setState(() {
                    firstItem = value!;
                    print("Chosen $firstItem");
                  });
                },
              ),
            ),
          ),
          Center(
            child: ElevatedButton.icon(
                onPressed: () {
                  restClient
                      .markAttendance(
                          widget.token, int.parse(firstItem ?? "-1"))
                      .then((value) {
                    if (value.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Attendance marked successfully!')));
                    } else {
                      // any server/request error
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ERROR: ${value.body}')));
                    }
                  });
                },
                icon: const Icon(Icons.check),
                label: const Text("Mark attendance")),
          ),
          SizedBox(
            height: 30,
          ),
          Text("Your height is: ${myHeight ?? 'not set!'}",
              style: TextStyle(fontSize: theme.textTheme.bodyLarge!.fontSize!)),
          Text("Your weight is: ${myWeight ?? 'not set!'}",
              style: TextStyle(fontSize: theme.textTheme.bodyLarge!.fontSize!)),
          OutlinedButton(
              onPressed: () async {
                final dataMap = await openDialog();
                if (dataMap == null ||
                    dataMap['height']!.isEmpty ||
                    dataMap['weight']!.isEmpty) return;
                double height = double.parse(dataMap['height']!);
                double weight = double.parse(dataMap['weight']!);

                if (myHeight == null || myWeight == null) {
                  // height and weight not exist
                  restClient
                      .sendVisitorPhysicalInfo(widget.token, height, weight)
                      .then((resp) {
                    if (resp.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Your info set successfully!')));
                      setVisitorInfoValues(height, weight);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'ERROR: ${resp.body}, CODE ${resp.statusCode}')));
                    }
                  });
                } else {
                  restClient
                      .updateVisitorPhysicalInfo(widget.token, height, weight)
                      .then((resp) {
                    if (resp.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Your info updated successfully!')));
                      setVisitorInfoValues(height, weight);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'ERROR: ${resp.body}, CODE ${resp.statusCode}')));
                    }
                  });
                }
              },
              child: Text('Edit my parameters',
                  style: TextStyle(
                      fontSize: theme.textTheme.bodyLarge!.fontSize!))),
        ],
      ),
    );
  }

  void setVisitorInfoValues(double height, double weight) {
    if (height > 0 && weight > 0) {
      // data already available
      setState(() {
        myHeight = height;
        myWeight = weight;
      });
    } else {
      // firstly, get info and then set states
      restClient.getVisitorPhysicalInfo(widget.token).then((resp) {
        if (resp.statusCode == 200) {
          dynamic bodyJSON = jsonDecode(resp.body);
          height = double.parse(bodyJSON['height'].toString());
          weight = double.parse(bodyJSON['weight'].toString());
          setState(() {
            myHeight = height;
            myWeight = weight;
          });
        } else {
          setState(() {
            myHeight = null;
            myWeight = null;
          });
        }
      });
    }
  }

  Future<Map<String, String>?> openDialog() => showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("Edit values"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(hintText: "Enter new height"),
                  autofocus: true,
                  controller: heightController,
                ),
                SizedBox(
                  height: 15,
                ),
                TextField(
                  decoration: InputDecoration(hintText: "Enter new weight"),
                  controller: weightController,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: submit,
                child: Text("Submit"),
              )
            ],
          ));

  void submit() {
    Navigator.of(context).pop(
        {'height': heightController.text, 'weight': weightController.text});
  }
}

class HomePage extends StatefulWidget {
  HomePage(
      {super.key,
      required this.username,
      required this.isVisitor,
      // ignore: non_constant_identifier_names
      required this.JWTToken});

  final String username;
  final bool isVisitor;
  // ignore: non_constant_identifier_names
  final String JWTToken;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int destinationIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (destinationIndex) {
      case 0:
        page = HomeMainPage(
            username: widget.username,
            isVisitor: widget.isVisitor,
            token: widget.JWTToken);
      case 1:
        page = TrainingQRChooserPage(
          JWTToken: String.fromCharCodes(widget.JWTToken.runes),
        );
      case 2:
        page = StatisticsPage(jwtToken: widget.JWTToken);
      default:
        throw UnimplementedError('no widget for $destinationIndex');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Row(children: [
        SafeArea(
          child: NavigationRail(
            extended: false,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.qr_code),
                label: Text('Training'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.emoji_events),
                label: Text('Stats'),
              ),
            ],
            selectedIndex: destinationIndex,
            onDestinationSelected: (value) {
              setState(() {
                destinationIndex = value;
              });
            },
          ),
        ),
        Expanded(
            child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page)),
      ]),
    );
  }
}

class SeriesData {
  SeriesData(this.at, this.payload);
  final DateTime at;
  final num payload;
}

class StatisticsPage extends StatefulWidget {
  StatisticsPage({super.key, required this.jwtToken});

  String jwtToken;
  //String activityName;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late List<SeriesData> chartData = [];
  RestClient restClient = RestClient();

  @override
  void initState() {
    // chartData = <SeriesData>[
    //   //SeriesData(DateTime(2022, 02, 01), 20),
    //   // SeriesData(DateTime(2022, 02, 02), 10),
    //   // SeriesData(DateTime(2022, 02, 03), 20),
    //   // SeriesData(DateTime(2022, 02, 04), 30),
    //   // SeriesData(DateTime(2022, 02, 05), 20),
    //   // SeriesData(DateTime(2022, 02, 06), 30),
    //   // SeriesData(DateTime(2022, 02, 07), 10),
    //   // SeriesData(DateTime(2022, 02, 08), 20),
    //   // SeriesData(DateTime(2022, 02, 09), 10),
    //   // SeriesData(DateTime(2022, 02, 10), 30)
    // ];
    if (ActivityService.setFlag) {
      restClient
          .getUserStatistics(widget.jwtToken, ActivityService.activityName)
          .then((resp) {
        if (resp.statusCode == 200) {
          dynamic body = jsonDecode(resp.body);
          if (body is List) {
            for (dynamic actState in body) {
              double value = actState['unit_amount'] * actState['secs'];
              DateTime at = DateTime.parse(actState['at']);
              chartData.add(SeriesData(at, value));
            }
            setState(() {});
          } else {
            // incorrect response format
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ERROR: incorrect response format')));
          }
        } else {
          // server/connection error
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('ERROR: ${resp.statusCode} - ${resp.body}')));
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Text(
            'Тренажер: ${ActivityService.setFlag ? ActivityService.activityName : "не обрано!"}'),
        SfCartesianChart(
            primaryXAxis: DateTimeAxis(
              dateFormat: DateFormat("M-d\nH:M:S"),
            ),
            series: <ChartSeries<SeriesData, DateTime>>[
              LineSeries(
                  dataSource: chartData,
                  xValueMapper: (SeriesData sales, _) => sales.at,
                  yValueMapper: (SeriesData sales, _) => sales.payload)
            ]),
        ElevatedButton.icon(
            onPressed: !ActivityService.setFlag
                ? null
                : () {
                    List<SeriesData> t = [];

                    restClient
                        .getUserStatistics(
                            widget.jwtToken,
                            ActivityService.setFlag
                                ? ActivityService.activityName
                                : "")
                        .then((resp) {
                      if (resp.statusCode == 200) {
                        //print("body of statistics: ${resp.body}");
                        dynamic body = jsonDecode(resp.body);
                        if (body is List) {
                          for (dynamic actState in body) {
                            double value =
                                actState['unit_amount'] * actState['secs'];
                            DateTime at = DateTime.parse(actState['at']);
                            t.add(SeriesData(at, value));
                          }
                          setState(() {
                            chartData.clear();
                            chartData.addAll(t);
                          });
                        } else {
                          // incorrect response format
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('ERROR: incorrect response format')));
                        }
                      } else {
                        // server/connection error
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'ERROR: ${resp.statusCode} - ${resp.body}')));
                      }
                    });
                  },
            icon: Icon(Icons.refresh),
            label: Text("Refresh")),
      ]),
    );
  }
}

// ignore: must_be_immutable
class TrainingQRChooserPage extends StatefulWidget {
  // ignore: non_constant_identifier_names
  TrainingQRChooserPage({super.key, required this.JWTToken});

  // ignore: non_constant_identifier_names
  String JWTToken;

  @override
  State<TrainingQRChooserPage> createState() => _TrainingQRChooserPageState();
}

class _TrainingQRChooserPageState extends State<TrainingQRChooserPage> {
  CountDownController countDownController = CountDownController();
  int pickedDuration = 0;
  String scannedActivityQR = '';
  String responseText = '';
  bool isResponseError = false;
  RestClient restClient = RestClient();
  bool startedCountdown = false;
  int activityUsageId = -1;

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      scannedActivityQR = barcodeScanRes;
      ActivityService.activityName = barcodeScanRes;
      ActivityService.setFlag = true;
    });
  }

  bool startButtonBeEnabled() {
    return scannedActivityQR.isNotEmpty;
  }

  bool scanQrButtonBeEnabled() {
    return !startedCountdown;
  }

  Widget _button(
      {required String title, VoidCallback? onPressed, required Icon icon}) {
    return ElevatedButton.icon(
      // style: ButtonStyle(
      //   backgroundColor: MaterialStateProperty.all(Colors.purple),
      // ),
      icon: icon,
      onPressed: onPressed,
      label: Text(
        title,
        //style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //countDownController.pause();

    return Scaffold(
      body: Column(
        children: [
          Center(
            child: CircularCountDownTimer(
              // Countdown duration in Seconds.
              duration: pickedDuration,

              // Countdown initial elapsed Duration in Seconds.
              initialDuration: 0,

              // Controls (i.e Start, Pause, Resume, Restart) the Countdown Timer.
              controller: countDownController,

              // Width of the Countdown Widget.
              width: MediaQuery.of(context).size.width / 2,

              // Height of the Countdown Widget.
              height: MediaQuery.of(context).size.height / 2,

              // Ring Color for Countdown Widget.
              ringColor: Colors.grey[300]!,

              // Ring Gradient for Countdown Widget.
              ringGradient: null,

              // Filling Color for Countdown Widget.
              fillColor: Colors.purpleAccent[100]!,

              // Filling Gradient for Countdown Widget.
              fillGradient: null,

              // Background Color for Countdown Widget.
              backgroundColor: Colors.purple[500],

              // Background Gradient for Countdown Widget.
              backgroundGradient: null,

              // Border Thickness of the Countdown Ring.
              strokeWidth: 20.0,

              // Begin and end contours with a flat edge and no extension.
              strokeCap: StrokeCap.round,

              // Text Style for Countdown Text.
              textStyle: const TextStyle(
                fontSize: 33.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),

              // Format for the Countdown Text.
              textFormat: CountdownTextFormat.S,

              // Handles Countdown Timer (true for Reverse Countdown (max to 0), false for Forward Countdown (0 to max)).
              isReverse: false,

              // Handles Animation Direction (true for Reverse Animation, false for Forward Animation).
              isReverseAnimation: false,

              // Handles visibility of the Countdown Text.
              isTimerTextShown: true,

              // Handles the timer start.
              autoStart: false,

              // This Callback will execute when the Countdown Starts.
              onStart: () {
                // Here, do whatever you want
                debugPrint('Countdown Started');
              },

              // This Callback will execute when the Countdown Ends.
              onComplete: () {
                // Here, do whatever you want
                debugPrint('Countdown Ended');
              },

              // This Callback will execute when the Countdown Changes.
              onChange: (String timeStamp) {
                // Here, do whatever you want
                debugPrint('Countdown Changed $timeStamp');
              },

              /* 
                  * Function to format the text.
                  * Allows you to format the current duration to any String.
                  * It also provides the default function in case you want to format specific moments
                    as in reverse when reaching '0' show 'GO', and for the rest of the instances follow 
                    the default behavior.
                */
              timeFormatterFunction: (defaultFormatterFunction, duration) {
                if (duration.inSeconds == 0) {
                  // only format for '0'
                  return "Pick time!";
                } else {
                  // other durations by it's default format
                  return Function.apply(defaultFormatterFunction, [duration]);
                }
              },
            ),
          ),
          ElevatedButton.icon(
              onPressed: scanQrButtonBeEnabled() ? () => scanQR() : null,
              icon: const Icon(Icons.qr_code),
              label: const Text("Scan activity")),
          Text("Scanned activity code: $scannedActivityQR"),
          Text("Chosen duration: $pickedDuration sec."),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _button(
                title: "",
                icon: const Icon(Icons.play_arrow),
                onPressed: startButtonBeEnabled()
                    ? () {
                        dynamic bodyJSON;

                        restClient
                            .sendActivityUsage(
                                widget.JWTToken,
                                scannedActivityQR,
                                DateTime.now(),
                                DateTime.now()
                                    .add(Duration(seconds: pickedDuration)),
                                1)
                            .then((value) {
                          if (value.statusCode == 200) {
                            setState(() {
                              bodyJSON = jsonDecode(value.body);
                              activityUsageId = bodyJSON["id"];
                              isResponseError = false;
                              startCountDownController(context);
                            });
                          } else if (value.statusCode == 500) {
                            setState(() {
                              isResponseError = true;
                              startCountDownController(context);
                            });
                          } else {
                            setState(() {
                              isResponseError = true;
                              startCountDownController(context);
                            });
                          }
                        });
                      }
                    : null,
              ),
              const SizedBox(
                width: 10,
              ),
              _button(
                title: "",
                icon: const Icon(Icons.pause),
                onPressed: () => countDownController.pause(),
              ),
            ],
          ),
          const SizedBox(
            width: 10,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _button(
                  title: "Duration\nPick",
                  icon: const Icon(Icons.timer),
                  onPressed: () {
                    showDurationPicker(
                            context: context,
                            initialTime: const Duration(minutes: 3))
                        .then((value) {
                      setState(() {
                        pickedDuration = value!.inSeconds;
                      });
                    });
                  }),
              _button(
                  title: "Cancel",
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    if (startedCountdown) {
                      if (activityUsageId != -1) {
                        restClient
                            .deleteActivityUsage(
                                widget.JWTToken, activityUsageId)
                            .then((value) {
                          if (value.statusCode == 200) {
                            countDownController.reset();
                            startedCountdown = false;
                          } else if (value.statusCode == 500) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('ERROR: ${value.body}')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('ERROR while network request')));
                          }
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('ERROR: training session not started')));
                    }
                  }),
            ],
          ),
        ],
      ),
    );
  }

  void startCountDownController(BuildContext context) {
    if (!isResponseError) {
      setState(() {
        startedCountdown = true;
      });
      if (countDownController.isPaused) {
        countDownController.resume();
      } else {
        countDownController.restart(duration: pickedDuration);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ERROR while network request')));
    }
  }
}
