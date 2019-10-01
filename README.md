# SpigotMC - High Performance Minecraft Server

### THIS IS NOT THE OFICIAL OR ORIGINAL IMAGE

This version was translated to `PT-BR` and also has some changes to fit some of my requirements.
Please see forked repository for the original image

---

## Sobre esta imagem

Essa é uma imagem Docker para iniciar um servidor Spigot rápidamente, com mínimo esforço possível.

Essa imagem foi baseada no `dlord/spigot-docker`, com algumas modificações, traduções e melhorias.

## Base Docker image

-   java:8

## Como utilizar esta imagem

### Iniciando uma instância

    docker run \
        --name spigot-instance \
        -p 0.0.0.0:25565:25565 \
        -d \
        -it \
        -e DEFAULT_OP=dinnerbone \
        -e MINECRAFT_EULA=true \
        dlord/spigot

Por padrão, irá iniciar um servidor Spigot 1.8.8. Caso deseje utilizar uma
versão diferente, você precisa definir a variável `MINECRAFT_VERSION` para
a versão desejada. Utilize a documentação do Spigot para escolher uma
versão suportdada.

Você deve definir a variável `DEFAULT_OP` ao iniciar. E será o administrador
(op) padrão do servidor. Deverá ser o seu usuário/nick. O conteiner irá falhar
caso a mesma não exista.

Ao iniciar uma instância do Spigot, você deve concordar com os termos de uso
do Minecraft (EULA). Isso pode ser feito definindo a variável `MINECRAFT_EULA`
para `true`. Sem isso o servidor não irá iniciar.

Essa imagem expõe a porta padrão do Minecraft (25565).

Ao iniciar um container pela primeira vez, a imagem irá checar a existencia de
um arquivo Spigot.jar. Caso não existe, irá baixar o BuildTools e compilar uma
nova versão do Spigot direto do código oficial. Por questões legais, não podemos
fornecer versões pre-compiladas.

É recomendavél iniciar o container com `-it`. Isso é necessário para permitir
a execução de comandos no console utilizando `docker exec`. E também permite
o Spigot para desligar o servidor de uma forma segura quando o container é
desativado utilizando `docker stop`.

#### Comandos

A imagem utiliza um script de entrada chamado `spigot` que lhe permite a execução
de comandos pré-definidos. Caso tente executar um comando irregular, ele será
reconhecido como um comando SHELL.

Os comandos são:

-   `run` - Roda o servidor Spigot, e é o comando padrão utilizado pelo container.
    Esse comando pode aceitar alguns parametros adicionais. Útil ao criar um novo
    container com `docker create` ou `docker run`.

-   `permissions` - Atualiza os arquivos de permissões e todos os arquivos
    relacionados. Útil quando manualmente editar um arquivo.

-   `console` - Executa comandos como `console`. Permite aos administradores
    executarem terefas utilizando scripts. Essa função está desabilitada por padrão.

Alguns exemplos de como utilizar estes comandos:

**run - especificar um arquivo de configuração diferente dentro de /opt/minecraft**

    docker run \
        --name spigot-instance \
        -p 0.0.0.0:25565:25565 \
        -d \
        -it \
        -e DEFAULT_OP=dinnerbone \
        -e MINECRAFT_EULA=true \
        dlord/spigot
        run --spigot-settings spigot-test.yml

**permissions - atualiza arquivo e pasta permissions enquanto o container está rodando**

    docker exec spigot-instance spigot permissions

#### Scripting

Diferente de outras imagens Spigot para Docker, essa imagem fornece uma forma de
executar comandos como console sem precisar se conectar ao container Docker. Isso
permite que os adminsitradores executem tarefas bem mais complexas, como manusear
o container dentro de outro container. (Ex: deploy automatico com Jenkins)

Para aquelas que estão acostumados a utilizar `docker attach` dentro de uma sessão
`screen` ou `tmux`, isso vai ser uma maravilha.

