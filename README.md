# rails環境構築

### 参考url
[http://qiita.com/emadurandal/items/e43c4896be1df60caef0](http://qiita.com/emadurandal/items/e43c4896be1df60caef0)


- 事前準備
```
$ rbenv local 2.3.0
$ ndenv local v6.10.2
$ rbenv exec gem install bundler
```

- プロジェクトのフォルダのみにGemをインストールする

```
$ echo "source 'http://rubygems.org'" >> Gemfile
$ echo "gem 'rails', '4.2.3'" >> Gemfile
$ bundle install --path vendor/bundle
```
`※ nokogiriが結構インストールするのに時間かかる`


- railsプロジェクトを作成（turbolinksは最初から無効）
```
$ rails new ./ -d postgresql --skip-bundle --skip-turbolinks
$ bundle install --path vendor/bundle
$ rake db:create
```
`※ 事前にエイリアスで「bundle exec rails　-> rails」と「bundle exec rake　-> rake」は張り替えている`


- gitの管理対象から以下を外す
```
$ echo '/vendor/bundle' >> .gitignore
$ echo '.env' >> .gitignore
$ echo '.idea/' >> .gitignore
```

# ログイン機能を作成

- deviseをインストールする
```
$ echo "gem 'devise'" >> Gemfile
$ bundle install --path vendor/bundle
```

- deviseに必要な初期設定とそのファイルを生成
```
$ rails generate devise:install
```

- Userモデルを作成する
```
$ rails g devise user
$ rake db:migrate
```

- Viewを作成する
```
$ rails generate devise:views
```


# Deviseのエラーメッセージを日本語化する

- デフォルトの設定を日本語にする

`config/application.rb`に以下を記載
```
config.i18n.default_locale = :ja
```

- 日本語の辞書ファイルを作成する

`config/locales/devise.ja.yml`を作成
`config/locales/devise.ja.yml`に日本語に翻訳された辞書をセット

[参考辞書リストはこちら](https://gist.github.com/kaorumori/7276cec9c2d15940a3d93c6fcfab19f3)


# バリデーションエラーメッセージの日本語化

`config/locales/ja.yml`を作成

[参考辞書リストはこちら](https://github.com/svenfuchs/rails-i18n/blob/master/rails/locale/ja.yml)


# 写真投稿用の機能を作成

- controller作成
```
$ rails g controller picture index
```

- model作成
```
$ rails g model picture photo:string comment:text
```

## 画像アップローダーとしてcarrierwaveとmini_magickをインストールする

- homebrewにimagemagickをインストールする（すでに入っていれば必要ない）
```
$ brew update 
$ brew install imagemagick
```

- carrierwaveとmini_magickをインストールする
```
$ echo "gem 'carrierwave'" >> Gemfile
$ echo "gem 'mini_magick'" >> Gemfile
$ bundle install --path vendor/bundle
```

- carrierwaveの初期設定を行う。
```
$ rails generate uploader Photo
```

- models/picture.rbにcarrierwave用の設定を行う
```
mount_uploader :photo, PhotoUploader
```

- 画像のリサイズ
`app/uploaders/photo_uploader.rb`に以下を記載
```
include CarrierWave::MiniMagick
process resize_to_limit: [600, 600]
```

- 投稿するviewに以下を記載
`app/views/picture/_form.html.erb`
```
<%= f.file_field :photo %>
<%= f.hidden_field :photo_cache %><!-- バリデーションエラー時の対策 -->
```

- 一覧画面に投稿画像を表示
`app/views/picture/index.html.erb`
```
<% @pictures.each do |picture| %>
  <%= image_tag(picture.photo, alt: '') %>
  <p><%= picture.comment %></p>
<% end %>
```

- 一連のCURD処理を作成

`〜省略〜`

- 画像アップロード時にプレビューできるようにjsを書く

`app/assets/javascripts/picture.js`
```
var picUpLoadButton = document.querySelector('.js-picUpLoadButton');
var previewImg = document.querySelector('.js-previewPhoto');

picUpLoadButton && picUpLoadButton.addEventListener('change', function (e) {
  var file = e.target.files[0];
  var reader = new FileReader();

  reader.onload = (function(file) {
    return function(e) {
      previewImg.src = e.target.result;
    };
  })(file);
  reader.readAsDataURL(file);
});
```

`app/views/picture/_form.html.erb`
```
<div class="picture-preview">
  <%= image_tag(@picture.photo, alt: '', class: 'js-previewPhoto') %>
</div>
```

# ユーザ新規登録した際に認証メールが送信されるようにする

- ローカル開発確認用にletter_opener_webをインストールする
`Gemfile`
```
group :development do
  gem 'letter_opener_web'
end
```

- letter_opener_webのroutingを設定する

`config/routes.rb`
```
if Rails.env.development?
  mount LetterOpenerWeb::Engine, at: '/letter_opener'
end
```
- 開発環境でメール送信の際、letter_opener_webを使用するように設定する

`config/environments/development.rb`
```
config.action_mailer.default_url_options = { host: 'localhost:3000' }
config.action_mailer.delivery_method = :letter_opener_web
```

- Userモデルに`:confirmable`を追加

`app/models/user.rb`
```
devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable
```

- メール認証に必要なカラムを追加

```
$ rails g migration add_confirmable_to_devise
```

- 上記コマンドで生成されたマイグレーションファイルを書き換える

```
class AddConfirmableToDevise < ActiveRecord::Migration
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true
    # User.reset_column_information # Need for some types of updates, but not for update_all.

    execute("UPDATE users SET confirmed_at = NOW()")
  end

  def down
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
    remove_columns :users, :unconfirmed_email # Only if using reconfirmable
  end
end
```

migration fileを編集後`rake db:migrate`を実行
もし、すでにユーザを新規登録していた場合はRailsコンソールを立ち上げて`User.delete_all`で全部削除

# アソシエーション

- Pictureモデルに`user_id`カラムを追加
```
$ rails g migration AddUserIdToPictures user_id:integer
```

- UserモデルのレコードがPictureモデルのレコードを複数もつことを定義する

`app/models/user.rb`
```
has_many :pictures
```

# 自分の投稿にだけ、編集と削除をさせる

`app/views/picture/index.html.erb`
```
<% if picture.user_id == @userId %>
  <%= link_to '編集', edit_picture_path(picture.id) %>
  <%= link_to picture_path(picture.id), method: :delete ,data: { confirm: '本当に削除していいですか？' } do %>
      削除
  <% end %>
<% end %>
```

`app/controllers/picture_controller.rb`
```
def checkMatchUser
  if current_user.id != @picture.user_id
    redirect_to picture_index_path
  end
end
```
など


# その他gem

- gem 'pry-rails'
- gem 'better_errors'
