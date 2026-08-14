# mac-bootstrap

macOS のユーザー作成後に、開発環境を再現可能な形でセットアップするための bootstrap script を管理します。

## 設定の適用

事前にHomebrewをインストールしてください。次のコマンドは、`Brewfile`に定義したアプリとOh My Zshをインストールし、macOS設定を適用します。アプリの初回起動、ログイン、権限付与は行いません。既存の`~/.zshrc`は保持します。

```sh
./apply.sh
```

## 開発準備

```sh
brew install gitleaks pre-commit
pre-commit install
```

全ファイルを検査する場合は、次を実行します。

```sh
pre-commit run --all-files
```
