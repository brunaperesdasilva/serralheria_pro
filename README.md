# Serralheria Pro

Aplicativo de gestão para serralheiros e pequenas serralherias, desenvolvido em Flutter. O sistema centraliza clientes, orçamentos, estoque e agenda, com autenticação segura, sincronização em nuvem e geração de propostas profissionais em PDF.

## Funcionalidades

- Cadastro, edição e exclusão de clientes.
- Orçamentos com serviços, materiais, quantidades e valores.
- Cálculo automático de subtotal, margem de lucro, desconto, adicional e total.
- Estados de orçamento: rascunho, enviado, aprovado e recusado.
- Sugestão de margem baseada na média e mediana dos orçamentos aprovados.
- Geração de orçamento profissional em PDF com dados e logotipo da empresa.
- Compartilhamento do PDF pelo WhatsApp e por outros aplicativos.
- Controle de estoque com entradas, saídas, histórico e alerta de estoque mínimo.
- Agenda de serviços com status, cliente, orçamento, endereço e observações.
- Perfil da empresa com CNPJ, contatos, endereço e logotipo.
- Sincronização dos dados entre dispositivos.
- Migração dos registros antigos armazenados no SQLite.
- Suporte ao funcionamento offline por meio do cache do Firestore.

## Tecnologias

- **Flutter e Dart** — aplicativo multiplataforma.
- **Firebase Authentication** — login, cadastro, recuperação de senha e sessão do usuário.
- **Cloud Firestore** — armazenamento e sincronização dos dados.
- **SQLite** — leitura e migração dos registros locais antigos.
- **pdf e printing** — geração e visualização dos orçamentos em PDF.
- **share_plus** — compartilhamento dos documentos.
- **url_launcher** — integração com aplicativos externos.

## Organização do projeto

```text
lib/
├── core/        # Tema, componentes, validações e tratamento de erros
├── data/        # SQLite, Firebase, repositórios e migração
├── domain/      # Regras de negócio e serviços
├── models/      # Modelos de dados
└── screens/     # Telas e navegação
```

Os módulos acessam os dados por meio de repositórios, evitando dependência direta das telas com o banco. Essa separação permite evoluir ou substituir a fonte de dados sem reescrever a interface.

## Firebase

Cada usuário autenticado possui seus próprios dados no Firestore, organizados abaixo do caminho:

```text
users/{userId}/
```

As regras em [`firestore.rules`](firestore.rules) impedem que um usuário acesse os registros de outro. A configuração Android está em `android/app/google-services.json`, e as opções usadas pelo Flutter estão em `lib/firebase_options.dart`.

> Antes de publicar o aplicativo, confirme no console do Firebase se o provedor E-mail/senha está habilitado e se as regras do Firestore foram implantadas.

## Como executar

### Requisitos

- Flutter SDK compatível com o projeto.
- Android Studio ou Visual Studio Code com suporte ao Flutter.
- Emulador Android ou aparelho com depuração USB habilitada.
- Projeto Firebase configurado.

### Instalação

```bash
git clone https://github.com/brunaperesdasilva/serralheria_pro.git
cd serralheria_pro
flutter pub get
flutter run
```

## Qualidade

Execute a análise estática e os testes automatizados antes de publicar uma alteração:

```bash
flutter analyze
flutter test
```

Os testes cobrem cálculos de orçamento, sugestão de margem, validações, movimentação de estoque, compartilhamento e compatibilidade dos modelos.

## Gerar APK

Para criar uma versão de teste:

```bash
flutter build apk --debug
```

Para criar uma versão de distribuição:

```bash
flutter build apk --release
```

O arquivo será gerado em `build/app/outputs/flutter-apk/`.

## Identidade visual

A interface utiliza uma identidade em preto, vermelho e branco, com componentes responsivos e estados de carregamento, lista vazia e erro. O nome e o logotipo exibidos nos orçamentos são definidos individualmente no perfil de cada empresa.

## Licença

Projeto de uso privado. A distribuição, modificação ou comercialização deve ser autorizada pela responsável pelo repositório.
