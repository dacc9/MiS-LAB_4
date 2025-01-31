import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lab_4/services/database_service.dart';
import 'package:lab_4/models/exam_event_model.dart';
import 'package:lab_4/services/notification_service.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _pickLocationOnMap() async {
    final LatLng? result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Локацијата е успешно избрана')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate() && _latitude != null && _longitude != null) {
      try {
        final dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final event = ExamEvent(
          title: _titleController.text,
          dateTime: dateTime,
          location: 'Локација: $_latitude, $_longitude',
          latitude: _latitude!,
          longitude: _longitude!,
        );

        final dbService = DatabaseService();
        await dbService.insertEvent(event);

        if (!mounted) return;

        final notificationService = NotificationService();
        if (!await notificationService.scheduleNotification(event)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Потсетникот не може да биде поставен. Проверете ги дозволите за апликацијата.'),
              duration: Duration(seconds: 5),
            ),
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Успешно зачуван испит')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Грешка при зачувување: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ве молиме пополнете го насловот и изберете локација')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Додади нов испит')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Наслов на испитот'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Внесете наслов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Датум: ${_selectedDate.toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text('Време: ${_selectedTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickLocationOnMap,
                child: const Text('Избери локација на мапа'),
              ),
              const SizedBox(height: 16),
              if (_latitude != null && _longitude != null)
                Text(
                  'Локација: $_latitude, $_longitude',
                  style: const TextStyle(color: Colors.green),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveEvent,
                child: const Text('Зачувај'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}