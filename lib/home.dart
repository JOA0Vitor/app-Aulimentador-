import 'package:aulimentador/controller.dart';
import 'package:aulimentador/global_style.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final primeiroHorario = context.watch<HorarioProvider>().primeiroHorario;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 90,
              ),
              GestureDetector(
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  width: 150,
                ),
              ),
              const Text(
                'Proxima Refeição',
                style: TextStyle(
                    fontWeight: FontWeight.w400, fontSize: 25, height: 3),
              ),
              TextField(
                maxLines: 1,
                readOnly: true,
                style: const TextStyle(fontSize: 55),
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                // keyboardType: TextInputType.number,
                // inputFormatters: [
                //   FilteringTextInputFormatter.digitsOnly,
                //   HoraInputFormatter(),
                // ],
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: customBorderSide,
                  ),
                  focusedBorder:
                      OutlineInputBorder(borderSide: customBorderSide),
                ),
                controller: TextEditingController(
                    text: primeiroHorario?.format(context)),
              ),
              const SizedBox(
                height: 38,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(75, 75),
                        elevation: 10,
                        shadowColor: customWhite,
                        backgroundColor:
                            Provider.of<ThemeProvider>(context).buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                      child: Icon(
                        Icons.power_settings_new,
                        color: customYellow,
                        size: 55,
                      )),
                  ElevatedButton(
                      onPressed: () {
                        context.push('/horarios');
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(75, 75),
                        elevation: 10,
                          shadowColor: customWhite,
                        backgroundColor: customGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(4),
                      ),
                      child:  Icon(
                        Icons.settings,
                        color: customWhite,
                        size: 55,
                      )),
                ],
              ),
              ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(150, 150),
                    elevation: 10,
                      shadowColor: customWhite,
                    backgroundColor: customYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                  child: Text(
                    'ABRIR',
                    style: TextStyle(color: customGrey, fontSize: 40),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
