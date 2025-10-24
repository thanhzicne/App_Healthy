// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/news_model.dart';
import '../providers/news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Article>> _futureNews;
  final NewsService _newsService = NewsService();

  @override
  void initState() {
    super.initState();
    _futureNews = _newsService.fetchHealthNews();
  }

  Future<void> _refreshNews() async {
    setState(() {
      _futureNews = _newsService.fetchHealthNews();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Vừa xong';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.green.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshNews,
                  color: Colors.blue.shade700,
                  child: FutureBuilder<List<Article>>(
                    future: _futureNews,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      } else if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error.toString());
                      } else if (snapshot.hasData) {
                        final articles = snapshot.data!;
                        if (articles.isEmpty) {
                          return _buildEmptyState();
                        }
                        return _buildNewsList(articles);
                      } else {
                        return _buildEmptyState();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.newspaper, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tin Tức Sức Khỏe',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Cập nhật mới nhất',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tải tin tức...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.error_outline,
                  size: 60, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              'Không thể tải tin tức',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Vui lòng kiểm tra kết nối mạng',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'Không có tin tức',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kéo xuống để làm mới',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList(List<Article> articles) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return _buildNewsCard(article, index);
      },
    );
  }

  Widget _buildNewsCard(Article article, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openArticle(article),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              if (article.urlToImage != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      Image.network(
                        article.urlToImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildImageLoader();
                        },
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(article.publishedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildPlaceholderImage(),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.sourceName ?? 'Nguồn không rõ',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (article.description.isNotEmpty)
                      Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),

                    // Read More Button
                    Row(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Đọc thêm',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios,
                                  size: 12, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade100, Colors.green.shade100],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Icon(
        Icons.health_and_safety,
        size: 80,
        color: Colors.white.withOpacity(0.7),
      ),
    );
  }

  Widget _buildImageLoader() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey.shade200,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
        ),
      ),
    );
  }

  Future<void> _openArticle(Article article) async {
    try {
      final uri = Uri.parse(article.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showSnackBar('Không thể mở liên kết', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi khi mở bài viết', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
