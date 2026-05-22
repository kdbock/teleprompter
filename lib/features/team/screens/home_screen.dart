import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../team/providers/team_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final userTeamsAsync = ref.watch(userTeamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Teleprompter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.push('/profile');
            },
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            // User not logged in, navigate to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const Center(child: CircularProgressIndicator());
          }

          return userTeamsAsync.when(
            data: (teams) {
              if (teams.isEmpty) {
                // No teams, show create team prompt
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_add,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome, ${user.displayName}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create or join a team to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () {
                          context.push('/create-team');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Team'),
                      ),
                    ],
                  ),
                );
              }

              // Show teams list
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: teams.length + 1, // +1 for quick actions card
                itemBuilder: (context, index) {
                  // First item: Quick actions
                  if (index == 0) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      context.push('/scripts');
                                    },
                                    icon: const Icon(Icons.description),
                                    label: const Text('Scripts'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // TODO: Navigate to recordings
                                    },
                                    icon: const Icon(Icons.videocam),
                                    label: const Text('Recordings'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Team cards
                  final team = teams[index - 1];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(team.name[0].toUpperCase()),
                      ),
                      title: Text(team.name),
                      subtitle: Text('${team.members.length} members'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        context.push('/team/${team.id}');
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading teams: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
