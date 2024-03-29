# gerafrequencia_web

Website para gerar controles de frequência de funcionários para preenchimento manual como PDF.

## Uso

O site pode ser acessado pelo link [https://gerafrequencia.web.app](https://gerafrequencia.web.app/).

<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/a6e3c47c-fbcd-4cfa-a0f8-265ff2ea0969" width="600"><br>

Clique em "Novo" para iniciar a edição de um novo controle de frequências:

<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/d6e14123-1e88-4ad4-b33d-78322f712020" width="600"><br>

Na aba "Geral", é possível definir o mês o qual a frequência será gerada, além de definir opções de formatação do PDF:

<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/df670b7f-40fd-44d9-972b-9ccd00085fc4" width="600"><br>

No calendário exibido, clique sobre um dia para marcá-lo como feriado (cor verde) ou 
[ponto facultativo](https://www.santander.com.br/blog/ponto-facultativo) (cor laranja) ao gerar a frequência. Os feriados
nacionais, estaduais e municipais serão destacados com a cor azul:

<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/54a1f891-712b-46d2-936d-0c241f97b321" width="600"><br>

No canto direito da tela, é possível subir uma imagem (de preferência com as dimensões de largura maiores que a de altura)
para utilizar como cabeçalho de todas as páginas do PDF a ser gerado:

<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/4db8fdda-fd0c-456a-bc7c-6c12198886c2" width="600"><br>

### Inserção de dados

Este projeto se baseia em um organograma vertical com dois níveis: diretorias e departamentos.

A aba "Diretorias", na seção "Dados" no canto esquerdo da tela, representa o primeiro nível. É possível inserir o nome da diretoria,
sua sigla, o nome da empresa, e seus dados de endereço. Clique em "adicionar" para inserir na lista da plataforma:

<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/437736d3-8c8a-4459-a3a1-fc66d9f1c7c8" width="600">
<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/bde622cf-186d-407a-a0d0-3a2a149de948" width="600">
<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/c17023b4-69fe-4e6b-b2ca-55ac64b81bc0" width="600"><br>

Ao clicar sobre um card inserido, é possível editar suas informações. Para deletá-lo, basta clicar no seu ícone de lixeira vermelho.

A aba "Departamentos", na mesma seção "Dados" anterior, representa o segundo nível. É possível inserir o nome do departamento, sua sigla,
um telefone e e-mail de contato. Neste caso, é preciso selecionar a qual diretoria este departamento está vinculado:

<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/4f3778a1-89d1-4652-ad35-0ac44dc2cc3d" width="600">
<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/79e0a210-a0de-4e14-860a-d810b8975af3" width="600"><br>

Por fim, a aba "Servidores", na mesma seção "Dados", representa os servidores que serão levados em consideração no controle de 
frequência a ser gerado. Para cada servidor adicionado nessa aba, será adicionada uma página no PDF correspondente ao mesmo:

<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/cd4af388-2b93-497f-ac19-1cf1590ec8fa" width="600">
<img src="https://github.com/enzo-santos/gerafrequencia_web/assets/22715629/a748b32b-1751-488d-979b-29c538331277" width="600"><br>

Ao adicionar os servidores, o botão "Exportar como PDF" ficará disponível no canto superior da tela. Ao clicar nele, será baixado o 
PDF contendo os controles de frequência de cada servidor adicionado. [Eis um exemplo](https://drive.google.com/uc?export=download&id=1omhVrO4x_QignH3obatm77jadZNeW4JM)
com os dados inseridos neste tutorial.

### Importação e exportação

Para evitar preencher novamente os dados todo mês ao gerar um novo controle de frequência, é possível salvá-los em um arquivo local. Para isso,
clique no botão "Salvar" no canto superior da tela com os dados já inseridos no sistema. Um arquivo *save.gfreq* será salvo no seu computador.

Para importar os dados novamente, basta clicar no botão "Abrir" no canto superior da tela, selecionar o arquivo e clicar em OK. Os dados, como
o cabeçalho escolhido, os feriados marcados e os servidores selecionados, já serão importados automaticamente.

## Privacidade

Os dados são 100% armazenados localmente no seu navegador, sem qualquer envio de dados para servidores. Desta forma, não há possibilidade de agentes 
externas acessarem remotamente as informações inseridas no site (foi escolhido o uso de arquivo de importação e exportação por este motivo).

A única conexão com recursos externos é feita para a [API de feriados](https://api.invertexto.com/api-feriados) da plataforma Invertexto,
em que é feita apenas a leitura dos feriados para exibição no calendário.

## Informações de desenvolvimento

Para fazer alterações no código-fonte, é recomendado ter instalados o Git ([link](https://git-scm.com/downloads)) e o
Flutter na versão 3.19.2 ([link](https://git-scm.com/downloads)).

Clone este repositório:

```shell
git clone https://github.com/enzo-santos/gerafrequencia_web
cd gerafrequencia_web
```

Baixe as dependências e gere os arquivos de modelos:

```shell
dart pub get
dart run build_runner build
```

Execute o site localmente:

```shell
flutter run -d chrome
```
