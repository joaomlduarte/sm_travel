import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// No emulador Android, 10.0.2.2 aponta para o computador.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => Carrinho(),
    child: const HotelApp(),
  ));
}

String reais(num valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class HotelApp extends StatelessWidget {
  const HotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S&M Hotel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1976a3)),
        useMaterial3: true,
      ),
      home: const Login(),
    );
  }
}

class DadosDestino {
  final String nome;
  final String imagem;
  final int valord;
  final int valorp;

  const DadosDestino(this.nome, this.imagem, this.valord, this.valorp);
}

const destinos = <DadosDestino>[
  DadosDestino('Angra dos Reis', 'imagens/angra.jpg', 384, 70),
  DadosDestino('Jericoacoara', 'imagens/jericoacoara.jpg', 571, 75),
  DadosDestino('Arraial do Cabo', 'imagens/arraial.jpg', 534, 65),
  DadosDestino('Florianópolis', 'imagens/florianopolis.jpg', 348, 85),
  DadosDestino('Madri', 'imagens/madri.jpg', 401, 85),
  DadosDestino('Paris', 'imagens/paris.jpg', 546, 95),
  DadosDestino('Orlando', 'imagens/orlando.jpg', 616, 105),
  DadosDestino('Las Vegas', 'imagens/las_vegas.jpg', 504, 110),
  DadosDestino('Roma', 'imagens/roma.jpg', 478, 85),
  DadosDestino('Chile', 'imagens/chile.jpg', 446, 95),
];

class Carrinho extends ChangeNotifier {
  DadosDestino? destino;
  int nDiarias = 0;
  int nPessoas = 0;
  int total = 0;

  void calcular(DadosDestino escolhido, int dias, int pessoas) {
    destino = escolhido;
    nDiarias = dias;
    nPessoas = pessoas;
    total = (dias * escolhido.valord) + (pessoas * escolhido.valorp);
    notifyListeners();
  }

  void limpar() {
    destino = null;
    nDiarias = 0;
    nPessoas = 0;
    total = 0;
    notifyListeners();
  }
}

class ApiUsuarios {
  Future<bool> entrar(String email, String senha) async {
    final resposta = await http.get(Uri.parse('$apiUrl/usuario'));
    if (resposta.statusCode != 200) throw Exception('Não foi possível acessar a API.');
    final usuarios = jsonDecode(resposta.body) as List<dynamic>;
    return usuarios.any((item) =>
        item['email'].toString().toLowerCase() == email.toLowerCase() &&
        item['senha'] == senha);
  }

  Future<void> cadastrar(String nome, String email, String senha) async {
    final resposta = await http.get(Uri.parse('$apiUrl/usuario'));
    if (resposta.statusCode != 200) throw Exception('Não foi possível acessar a API.');
    final usuarios = jsonDecode(resposta.body) as List<dynamic>;
    if (usuarios.any((item) => item['email'].toString().toLowerCase() == email.toLowerCase())) {
      throw Exception('Esse e-mail já está cadastrado.');
    }

    final dados = jsonEncode({'nome': nome, 'email': email, 'senha': senha});
    final cabecalho = {'Content-Type': 'application/json'};
    // A atividade pede o POST em cadastro-usuario. O segundo POST faz
    // a conta aparecer também no endpoint utilizado pelo login.
    final cadastro = await http.post(
      Uri.parse('$apiUrl/cadastro-usuario'), headers: cabecalho, body: dados,
    );
    if (cadastro.statusCode != 201) throw Exception('Não foi possível cadastrar.');
    final login = await http.post(
      Uri.parse('$apiUrl/usuario'), headers: cabecalho, body: dados,
    );
    if (login.statusCode != 201) {
      throw Exception('Cadastro salvo, mas não foi possível habilitar o login.');
    }
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final email = TextEditingController();
  final senha = TextEditingController();
  bool carregando = false;

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    if (email.text.trim().isEmpty || senha.text.isEmpty) {
      mostrar('Preencha o e-mail e a senha.');
      return;
    }
    setState(() => carregando = true);
    try {
      final valido = await ApiUsuarios().entrar(email.text.trim(), senha.text);
      if (!mounted) return;
      if (valido) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
      } else {
        mostrar('E-mail ou senha incorretos.');
      }
    } catch (_) {
      if (mounted) mostrar('Erro de conexão. Confira se o JSON Server está rodando.');
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  void mostrar(String texto) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S&M Hotel')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Icon(Icons.hotel, size: 76, color: Color(0xff1976a3)),
              const SizedBox(height: 18),
              const Text('Planeje sua viagem', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 28),
              TextField(controller: email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: senha, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              FilledButton(onPressed: carregando ? null : entrar,
                  child: Text(carregando ? 'Entrando...' : 'Entrar')),
              TextButton(onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const Cadastro())),
                  child: const Text('Criar uma conta')),
            ],
          ),
        ),
      ),
    );
  }
}

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  bool carregando = false;

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (nome.text.trim().isEmpty || !email.text.contains('@') || senha.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Digite nome, e-mail válido e senha com pelo menos 6 caracteres.')));
      return;
    }
    setState(() => carregando = true);
    try {
      await ApiUsuarios().cadastrar(nome.text.trim(), email.text.trim(), senha.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada! Agora faça o login.')));
    } catch (erro) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(erro is Exception && erro.toString().contains('conexão')
              ? 'Confira o JSON Server.' : 'Não foi possível cadastrar: $erro')));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
          TextField(controller: nome, decoration: const InputDecoration(
              labelText: 'Nome', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: senha, obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          FilledButton(onPressed: carregando ? null : salvar,
              child: Text(carregando ? 'Salvando...' : 'Cadastrar')),
        ]),
      )),
    );
  }
}

