# mischan-reminder
Slack等のチャットツールでサークル活動の通知とかをするbotです．   

## 開発環境
* docker 20.10.2  
* Ruby <s>2.7.2</s> -> 2.7.3
* Rails <s>6.1.1</s> -> 6.1.3 

## ローカルでの開発（puma起動確認まで）
クローン後にルートディレクトリ内で
```
$ docker-compose build (初回と再ビルドが必要な変更があったとき)
$ docker-compose up
```
* ログを垂れ流したくなければ`-d`をつける．  
* Webhookを受ける仕様上，ローカルではbotとしての動作確認は不可能なので，Herokuなど何らかのサーバを用意する必要がある．
* RailsはAPIモードでの動作なのでブラウザからアクセスしてもViewは生成されません．

## 導入方法
### Slack Appの作成
https://api.slack.com/apps

* App Credentials の Signing Secret を控える．
* OAuth Scope (Bot Token) - chat:write, im:write, commands, (im:read)
* Bot User OAuth Access Token (xoxb-...) を控える．
* Slash Command作成 Request URLは `https://<--server url-->/commands`
* InteractivityをOnにし，Request URLは `https://<--server url-->/interact`
* Event Subscriptionは `https://<--server url-->/event`
* Beta featuresを使っているので有効化
* 最後にWorkspaceにインストールする

### 環境変数
* `TZ` - `Asia/Toyko` に
* `SLACK_BOT_USER_TOKEN` - Bot User OAuth Access Token
* `SLACK_SIGNING_SECRET` - Signing Secret
* `PORTAL_AUTH_TOKEN` - Portal apiの認証用トークン
* `VERIFY_WITH` - Portalを使ったユーザー認証をするか (for debug)（使用する場合は`portal`にする）
* `DATABASE_URL`
* `DISCORD_WEBHOOK_URL` - DiscordのWebhookアドレスの`/api`以下
* `DISCORD_TRANSPORT_E927` - transportの使用切り替え (1で稼働)
* `E927_CHANNEL_ID` - 上記のchannel_id(slack)
* Herokuで動かす際はClearDBを導入して，`DB_HOSTNAME` `DB_NAME` `DB_USERNAME` `DB_PASSWORD` `DB_PORT` も設定した

### Rake Task
* リマインド送信は定期的にRakeタスクを実行することで動作している．Herokuで動かす際は`Heroku Scheduler` を使用．
* `rake reminder_task` 
  - `reminder`テーブルを確認し，時間の合致するものがあれば通知を送信．10分おきの実行を想定．
* `rake weekly_task` 
  - `weekly`テーブルを確認し，先一週間分の定期リマインドを`reminder`テーブルに追加する．1日に1回の動作を想定（結局日曜のみに動作するように記述してあるので，毎週日曜の実行でもOK）