Esse recurso pode ser habilitado passando `-it` como parametro em `docker create`
ou `docker run`, que irá habilitar STDIN e TTY. Isso irá rodar o Spigot dentro de
uma sessão `tmux`. E também habilita o desligamente seguro quando o container é
parado.

Uma vez ativado, você poderá executar comandos no console como no exemplo abaixo:

    docker exec spigot-instance spigot console say Fala galera!

Alguns avisos para quando utilizar esse recurso:

-   **NÃO USE `-it` em `docker exec`!** Por algum motivo ele, crasha (destroi)
    a sessão `tmux` que nos da essa liberdade.
-   **Cuidado ao entrar no container utilizando `docker attach`**. Você está
    entrando em uma sessão `tmux` rodando no fundo e com o rodapé desabilitado.
    Não tente sair utilizando `CTRL-b d`, isso irá parar o container. Para sair
    do container, utilize `CTRL-p CTRL-q` que é a forma padrão para sair do
    `docker attach`.

Segue um exemplo de como notificar os jogadores que o servidor irá ser desligado
após 60 segundos:

    #!/bin/bash
    docker exec spigot-instance spigot console say O servidor será desligado em 60s!
    docker exec spigot-instance spigot console say Para o que estiver fazendo!
    sleep 60
    docker exec spigot-instance spigot console say Voltaremos em breve!
    sleep 5

    # The container will send the stop console command to the server for you, to
    # O container irá enviar o comando '/stop' para o console para você, garantindo
    # que o servidor será desligado de uma forma segura.
    #
    # Claro que você pode rodar manualmente usando:
    #
    #     docker exec spigot-instance spigot console stop
    #
    # Mas isso irá reiniciar o container, se a politica de restart estiver habilitada.
    docker stop -t 60 spigot-instance

#### O problema do Spigot BuildTools

Um dos maiores problemas com o Spigot BuildTools é que ele não respeita 100% a
versão que você quer compilar. Caso a versão especificada em `MINECRAFT_VERSION`
não exista, ele irá compilar a última versão disponível. E se a versão compilada
não bater com a que foi especificada em `MINECRAFT_VERSION`, o container irá parar.

Infelizmente ainda não temos uma solução para detectar qual versão foi compilada.

Caso isso aconteça, você poderá copiar versões compiladas para o `data volume` do
docker, especificado em `MINECRAFT_HOME` (o padrão é `/opt/minecraft`), e utiliza-las
para iniciar um novo container com a `MINECRAFT_VERSION`. apropriada.

### Data volumes

O script de entrada atualiza as permissões dos `data volumes` antes de rodar
o Spigot. Você é livre para modificar o conteúdo dessas pastas sem se preocupar
com as permissões para execussão.

Existem dois volumes definidos para essa imagem:

#### /opt/minecraft

Todos os arquivos relacionados ao servidor (jars, configs) entram aqui.

#### /var/lib/minecraft

Este contém as informações dos mundos¹. Essa foi uma decisão feita para
suportar construir novas imagens Docker com templates de mundos¹ (útil para
mapas personalizados).

A abordagem recomendada para lidar com dados de mundos¹ é utilizar
containers de `data volume` separados. Você pode criar um com o seguinte comando:

    docker run --name minecraft-data -v /var/lib/minecraft java:8 true

### Variáveis de ambiente

A imagem utiliza variáveis de ambientes para configurar a JVM e o arquivo
server.properties.

#### MINECRAFT_EULA

`MINECRAFT_EULA` é obrigatório quando iniciar um novo container. Você precisa
aceitar os Termos do Minecraft (EULA) antes de iniciar o Spigot.

Por questões legais isso não será definido como padrão!

Leiam os termos antes de aceita-los.

#### DEFAULT_OP

`DEFAULT_OP` é obrigatório ao iniciar um novo container.

Isso será removido em uma versão futura