// A tela inicial pedida na aula: Stateless, Scaffold, AppBar, Container e ListView.
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S&M Hotel'), actions: [
        IconButton(tooltip: 'Checkout', icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const Checkout()))),
        IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: () {
          context.read<Carrinho>().limpar();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login()));
        }),
      ]),
      body: Container(
        color: const Color(0xfff3f7fa),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: destinos.length,
          itemBuilder: (context, index) {
            final item = destinos[index];
            return Destino(nomeDestino: item.nome, caminhoImagem: item.imagem,
                valord: item.valord, valorp: item.valorp);
          },
        ),
      ),
    );
  }
}

class Destino extends StatefulWidget {
  final String nomeDestino;
  final String caminhoImagem;
  final int valord;
  final int valorp;

  const Destino({super.key, required this.nomeDestino, required this.caminhoImagem,
      required this.valord, required this.valorp});

  @override
  State<Destino> createState() => _DestinoState();
}

class _DestinoState extends State<Destino> {
  int nDiarias = 0;
  int nPessoas = 0;
  int total = 0;

  void dias() => setState(() => nDiarias++);
  void n_pessoas() => setState(() => nPessoas++);

  void calctotal() {
    if (nDiarias == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione pelo menos uma diária.')));
      return;
    }
    setState(() => total = (nDiarias * widget.valord) + (nPessoas * widget.valorp));
    final item = destinos.firstWhere((d) => d.nome == widget.nomeDestino);
    context.read<Carrinho>().calcular(item, nDiarias, nPessoas);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Checkout()));
  }

  void limpar() {
    setState(() {
      nDiarias = 0;
      nPessoas = 0;
      total = 0;
    });
    final carrinho = context.read<Carrinho>();
    if (carrinho.destino?.nome == widget.nomeDestino) carrinho.limpar();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 393, height: 250,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Image.asset(widget.caminhoImagem, fit: BoxFit.cover),
          )),
          const SizedBox(height: 10),
          Text(widget.nomeDestino, style: Theme.of(context).textTheme.titleLarge),
          Text('Diária: ${reais(widget.valord)}  •  Por acompanhante: ${reais(widget.valorp)}'),
          const SizedBox(height: 6),
          Row(children: [
            IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'Adicionar diária', onPressed: dias),
            Expanded(child: Text('Diárias: $nDiarias')),
            IconButton(icon: const Icon(Icons.person_add_alt), tooltip: 'Adicionar acompanhante', onPressed: n_pessoas),
            Expanded(child: Text('Acompanhantes: $nPessoas')),
          ]),
          if (total > 0) Text('Total: ${reais(total)}'),
          Row(children: [
            Expanded(child: FilledButton(onPressed: calctotal, child: const Text('Calcular'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: limpar, child: const Text('Limpar'))),
          ]),
        ]),
      ),
    );
  }
}

class Checkout extends StatefulWidget {
  const Checkout({super.key});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  String pagamento = 'Cartão';

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<Carrinho>();
    final desconto = pagamento == 'Pix' ? carrinho.total * 0.10 : 0.0;
    final valorFinal = carrinho.total - desconto;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (carrinho.destino == null)
            const Text('Seu carrinho está vazio. Escolha um destino na tela inicial.')
          else ...[
            Image.asset(carrinho.destino!.imagem, height: 180, fit: BoxFit.cover),
            const SizedBox(height: 14),
            Text(carrinho.destino!.nome, style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            ListTile(title: const Text('Diárias'), trailing: Text('${carrinho.nDiarias} × ${reais(carrinho.destino!.valord)}')),
            ListTile(title: const Text('Acompanhantes'), trailing: Text('${carrinho.nPessoas} × ${reais(carrinho.destino!.valorp)}')),
            const Divider(),
            ListTile(title: const Text('Subtotal'), trailing: Text(reais(carrinho.total))),
            const Text('Forma de pagamento', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(title: const Text('Cartão'), value: 'Cartão',
                groupValue: pagamento, onChanged: (v) => setState(() => pagamento = v!)),
            RadioListTile<String>(title: const Text('Pix (10% de desconto)'), value: 'Pix',
                groupValue: pagamento, onChanged: (v) => setState(() => pagamento = v!)),
            if (desconto > 0) ListTile(title: const Text('Desconto Pix (10%)'),
                trailing: Text('- ${reais(desconto)}')),
            ListTile(title: const Text('Total da viagem', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(reais(valorFinal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => showDialog<void>(context: context, builder: (context) => AlertDialog(
              title: const Text('Resumo da viagem'),
              content: Text('Destino: ${carrinho.destino!.nome}\nPagamento: $pagamento\nTotal: ${reais(valorFinal)}'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
            )), child: const Text('Conferir pedido')),
            OutlinedButton(onPressed: () {
              context.read<Carrinho>().limpar();
              Navigator.pop(context);
            }, child: const Text('Limpar carrinho')),
          ],
        ]),
      )),
    );
  }
}
