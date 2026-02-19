import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_app_bar.dart';

class RentalFeedbackScreen extends StatefulWidget {
  final String rentalId;
  final String vehicleName;

  const RentalFeedbackScreen({
    super.key,
    required this.rentalId,
    required this.vehicleName,
  });

  @override
  State<RentalFeedbackScreen> createState() => _RentalFeedbackScreenState();
}

class _RentalFeedbackScreenState extends State<RentalFeedbackScreen> {
  int _vehicleRating = 0;
  int _experienceRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  void _submitFeedback() async {
    if (_vehicleRating == 0 || _experienceRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor califica ambos aspectos')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tus comentarios!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(title: 'Calificar Experiencia'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué te pareció el ${widget.vehicleName}?',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildStarRating((val) => setState(() => _vehicleRating = val), _vehicleRating),
            
            SizedBox(height: 4.h),
            Text(
              '¿Cómo calificarías el servicio en general?',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildStarRating((val) => setState(() => _experienceRating = val), _experienceRating),
            
            SizedBox(height: 4.h),
            Text(
              'Escribe una reseña (Opcional)',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Cuéntanos más sobre tu experiencia...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            SizedBox(height: 6.h),
            SizedBox(
              width: double.infinity,
              height: 7.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1538),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar Comentarios', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(Function(int) onRatingChanged, int currentRating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () => onRatingChanged(index + 1),
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }
}
