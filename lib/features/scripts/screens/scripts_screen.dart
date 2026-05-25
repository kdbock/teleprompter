import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/script_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../team/providers/team_providers.dart';
import '../../../shared/models/script.dart';
import '../../../shared/models/team.dart';

class ScriptsScreen extends ConsumerStatefulWidget {
  const ScriptsScreen({super.key});

  @override
  ConsumerState<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends ConsumerState<ScriptsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final currentTeam = ref.watch(currentTeamProvider).value;
    final searchQuery = ref.watch(scriptSearchQueryProvider);

    // Get user's role in current team
    final userRole = currentTeam?.getRoleForUser(currentUser?.id ?? '');
    final canEdit = userRole?.canEdit ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Published'),
            Tab(text: 'Drafts'),
          ],
        ),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Script',
              onPressed: () => context.push('/scripts/new'),
            ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search scripts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(scriptSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref.read(scriptSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Script list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScriptList(ref.watch(
                    searchQuery.isEmpty
                        ? teamScriptsProvider
                        : filteredScriptsProvider)),
                _buildScriptList(ref.watch(publishedScriptsProvider)),
                _buildScriptList(ref.watch(draftScriptsProvider)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/scripts/new');
              },
              icon: const Icon(Icons.add),
              label: const Text('New Script'),
            )
          : null,
    );
  }

  Widget _buildScriptList(AsyncValue<List<Script>> scriptsAsync) {
    return scriptsAsync.when(
      data: (scripts) {
        if (scripts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No scripts found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/scripts/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Script'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: scripts.length,
          itemBuilder: (context, index) {
            final script = scripts[index];
            return _buildScriptCard(script);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading scripts: $error'),
      ),
    );
  }

  Widget _buildScriptCard(Script script) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/scripts/${script.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      script.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (script.isPublished)
                    Chip(
                      label: const Text('Published'),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    Chip(
                      label: const Text('Draft'),
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                script.content.length > 100
                    ? '${script.content.substring(0, 100)}...'
                    : script.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _metaItem(
                    icon: Icons.access_time,
                    label: dateFormat.format(script.createdAt),
                  ),
                  _metaItem(
                    icon: Icons.text_fields,
                    label: '${script.wordCount} words',
                  ),
                  _metaItem(
                    icon: Icons.timer,
                    label: '~${(script.estimatedReadingTime / 60).ceil()} min',
                  ),
                ],
              ),
              if (script.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: script.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 11,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}
