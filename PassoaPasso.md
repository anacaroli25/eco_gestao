Baixe o software necessário.
Antes de instalar o SDK do Flutter, conclua a seguinte configuração.

Instalar o Git para Windows
Baixe e instale a versão mais recente do Git para Windows .

Para obter ajuda na instalação ou na resolução de problemas do Git, consulte a documentação do Git .

Configure um editor ou IDE.
Para obter a melhor experiência no desenvolvimento de aplicativos Flutter, considere instalar e configurar um editor ou IDE com suporte para Flutter .

Instale e configure o Flutter.
Para instalar o SDK do Flutter, baixe o pacote mais recente do arquivo do SDK e, em seguida, extraia o SDK para o local desejado.

Baixe o pacote do SDK do Flutter
Baixe o pacote de instalação a seguir para obter a versão estável mais recente do SDK do Flutter.

Crie uma pasta para armazenar o SDK.
Crie ou encontre uma pasta para armazenar o SDK extraído. Considere criar e usar um diretório em %USERPROFILE%\develop( C:\Users\{username}\develop).

Observação
Selecione um local que não contenha caracteres especiais ou espaços em seu caminho e que não exija privilégios elevados.

Extraia o SDK
Extraia o .ziparquivo baixado para o diretório escolhido (por exemplo, de ` Downloads<diretório_de_configuração> ` para `<diretório_de_configuração develop>`, ajustando o nome do arquivo e os caminhos conforme necessário):

tar -xf "%USERPROFILE%\Downloads\flutter_windows_3.50.0-stable.zip" -C "%USERPROFILE%\develop"
Observação
Se o flutter.batarquivo estiver faltando no bindiretório após a extração, seu antivírus pode tê-lo colocado em quarentena. Nesse caso, configure seu antivírus para confiar no diretório do SDK do Flutter e extraia o pacote novamente.

Adicione o Flutter ao seu PATH.
Agora que você baixou o SDK, adicione o bindiretório do SDK do Flutter à sua PATHvariável de ambiente. Adicionar o Flutter à sua variável de ambiente PATHpermite que você use as ferramentas flutterde dartlinha de comando em terminais e IDEs.

Determine o local de instalação do seu SDK do Flutter.
Copie o caminho absoluto para o diretório onde você baixou e extraiu o SDK do Flutter.

Acesse as configurações de variáveis ​​de ambiente.
Pressione Windows+ Pause.

Se o seu teclado não tiver uma Pausetecla, tente Windows+ Fn+ B.

A caixa de diálogo Sistema > Sobre é aberta.

Clique em Configurações avançadas do sistema > Avançado > Variáveis ​​de ambiente ...

A caixa de diálogo Variáveis ​​de Ambiente é aberta.

Adicione o diretório bin do SDK do Flutter ao seu PATH.
Na seção Variáveis ​​de usuário para (nome de usuário) da caixa de diálogo Variáveis ​​de ambiente , procure a entrada Path .

Se a entrada do caminho existir, clique duas vezes nela.

A caixa de diálogo Editar Variável de Ambiente deverá abrir.

Clique duas vezes dentro de uma linha vazia.

Digite o caminho para o bindiretório de instalação do Flutter.

Por exemplo, se você baixou o Flutter para uma develop\flutterpasta dentro do seu diretório de usuário, você digitaria o seguinte:

%USERPROFILE%\develop\flutter\bin
Clique na entrada do Flutter que você adicionou para selecioná-la.

Clique em "Mover para cima" até que a entrada do Flutter fique no topo da lista.

Para confirmar as alterações, clique em OK três vezes.

Se a entrada não existir, clique em Novo ...

A caixa de diálogo Editar Variável de Ambiente deverá abrir.

Na caixa Nome da variável , digite Path.

Na caixa Valor da variável , digite o caminho para o bindiretório de instalação do Flutter.

Por exemplo, se você baixou o Flutter para uma develop\flutterpasta dentro do seu diretório de usuário, você digitaria o seguinte:

%USERPROFILE%\develop\flutter\bin
Para confirmar as alterações, clique em OK três vezes.

Aplique as alterações.
Para aplicar essa alteração e obter acesso à flutterferramenta, feche e abra novamente todos os prompts de comando, sessões em seus aplicativos de terminal e IDEs.

Valide sua configuração
Para garantir que você adicionou o SDK com sucesso ao seu projeto PATH, abra o prompt de comando ou seu aplicativo de terminal preferido e tente executar as ferramentas ` --install` fluttere ` --install`.dart

flutter --version
dart --version
Se nenhum dos comandos for encontrado, consulte a seção de solução de problemas de instalação do Flutter .

Valide sua configuração
Para verificar sua instalação do Flutter, execute o seguinte comando flutter doctorno seu terminal:

flutter doctor
O que esperar emflutter doctor
Você só precisa marcar as caixas de seleção ( [✓]) para o Flutter e as plataformas que pretende usar (por exemplo, o Chrome permite que você crie para a web imediatamente). Você pode ignorar com segurança [!]os [✗]avisos para ferramentas como o Android Studio ou o Xcode até que esteja pronto para usar essas plataformas.