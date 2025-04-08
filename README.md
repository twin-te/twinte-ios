# twinte-ios
Twin:teのiOS版ネイティブアプリ

## code format
コードフォーマットに
[swiftformat](https://github.com/nicklockwood/SwiftFormat)を用いています．  
導入方法例は[こちら](https://zenn.dev/usk2000/articles/b07d0ac3bc016a)．  
### 速攻導入&実行おすすめ方法
```
$ brew install swiftformat
$ swiftformat . 
```

## code generation

1. https://buf.build/docs/cli/installation/ を参考にBuf CLIをインストールしてください
2. V4APIディレクトリで以下のコマンドを実行するとV4API/Generatedディレクトリにコードが生成されます

```shell
buf generate --template ./buf.gen.yml </path/to/twin-te/proto>
```

