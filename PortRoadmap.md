## Model Port Progress
| Schema         | Model                  |       Ported?      |
| ------         | -----                  |       :-----:      |
| public         | ads                    | :x: |
| factoids       | analytics              | :x: |
| ads            | analytics              | :x: |
| factoids       | authed_users           | :x: |
| ads            | authed_users           | :x: |
| public         | auto_moderation        | :white_check_mark: |
| public         | backoff                | :x: |
| public         | banned_addresses       | :white_check_mark: |
| users          | bans                   | :white_check_mark: |
| public         | blacklist              | :x: |
| users          | board_bans             | :white_check_mark:|
| public         | board_mapping          | :white_check_mark: |
| public         | board_moderators       | :white_check_mark: |
| metadata       | boards                 | :white_check_mark: |
| public         | boards                 | :white_check_mark: |
| public         | categories             | :white_check_mark: |
| public         | configurations         | :white_check_mark: |
| public         | factoids               | :x: |
| mentions       | ignored                | :white_check_mark:|
| messages       | ignored                | :x: |
| users          | ignored                | :white_check_mark: |
| public         | image_expirations      | :x: |
| public         | images_posts           | :x: |
| public         | invitations            | :white_check_mark: |
| users          | ips                    | :white_check_mark: |
| mentions       | mentions               | :white_check_mark: |
| public         | metric_rank_maps       | :white_check_mark: |
| public         | moderation_log         | :white_check_mark: |
| mod            | notes                  | :x: |
| public         | notifications          | :white_check_mark: |
| public         | permissions            | :white_check_mark: |
| public         | poll_answers           | :white_check_mark: |
| public         | poll_responses         | :white_check_mark: |
| public         | polls                  | :white_check_mark: |
| public         | posts                  | :white_check_mark: |
| users          | preferences            | :white_check_mark: |
| messages       | private_conversations  | :x: |
| messages       | private_messages       | :x: |
| users          | profiles               | :white_check_mark: |
| public         | ranks                  | :white_check_mark: |
| mod            | reports                | :x: |
| administration | reports_messages       | :x: |
| administration | reports_messages_notes | :x: |
| administration | reports_posts          | :x: |
| administration | reports_posts_notes    | :x: |
| administration | reports_users          | :x: |
| administration | reports_users_notes    | :x: |
| public         | roles                  | :white_check_mark: |
| public         | roles_permissions      | :white_check_mark: |
| public         | roles_users            | :white_check_mark: |
| ads            | rounds                 | :x: |
| users          | thread_subscriptions   | :white_check_mark: |
| users          | thread_views           | :white_check_mark: |
| metadata       | threads                | :white_check_mark: |
| public         | threads                | :white_check_mark: |
| public         | trust                  | :white_check_mark: |
| public         | trust_boards           | :white_check_mark: |
| public         | trust_feedback         | :white_check_mark: |
| public         | trust_max_depth        | :white_check_mark: |
| factoids       | unique_ip              | :x: |
| ads            | unique_ip              | :x: |
| public         | user_activity          | :white_check_mark: |
| messages       | user_drafts            | :x: |
| posts          | user_drafts            | :x: |
| public         | user_notes             | :x: |
| public         | users                  | :white_check_mark: |
| users          | watch_boards           | :white_check_mark: |
| users          | watch_threads          | :white_check_mark: |


## Hook List
| Module                   | Path                           | Method                   |       Ported?      |
| ------                   | -----                          | -----                    |       :-----:      |
| bct-activity             | users.find.post                | userActivity             | :x: |
| bct-activity             | posts.byThread.post            | userPostActivity         | :white_check_mark: |
| bct-activity             | posts.create.post              | updateUserActivity       | :white_check_mark: |
| bct-trust                | posts.byThread.post            | userTrust                | :white_check_mark: |
| bct-trust                | posts.byThread.post            | showTrust                | :white_check_mark: |
| ept-auto-moderation      | posts.create.pre               | moderate                 | :white_check_mark: |
| ept-auto-moderation      | posts.update.pre               | moderate                 | :x: |
| ept-auto-moderation      | threads.create.pre             | moderate                 | :white_check_mark: |
| ept-ignore-users         | users.find.post                | userIgnored              | :x: |
| ept-ignore-users         | posts.patroller.post           | isIgnored                | :x: |
| ept-ignore-users         | posts.byThread.post            | isIgnored                | :white_check_mark: |
| ept-mentions             | posts.byThread.post            | userIdToUsername         | :white_check_mark: |
| ept-mentions             | posts.patrol.post              | userIdToUsername         | :x: |
| ept-mentions             | posts.pageByUser.post          | userIdToUsername         | :x: |
| ept-mentions             | posts.pageFirstPostByUser.post | userIdToUsername         | :x: |
| ept-mentions             | posts.find.post                | userIdToUsername         | :x: |
| ept-mentions             | posts.search.post              | userIdToUsername         | :x: |
| ept-mentions             | mentions.page.post             | userIdToUsername         | :x: |
| ept-mentions             | portal.view.post               | userIdToUsername         | :x: |
| ept-mentions             | posts.update.post              | userIdToUsername         | :x: |
| ept-mentions             | posts.update.post              | correctTextSearchVector  | :x: |
| ept-mentions             | posts.create.pre               | usernameToUserId         | :white_check_mark: |
| ept-mentions             | posts.update.pre               | usernameToUserId         | :x: |
| ept-mentions             | threads.create.pre             | usernameToUserId         | :white_check_mark: |
| ept-mentions             | posts.create.post              | createMention            | :white_check_mark: |
| ept-mentions             | posts.create.post              | correctTextSearchVector  | :white_check_mark: |
| ept-mentions             | posts.update.post              | removeMentionIds         | :x: |
| ept-mentions             | threads.create.post            | createMention            | :white_check_mark: |
| ept-mentions             | threads.create.post            | correctTextSearchVector  | :white_check_mark: |
| ept-mentions             | users.find.post                | userIgnoredMentions      | :x: |
| ept-messages             | users.find.post                | userIgnoredMessages      | :x: |
| ept-messages             | conversations.create.pre       | checkUserIgnoredMessages | :x: |
| ept-messages             | messages.create.pre            | checkUserIgnoredMessages | :x: |
| ept-rank                 | posts.byThread.post            | getRankData              | :white_check_mark: |
| ept-rank                 | users.find.post                | getRankData              | :x: |
| ept-thread-notifications | posts.create.post              | emailSubscribers         | :white_check_mark: |
| ept-rank                 | posts.create.post              | subscribeToThread        | :white_check_mark: |
| ept-rank                 | threads.create.post            | subscribeToThread        | :white_check_mark: |
| ept-watchlist            | threads.byBoard.parallel       | watchingBoard            | :white_check_mark: |
| ept-watchlist            | posts.byThread.parallel        | watchingThread           | :white_check_mark: |
| ept-watchlist            | posts.create.post              | watchingThread           | :white_check_mark: |





