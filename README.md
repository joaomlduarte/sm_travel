# S&M Hotel

Atividade da aula de Aplicações Mobile. O aplicativo mostra 10 destinos, calcula a viagem e permite conferir o valor no checkout. No Pix, o total recebe 10% de desconto.

## Para rodar

Instale o Flutter, o Android Studio (com um emulador Android) e o Node.js. Na pasta do projeto, rode no terminal:

```bash
npm install -g json-server
json-server --watch db.json --port 3000
```

Deixe esse terminal aberto. Em outro terminal, na mesma pasta:

```bash
flutter create .
flutter pub get
flutter run
```

O comando `flutter create .` gera as pastas de configuração do Android e das outras plataformas. As telas do aplicativo estão em `lib/`.

No emulador Android, a API usa `http://10.0.2.2:3000`. Para usar no celular físico, passe o IP do seu computador na mesma rede:

```bash
flutter run --dart-define=API_URL=http://192.168.0.10:3000
```

Troque o IP do exemplo pelo seu. O manifesto Android já permite a conexão HTTP com o servidor local.

Para testar o login sem cadastrar: `aluno@teste.com` / `123456`. Também dá para criar uma conta na tela de cadastro. Este JSON Server é apenas para a atividade: a senha fica em texto no arquivo de exemplo.

O total segue a fórmula da aula: `(diárias × valor da diária) + (acompanhantes × valor por pessoa)`. O custo de acompanhantes entra uma vez por viagem, conforme o enunciado.
