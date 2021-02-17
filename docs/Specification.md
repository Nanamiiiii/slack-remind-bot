# 仕様
## ソースファイル群
### app/controllers
* `slack_controller.rb` - SlackからのHTTPリクエストの処理

### app/services
* `command_service.rb` - Slashコマンドの処理
* `interact_service.rb` - interactiveコンテンツから受けたリクエストの処理
* `remind_service.rb` - リマインダーの確認，通知
* `weekly_service.rb` - 定期リマインド関連

### app/services/client
* `slack_client.rb` - Slackに対するリクエスト関連
* `portal_client.rb` - Portalに対するリクエスト関連

### lib/tasks
* `reminder.rake` - Rakeタスク `reminder_task`
* `weekly.rake` - Rakeタスク `weekly_task`

## データベース
### Table: weeklies
* `day` - Integer: 通知の曜日 日曜を0 (0~6)
* `remind_time` - Time: 予定の時刻
* `offset` - Integer: 通知オフセット（単位:hour）
* `place` - String: 場所

### Table: reminders
* `remind_day` - DateTime: 通知日時
* `comment` - Text: 通知コメント

### Table: messages
* `userid` - String: Slack ID
* `t_stamp` - String: 最後のメッセージのタイムスタンプ

### Table: channels
* `index` - String: チャンネル用途（現状'reminder'のみ）
* `ch_id` - String: チャンネルID

## 環境変数（README.mdより)
* `TZ` - `Asia/Toyko` に
* `SLACK_BOT_USER_TOKEN` - Bot User OAuth Access Token (xoxb-)
* `SLACK_SIGNING_SECRET` - Signing Secret
* `PORTAL_AUTH_TOKEN` - Portal apiの認証用トークン
* `VERIFY_WITH` - Portalを使ったユーザー認証をするか（使用する場合は`portal`にする）
* `DATABASE_URL`