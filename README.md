# 📱 Task Manager Flutter

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License">
</div>

## 📋 Sobre o Projeto

O **Task Manager** é um aplicativo Flutter completo para gerenciamento de tarefas com persistência local usando SQLite. Desenvolvido como parte do curso de Engenharia de Software, este projeto demonstra conceitos fundamentais de desenvolvimento mobile, gerenciamento de estado e persistência de dados.

### ✨ Funcionalidades

- ✅ **CRUD Completo**: Criar, ler, atualizar e deletar tarefas
- 🎯 **Sistema de Prioridades**: Baixa, Média e Alta com cores visuais
- 🔍 **Filtros Inteligentes**: Visualizar todas, completas ou pendentes
- 📊 **Contador em Tempo Real**: Estatísticas de tarefas no AppBar
- 💾 **Persistência Local**: Dados salvos em SQLite
- 🎨 **Interface Moderna**: Design responsivo com Material Design
- 🔄 **Atualização Automática**: Interface sincronizada com dados
- 📱 **Layout Responsivo**: Adaptação automática a diferentes tamanhos de tela
- 🛡️ **Overflow Prevention**: Solução para problemas de espaço em dispositivos pequenos

## 🚀 Tecnologias Utilizadas

- **Flutter** - Framework de desenvolvimento mobile
- **Dart** - Linguagem de programação
- **SQLite** - Banco de dados local (via sqflite)
- **Material Design** - Design system do Google

## 📦 Dependências

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0          # Banco de dados SQLite
  path_provider: ^2.1.1    # Acesso a diretórios do sistema
  path: ^1.8.3             # Manipulação de caminhos
  uuid: ^4.2.1             # Geração de IDs únicos
  intl: ^0.19.0            # Formatação de datas
  shared_preferences: ^2.2.2 # Preferências do usuário
```

## 🏗️ Arquitetura do Projeto

```
lib/
├── models/
│   └── task.dart              # Modelo de dados da tarefa
├── services/
│   └── database_service.dart  # Serviço de banco de dados
├── screens/
│   └── task_list_screen.dart  # Tela principal da aplicação
└── main.dart                  # Ponto de entrada da aplicação
```

### 📚 Padrões de Design Aplicados

- **Singleton Pattern**: DatabaseService para gerenciar conexão única
- **Model-View-Controller**: Separação clara de responsabilidades
- **State Management**: Gerenciamento de estado com setState()
- **Widget Composition**: Componentes reutilizáveis e modulares

## 🛠️ Instalação e Execução

### Pré-requisitos

- Flutter SDK (versão 3.5.4 ou superior)
- Dart SDK
- Android Studio / VS Code
- Emulador Android ou dispositivo físico

### 📱 Dispositivos Suportados

#### **Android**
- ✅ Dispositivos físicos (Android 5.0+)
- ✅ Emuladores Android
- ✅ Tablets Android

#### **Windows**
- ✅ Windows 10/11 (64-bit)
- ✅ Desktop e laptop

#### **Web**
- ✅ Chrome (recomendado)
- ✅ Edge
- ✅ Firefox
- ✅ Safari

#### **Dispositivos Testados**
- Samsung Galaxy A30s (SM A305GT) - Android 11
- Windows 10/11 Desktop
- Chrome/Edge Web Browsers

### Passos para Execução

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/task-manager-flutter.git
   cd task-manager-flutter
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Execute a aplicação**
   ```bash
   flutter run
   ```

### Comandos por Dispositivo

#### 📱 **Android (Dispositivo Físico)**
```bash
# Verificar dispositivos Android conectados
flutter devices

# Executar em dispositivo específico (substitua pelo ID do seu dispositivo)
flutter run -d RX8M704WDHT

# Executar com hot reload
flutter run -d RX8M704WDHT --hot

# Executar em modo debug
flutter run -d RX8M704WDHT --debug

# Executar em modo release
flutter run -d RX8M704WDHT --release
```

#### 🖥️ **Windows Desktop**
```bash
# Executar no Windows
flutter run -d windows

# Build para Windows
flutter build windows
```

#### 🌐 **Web**
```bash
# Executar no Chrome
flutter run -d chrome

# Executar no Edge
flutter run -d edge

# Build para Web
flutter build web
```

#### 📱 **Emulador Android**
```bash
# Listar emuladores disponíveis
flutter emulators

# Iniciar emulador específico
flutter emulators --launch <emulator_id>

# Executar no emulador
flutter run
```

### Comandos de Manutenção

```bash
# Verificar problemas do Flutter
flutter doctor

# Limpar cache e dependências
flutter clean && flutter pub get

# Verificar dispositivos conectados
flutter devices

