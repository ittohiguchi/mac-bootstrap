# mac-bootstrap

macOS のユーザー作成後に、開発環境を再現可能な形でセットアップするための bootstrap script を管理します。

## 設定の適用

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
