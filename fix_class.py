file_path = "lib/presentation/login_registration_screen/login_registration_screen.dart"
with open(file_path, "r") as f:
    lines = f.readlines()

output = []
skip = False
for line in lines:
    input_line = line.strip()
    if input_line.startswith("class LoginRegistrationScreen extends StatefulWidget {"):
        output.append("class LoginRegistrationScreen extends StatefulWidget {\n")
        output.append("  const LoginRegistrationScreen({super.key});\n\n")
        output.append("  @override\n")
        output.append("  State<LoginRegistrationScreen> createState() =>\n")
        output.append("      _LoginRegistrationScreenState();\n")
        output.append("}\n\n")
        output.append("class _LoginRegistrationScreenState extends State<LoginRegistrationScreen> {\n")
        skip = True
        continue
    
    if skip and input_line.startswith("bool _isLogin = true;"):
        skip = False
        output.append("  bool _isLogin = true;\n")
        continue

    if not skip:
        output.append(line)

with open(file_path, "w") as f:
    f.writelines(output)
