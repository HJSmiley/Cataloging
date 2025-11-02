import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../services/api_service.dart';
import '../models/catalog.dart';
import 'catalog_detail_screen.dart';
import 'create_catalog_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isServerConnected = false;

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    final isConnected = await ApiService.testConnection();
    setState(() {
      _isServerConnected = isConnected;
    });

    if (isConnected) {
      // 서버 연결이 성공하면 카탈로그 목록을 로드
      if (mounted) {
        context.read<CatalogProvider>().loadCatalogs();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카탈로깅'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkServerConnection();
              if (_isServerConnected) {
                context.read<CatalogProvider>().loadCatalogs();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 서버 연결 상태 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isServerConnected
                ? Colors.green.shade100
                : Colors.red.shade100,
            child: Row(
              children: [
                Icon(
                  _isServerConnected ? Icons.check_circle : Icons.error,
                  color: _isServerConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isServerConnected
                      ? '서버 연결됨 (localhost:8000)'
                      : '서버 연결 실패 - 백엔드 서버를 확인해주세요',
                  style: TextStyle(
                    color: _isServerConnected
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 카탈로그 목록
          Expanded(
            child: _isServerConnected
                ? _buildCatalogList()
                : _buildServerDisconnectedView(),
          ),
        ],
      ),
      floatingActionButton: _isServerConnected
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCatalogScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCatalogList() {
    return Consumer<CatalogProvider>(
      builder: (context, catalogProvider, child) {
        if (catalogProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (catalogProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '오류가 발생했습니다',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(catalogProvider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    catalogProvider.clearError();
                    catalogProvider.loadCatalogs();
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        if (catalogProvider.catalogs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '카탈로그가 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '+ 버튼을 눌러 첫 번째 카탈로그를 만들어보세요',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: catalogProvider.catalogs.length,
          itemBuilder: (context, index) {
            final catalog = catalogProvider.catalogs[index];
            return _buildCatalogCard(catalog);
          },
        );
      },
    );
  }

  Widget _buildCatalogCard(Catalog catalog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CatalogDetailScreen(catalog: catalog),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      catalog.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: catalog.completionRate == 100
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${catalog.completionRate.toInt()}%',
                      style: TextStyle(
                        color: catalog.completionRate == 100
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                catalog.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      catalog.category,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${catalog.ownedCount}/${catalog.itemCount} 아이템',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerDisconnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '서버에 연결할 수 없습니다',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '백엔드 서버가 실행 중인지 확인해주세요',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkServerConnection,
            child: const Text('다시 연결'),
          ),
        ],
      ),
    );
  }
}
