# News2Kindle
ニュースサイトを定期的にスクレイピングしてmobiファイルを生成し、Kindle Personal Documentへメールで送信するコマンドライン・ツール

ニュースの電子書籍化と配信を自動化するソフトウェアとしては電子書籍管理ツールであるCalibreが豊富なレシピで抜きん出た存在ですが、クライアントPCを常時稼動しておかなくてはならず、環境面で稼働が難しい面があります。そこで、サーバ上でcronタスクとして稼働する仕組みを作りました。ただしレシピはまだぜんぜんありません(作者が使っている日経新聞電子版とINTERNET Watch、tDiaryのみ)。

## 仕組み
cronタスクとして動かすことを前提にしています。

実際にどのサイトをmobiファイル化するのかという指定は、`~/.news2kindle`ないし`./news2kindle.yaml`のconfigファイルで指定します。configファイルのサンプルです:

```yaml
:tasks:
  sites1:
    :media:
    - foo
    - bar
    :receiver:
    - receiver1@example.com
  sites2:
    :media:
    - buz
    :receiver:
    - dropbox:/Public
:sender: hoge@example.com
:email:
  :address: smtp.sendgrid.net
  :port: 587
  :user_name: yes
  :password: yes
  :authentication: :plain
:mongodb_uri: mongodb://localhost:27017/news2kindle
```

cronタスクを動かす時間によって、異なるニュースサイトにアクセスしたり、送り先を変えたいでしょう。そのため、コマンドに指定する「タスク(:tasks)」を分けて、それぞれに「メディア(:media)」と「送り先(:receiver)」を指定できるようになっています。receiverにはメールアドレスの他に「dropbox:」で始まるDropboxのディレクトリも指定できます。Dropboxを利用する場合には、Dropboxの開発者向けサービスから各種APIトークンを取得しておく必要があります。

「送信元(:sender)」は、KPDサービスに登録してあるメールアドレスを指定します。

「:email」は、メールサーバ(SMTP)の設定です。プログラムを動かしている環境からアクセスできるメールサーバの情報を指定します。なお、メールサーバが認証を必要とする場合は「:user_name」や「:password」を指定する必要がありますが、configファイルには直接書くことはありません。これらの項目を「yes」にしておくと、初回実行時にプログラムが聞いてきます(~/.pit/default.yamlというファイルに保存されます)。

「:mongodb_uri」はURIの重複チェックをする場合にMongoDBの情報を指定します。日に何度も動かすと、すでに取得済みの記事が重複して含まれてしまいますが、それをチェックして除外したい場合に利用します。

mobiファイルの生成に成功すると、指定したアドレスにメールを送ったり、Dropboxの指定フォルダに保存します。メールアドレスは、実際は〜@kindle.comになるでしょう(:receiver)。また、送信元のアドレスもKindle Personal Documentで許可したアドレスを指定して置く必要があります(:sender)。

## 動かし方
インストール方法:

```sh
% gem install news2kindle
```

news2kindleコマンドを実行すると、ヘルプが出ます。適切なconfigファイルがあれば、そこに記述してあるタスクを指定することで、mobiファイルが生成され、指定した送信先へ送られます。


## ジェネレータの作り方
あとで書く。

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tdtds/news2kindle.