#### MINECRAFT_OPTS

Você pode modificar as configurações da JVM utilizando a variável `MINECRAFT_OPTS`.

#### Variáveis de ambientes para server.properties

Cada campo dentro do arquivo `server.properties` pode ser alterado passando
a variável correspondente. Para facilitar, a variável correspondente para cada campo
é o mesmo descrito dentro do arquivo mas em CAPSLOCK e com underscore (-) no lugar
do hífem (-).

Por enquanto a porta do servidor não pode ser modificada. Ela deverá ser mapeada
utilizando o roteamendo do Docker.

Para referência, segue uma lista das variáveis de ambientes disponíveis para
`server.properties`:

-   GENERATOR_SETTINGS
-   OP_PERMISSION_LEVEL
-   ALLOW_NETHER
-   LEVEL_NAME
-   ENABLE_QUERY
-   ALLOW_FLIGHT
-   ANNOUNCE_PLAYER_ACHIEVEMENTS
-   LEVEL_TYPE
-   ENABLE_RCON
-   FORCE_GAMEMODE
-   LEVEL_SEED
-   SERVER_IP
-   MAX_BUILD_HEIGHT
-   SPAWN_NPCS
-   WHITE_LIST
-   SPAWN_ANIMALS
-   SNOOPER_ENABLED
-   ONLINE_MODE
-   RESOURCE_PACK
-   PVP
-   DIFFICULTY
-   ENABLE_COMMAND_BLOCK
-   PLAYER_IDLE_TIMEOUT
-   GAMEMODE
-   MAX_PLAYERS
-   SPAWN_MONSTERS
-   VIEW_DISTANCE
-   GENERATE_STRUCTURES
-   MOTD

## Extending this image

This image is meant to be extended for packaging custom maps, plugins, and
configurations as Docker images. For server owners, this is the best way to
roll out configuration changes and updates to your servers.

If you wish to do so, here are some of the things you will need to know:

### Gatilho de ONBUILD

Essa imagem contem um gatilho de `ONBUILD`, que copia todos os arquivos
locais para `/usr/src/minecraft`.

Quando um container é iniciado pela primeira vez, o conteúdo dessa pasta é
copiado para `MINECRAFT_HOME` utilizando `rsync`, exceto para os arquivos que
começam com `world`. Ele também irá garantir que a pasta `MINECRAFT_HOME/plugins`
exista e irá deletar todos os arquivos `.jar` para substituir pelos novos. Essa é
a forma mais fácil de atualizar os plugins sem precisar entrar dentro dos volumes.

### Templates de mundo¹

Essa imagem suporta o uso de templates para mundos, que é útil para empacotar
mapas personalizados. Templates de mundos devem sempre iniciar com `world`, que
tem sindo um padrão de conveniência do Minecraft. (ex: world, world_nether, world_end).
Copie seus templates para `/usr/src/minecraft` utilizando o Gatilho de `ONBUILD`.
Durante a inicialização, ele irá checar se `/var/lib/minecraft` está vazio. E se
tiver, irá criar uma cópia dos templates dessa pasta.

### Argumentos da JVM

Você pode adiciona-los pela variável `MINECRAFT_OPTS` no seu Dockerfile.s

## Versões do Docker suportadas

Essa imagem foi testada na versão 1.9 do Docker.

## Feedback and Contributions

Sinta-se a vontade para abrir um [Github issue][].

Caso deseje contribuir, você poderá abrir um pull request.

O código deverá ser estar 100% em inglês e mensagens preferencialmente em português.

If you wish to contribute and you DO NOT speak Portuguese, the messages and the code
should be 100% in English. LANGUAGES OTHER THAN ENGLISH AND PORTUGUESE WILL BE DECLINED.

[original github image]: https://github.com/dlord/spigot-docker/
[minecraft eula]: https://account.mojang.com/documents/minecraft_eula

Mundo¹: Mapa, world, etc.
