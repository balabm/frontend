import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EC2IpService {
  // TODO: Replace with your actual Lambda Function URL after creating it
  // Get this from: AWS Lambda Console → Your Function → Configuration → Function URL
  
  static const String lambdaFunctionUrl = 'https://7qm44pmvm22vo67oh7qet33ylm0fhlxe.lambda-url.ap-south-1.on.aws/';

  /// Fetches the current EC2 public IP from Lambda and updates SharedPreferences
  static Future<Map<String, String>?> fetchAndUpdateUrls() async {
    try {
      print('🔄 Fetching EC2 IP from Lambda...');
      print('🔄 Lambda URL: $lambdaFunctionUrl');

      final response = await http.get(
        Uri.parse(lambdaFunctionUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Parsed Data: $data');
        
        final ec2Ip = data['ec2_public_ip'] as String?;

        if (ec2Ip != null && ec2Ip.isNotEmpty) {
          print('✅ Got EC2 IP: $ec2Ip');

          // Build the URLs with the fetched IP
          final urls = {
            'bounding_box_url':
                'http://$ec2Ip:8001/cv/form-detection-with-box/',
            'ocr_text_url': 'http://$ec2Ip:8002/cv/ocr',
            'asr_url': 'http://$ec2Ip:8003/upload-audio-zip/',
            'llm_url': 'http://$ec2Ip:8004/get_llm_response_schemes',
          };

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          for (var entry in urls.entries) {
            await prefs.setString(entry.key, entry.value);
          }
          await prefs.setString('urlupdated', 'true');
          await prefs.setString('last_ec2_ip', ec2Ip);
          await prefs.setString(
              'last_ip_fetch_time', DateTime.now().toIso8601String());

          print('✅ URLs updated successfully');
          return urls;
        } else {
          print('❌ No EC2 IP found in response. Full data: $data');
          return null;
        }
      } else {
        print('❌ Failed to fetch EC2 IP');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
        
        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          print('   Error Details: ${errorData['error'] ?? 'Unknown error'}');
        } catch (e) {
          print('   Could not parse error response');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching EC2 IP: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Gets the last fetched EC2 IP from SharedPreferences
  static Future<String?> getLastFetchedIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_ec2_ip');
  }

  /// Gets the last IP fetch time
  static Future<DateTime?> getLastFetchTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('last_ip_fetch_time');
    if (timeStr != null) {
      return DateTime.parse(timeStr);
    }
    return null;
  }

  /// Check if we should fetch new IP (e.g., if it's been more than 1 hour)
  static Future<bool> shouldFetchNewIp() async {
    final lastFetchTime = await getLastFetchTime();
    if (lastFetchTime == null) return true;

    final difference = DateTime.now().difference(lastFetchTime);
    return difference.inHours >= 1; // Fetch if more than 1 hour old
  }
}
