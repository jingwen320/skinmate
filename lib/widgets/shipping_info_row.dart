import 'package:flutter/material.dart';

class ShippingInfoRow extends StatelessWidget {
  final String region;
  final String rate;
  final String timeframe;

  const ShippingInfoRow({
    super.key,
    required this.region,
    required this.rate,
    required this.timeframe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                region, 
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14, 
                  color: Color(0xFF2E2F2D),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeframe, 
                style: const TextStyle(
                  fontSize: 11, 
                  color: Color(0xFF5B5C5A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            rate,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 14, 
              color: Color(0xFF91462E),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ),
      ],
    );
  }
}