# Executar com logs detalhados
flutter run --verbose
```

## 📱 Screenshots

<div align="center">
  <img src="screenshots/main_screen.png" alt="Tela Principal" width="300">
  <img src="screenshots/priority_dropdown.png" alt="Dropdown de Prioridade" width="300">
  <img src="screenshots/filters.png" alt="Filtros" width="300">
</div>

## 🎯 Funcionalidades Detalhadas

### 📝 Gerenciamento de Tarefas
- **Adicionar**: Campo de texto + dropdown de prioridade
- **Editar**: Marcar como concluída/desmarcar
- **Deletar**: Botão de exclusão com confirmação visual
- **Visualizar**: Lista organizada com cards e cores

### 🎨 Sistema de Prioridades
- **🟢 Baixa**: Tarefas de menor urgência
- **🟡 Média**: Tarefas de prioridade padrão
- **🔴 Alta**: Tarefas urgentes e importantes

### 🔍 Filtros Inteligentes
- **Todas**: Exibe todas as tarefas
- **Pendentes**: Apenas tarefas não concluídas
- **Completas**: Apenas tarefas finalizadas

### 📊 Contadores em Tempo Real
- **Total**: Número total de tarefas
- **Completas**: Tarefas finalizadas
- **Pendentes**: Tarefas em andamento

### 📱 Design Responsivo
- **Layout Adaptativo**: Interface se ajusta automaticamente ao tamanho da tela
- **Contadores Responsivos**: Layout vertical em telas pequenas, horizontal em telas grandes
- **Filtros Inteligentes**: Layout vertical em dispositivos pequenos para evitar overflow
- **Dropdown Otimizado**: Expansão automática para usar todo espaço disponível
- **Prevenção de Overflow**: Soluções implementadas para evitar quebra de interface

## 🧪 Testes

### Checklist de Funcionalidades
- [x] Adicionar nova tarefa
- [x] Marcar tarefa como concluída
- [x] Deletar tarefa
- [x] Filtrar por status
- [x] Selecionar prioridade
- [x] Persistência de dados
- [x] Atualização em tempo real

### Como Testar
1. Execute a aplicação
2. Adicione algumas tarefas com diferentes prioridades
3. Teste os filtros (Todas/Pendentes/Completas)
4. Marque algumas tarefas como concluídas
5. Verifique se os contadores atualizam corretamente
6. Feche e reabra o app para verificar persistência

## 📚 Conceitos de Engenharia de Software

### 🏗️ Arquitetura
- **Separation of Concerns**: Cada classe tem responsabilidade específica
- **Single Responsibility**: Métodos focados em uma única funcionalidade
- **Dependency Injection**: Serviços injetados onde necessário

### 🔄 Gerenciamento de Estado
- **Local State**: setState() para atualizações de interface
- **Data Flow**: Fluxo unidirecional de dados
- **State Separation**: Dados completos vs. dados filtrados

### 💾 Persistência de Dados
- **SQLite**: Banco de dados local robusto
- **CRUD Operations**: Operações completas de banco
- **Data Mapping**: Conversão entre objetos e registros

### 🎨 Design Responsivo
- **LayoutBuilder**: Adaptação automática ao tamanho da tela
- **Responsive UI**: Interface que se ajusta a diferentes dispositivos
- **Overflow Prevention**: Solução para problemas de espaço em telas pequenas

## 🐛 Solução de Problemas

### RenderFlex Overflow
**Problema**: Erro "RenderFlex overflowed by X pixels" no AppBar e filtros

**Causa**: Conteúdo excedia o espaço disponível em telas menores

**Soluções Implementadas**:

#### 1. Contadores Responsivos
```dart
Widget _buildResponsiveCounters() {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 300) {
        // Layout vertical para telas pequenas
        return Column([
          Row([Total, Completas]),
          Pendentes
        ]);
      } else {
        // Layout horizontal para telas grandes
        return Row([Total, Completas, Pendentes]);
      }
    },
  );
}
```

#### 2. Filtros Responsivos
```dart
Widget _buildResponsiveFilters() {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 350) {
        // Layout vertical para telas pequenas
        return Column([
          Text('Filtrar:'),
          SegmentedButton([...])
        ]);
      } else {
        // Layout horizontal para telas grandes
        return Row([
          Text('Filtrar:'),
          Expanded(SegmentedButton([...]))
        ]);
      }
    },
  );
}
```

#### 3. Dropdown Otimizado
```dart
Expanded(
  child: DropdownButton<String>(
    isExpanded: true,
    child: Text(
      _getPriorityLabel(value),
      style: TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
    ),
  ),
)
```

**Benefícios**:
- ✅ Elimina completamente o overflow
- 📱 Interface responsiva em qualquer dispositivo
- 🎨 Mantém a aparência profissional
- 🔄 Adaptação automática à orientação da tela
- 🛡️ Prevenção de textos quebrados

### Problemas Comuns e Soluções

| Problema | Causa | Solução |
|----------|-------|---------|
| `RenderFlex overflowed` | Conteúdo excede espaço disponível | Usar `LayoutBuilder` ou `Flexible` |
| `Database locked` | Múltiplas conexões simultâneas | Verificar padrão Singleton |
| `Hot reload não funciona` | Cache corrompido | Executar `flutter clean` |
| `Dependências não encontradas` | Pub cache inválido | Executar `flutter pub get` |

### Comandos de Diagnóstico
```bash
# Verificar problemas do Flutter
flutter doctor

# Limpar cache e dependências
flutter clean && flutter pub get

# Verificar dispositivos disponíveis
flutter devices

# Executar em modo verbose para debug
flutter run --verbose
```

## 🚀 Próximas Funcionalidades

- [ ] Edição inline de tarefas
- [ ] Busca por texto
- [ ] Ordenação por prioridade/data
- [ ] Data de vencimento
- [ ] Categorias de tarefas
- [ ] Backup e sincronização
- [ ] Temas claro/escuro
- [ ] Notificações

## 🤝 Contribuição

Contribuições são bem-vindas! Para contribuir:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👨‍💻 Autor

**Mauricio Fernandes Leite**
- Matrícula: 697964
- GitHub: https://github.com/MF300175/AppFlutter

