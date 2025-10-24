// lib/providers/news_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsService {
  // Sử dụng RSS feed từ VnExpress Sức khỏe thông qua rss2json API (miễn phí)
  final String _rss2jsonApi = 'https://api.rss2json.com/v1/api.json';

  // RSS feeds từ các nguồn tin Việt Nam
  final List<String> _rssFeedsVN = [
    'https://vnexpress.net/rss/suc-khoe.rss',
    'https://thanhnien.vn/rss/suc-khoe.rss',
  ];

  Future<List<Article>> fetchHealthNews() async {
    try {
      List<Article> allArticles = [];

      // Lấy tin từ VnExpress
      final vnexpressUrl =
          '$_rss2jsonApi?rss_url=${Uri.encodeComponent(_rssFeedsVN[0])}';

      final response = await http.get(
        Uri.parse(vnexpressUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'ok' && data['items'] != null) {
          List<dynamic> items = data['items'];

          for (var item in items.take(15)) {
            allArticles.add(Article(
              title: item['title'] ?? 'Không có tiêu đề',
              description: _cleanDescription(item['description'] ?? ''),
              url: item['link'] ?? '',
              urlToImage: _extractImage(item),
              publishedAt: item['pubDate'] ?? '',
              sourceName: 'VnExpress Sức khỏe',
            ));
          }
        }
      }

      // Nếu không lấy được tin, trả về tin mẫu
      if (allArticles.isEmpty) {
        return _getSampleNews();
      }

      return allArticles;
    } catch (e) {
      print('Error fetching news: $e');
      // Trả về tin mẫu khi có lỗi
      return _getSampleNews();
    }
  }

  String _cleanDescription(String html) {
    // Loại bỏ HTML tags
    String text = html.replaceAll(RegExp(r'<[^>]*>'), '');
    // Giới hạn độ dài
    if (text.length > 150) {
      text = '${text.substring(0, 150)}...';
    }
    return text;
  }

  String? _extractImage(dynamic item) {
    // Thử lấy ảnh từ nhiều nguồn
    if (item['enclosure'] != null && item['enclosure']['link'] != null) {
      return item['enclosure']['link'];
    }
    if (item['thumbnail'] != null) {
      return item['thumbnail'];
    }

    // Tìm ảnh trong content/description
    String content = item['content'] ?? item['description'] ?? '';
    final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = imgRegex.firstMatch(content);
    if (match != null) {
      return match.group(1);
    }

    return null;
  }

  List<Article> _getSampleNews() {
    return [
      Article(
        title: '10 thói quen tốt cho sức khỏe mỗi ngày',
        description:
            'Uống đủ nước, tập thể dục đều đặn và ngủ đủ giấc là những thói quen quan trọng giúp duy trì sức khỏe tốt.',
        url: 'https://vnexpress.net/suc-khoe',
        urlToImage:
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
        publishedAt: DateTime.now().toString(),
        sourceName: 'VnExpress Sức khỏe',
      ),
      Article(
        title: 'Lợi ích của việc tập yoga mỗi ngày',
        description:
            'Yoga giúp cải thiện sự linh hoạt, giảm stress và tăng cường sức khỏe tinh thần.',
        url: 'https://thanhnien.vn/suc-khoe',
        urlToImage:
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
        publishedAt:
            DateTime.now().subtract(const Duration(hours: 2)).toString(),
        sourceName: 'Thanh Niên Sức khỏe',
      ),
      Article(
        title: 'Chế độ ăn uống lành mạnh cho người bận rộn',
        description:
            'Những mẹo đơn giản để duy trì chế độ ăn uống lành mạnh ngay cả khi bạn có lịch trình bận rộn.',
        url: 'https://vnexpress.net/suc-khoe',
        urlToImage:
            'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400',
        publishedAt:
            DateTime.now().subtract(const Duration(hours: 5)).toString(),
        sourceName: 'VnExpress Sức khỏe',
      ),
      Article(
        title: 'Tầm quan trọng của giấc ngủ đối với sức khỏe',
        description:
            'Ngủ đủ 7-8 tiếng mỗi đêm giúp cơ thể phục hồi và tăng cường hệ miễn dịch.',
        url: 'https://thanhnien.vn/suc-khoe',
        urlToImage:
            'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=400',
        publishedAt:
            DateTime.now().subtract(const Duration(hours: 8)).toString(),
        sourceName: 'Thanh Niên Sức khỏe',
      ),
      Article(
        title: 'Cách phòng ngừa bệnh tim mạch',
        description:
            'Kiểm soát huyết áp, cholesterol và duy trì lối sống lành mạnh để bảo vệ tim mạch.',
        url: 'https://vnexpress.net/suc-khoe',
        urlToImage:
            'https://images.unsplash.com/photo-1628348068343-c6a848d2b6dd?w=400',
        publishedAt:
            DateTime.now().subtract(const Duration(days: 1)).toString(),
        sourceName: 'VnExpress Sức khỏe',
      ),
    ];
  }
}
