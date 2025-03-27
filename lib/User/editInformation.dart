import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'option/ChangeAvatar.dart';

class EditInformation extends StatefulWidget {
  final String idUser;
  final Map<String, dynamic> userData;

  const EditInformation({
    super.key,
    required this.idUser,
    required this.userData,
  });

  @override
  State<EditInformation> createState() => _EditInformationState();
}

class _EditInformationState extends State<EditInformation> {
  late TextEditingController _nameController;
  late TextEditingController _birthYearController;
  String selectedGender = 'Nam';
  bool isName = false;
  bool isBirth = false;
  bool _isChanged = false;
  String? selectedBirthYear;
  String? selectedBirthDate;

  @override
  void initState() {
    super.initState();
    selectedGender = widget.userData['gender'] ?? 'Nam';
    _nameController = TextEditingController(text: widget.userData['fullName'] ?? '');
    _birthYearController = TextEditingController(text: widget.userData['namSinh'] ?? '');
    selectedBirthYear = widget.userData['namSinh'];
    _nameController.addListener(_checkChanges);
    _birthYearController.addListener(_checkChanges);
  }


  void _checkChanges() {
    setState(() {
      _isChanged = _nameController.text != widget.userData['fullName'] ||
          _birthYearController.text != widget.userData['namSinh'] ||
          selectedGender != widget.userData['gender'];
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }
  void _updateUserData() async {
    final DatabaseReference userRef =
    FirebaseDatabase.instance.ref("users/${widget.idUser}");

    Map<String, dynamic> updatedData = {
      "fullName": _nameController.text,
      "namSinh": selectedBirthDate ?? widget.userData['namSinh'],
      "gender": selectedGender,
    };

    try {
      await userRef.update(updatedData);
      setState(() {
        _isChanged = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thành công!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFdfe3e6),
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 27),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: widget.userData['AVT'] != null && widget.userData['AVT'].isNotEmpty
                            ? NetworkImage(widget.userData['AVT'])
                            : null,
                        child: widget.userData['AVT'] == null || widget.userData['AVT'].isEmpty
                            ? const Icon(Icons.person, size: 40, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangeAvatar(idUser: widget.idUser),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: isName
                                  ? TextField(
                                controller: _nameController,
                                style: const TextStyle(fontSize: 18),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Nhập họ và tên",
                                ),
                              )
                                  : Text(
                                widget.userData['fullName'] ?? 'Chưa có tên',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            if (!isName)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    isName = true;
                                    isBirth = false;
                                  });
                                },
                              ),
                          ],
                        ),
                        const Divider(thickness: 1, height: 15, color: Color(0xFFF3F4F6)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedBirthDate ?? widget.userData['namSinh'] ?? 'Chưa có ngày sinh',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  builder: (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        primaryColor: Colors.green,
                                        colorScheme: ColorScheme.light(primary: Colors.green),
                                        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    selectedBirthDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                    _birthYearController.text = selectedBirthDate!;
                                    _checkChanges();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(thickness: 1, height: 15, color: Color(0xFFF3F4F6)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 70),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Nam',
                        groupValue: selectedGender,
                        activeColor: Colors.green,
                        onChanged: (String? value) {
                          setState(() {
                            selectedGender = value!;
                            _checkChanges();
                          });
                        },
                      ),
                      const Text('Nam'),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Nữ',
                        groupValue: selectedGender,
                        activeColor: Colors.green,
                        onChanged: (String? value) {
                          setState(() {
                            selectedGender = value!;
                            _checkChanges();
                          });
                        },
                      ),
                      const Text('Nữ'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChanged ? _updateUserData : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isChanged ? Colors.green : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}