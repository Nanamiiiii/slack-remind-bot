# Ruby関連の更新時のメモ
## Ruby
* `Dockerfile`記載のイメージのバージョンを変える `FROM ruby:2.X.X`
* `Gemfile`記載のrubyバージョンを変える `ruby '2.X.X'`
* `Gemfile.lock`を空に

## Bundler
* `Dockerfile`内に定義した環境変数`BUNDLER_VERSION`を変更
* `Gemfile.lock`を空に

いずれも最後に`docker-compose build --no-cache`

## 各種Gem
* `docker-compose run web bundle update`
