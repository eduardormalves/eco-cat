# EcoCat

EcoCat e um jogo educativo ambiental 2D desenvolvido na Godot.

O projeto e academico, single player, autossuficiente e pensado para exportacao final em HTML5/Web.

## Requisitos

- Godot Engine 4.x
- Git
- VS Code ou outro editor de codigo, opcional
- Extensao Godot Tools para VS Code, opcional

Versao usada durante o desenvolvimento inicial:

```txt
Godot 4.6.2 stable
```

Outras versoes 4.x da Godot podem funcionar, mas a recomendacao e usar a versao mais proxima possivel da indicada acima.

## Como Clonar

```bash
git clone <url-do-repositorio>
cd <pasta-do-projeto>
```

O arquivo principal do projeto Godot fica na raiz:

```txt
project.godot
```

## Como Abrir no Godot

Pelo editor da Godot:

1. Abra a Godot.
2. Clique em `Import`.
3. Selecione o arquivo `project.godot`.
4. Abra o projeto.
5. Execute a cena principal.

## Como Rodar Pela Linha de Comando

Se o executavel da Godot estiver no `PATH`:

```bash
godot --path . --run
```

Para abrir o editor pela linha de comando:

```bash
godot --path .
```

No Windows, se o comando `godot` nao existir, use o caminho completo do executavel da sua instalacao da Godot. Exemplo:

```powershell
& "C:\caminho\para\Godot_v4.x-stable_win64.exe" --path . --run
```

## Controles

- `WASD` ou setas: mover o EcoCat
- Encostar em um residuo colorido: coletar
- Encostar na lixeira correspondente: descartar

## Estado Atual do Prototipo

O projeto ja possui:

- cena principal
- player 2D com camera
- mapa placeholder
- colisao basica
- residuos coletaveis
- inventario simples de um item
- lixeiras funcionais
- moedas e sustentabilidade basicas
- feedback textual na HUD

## Objetivo de Build

O build final deve ser exportado para HTML5/Web e funcionar integralmente no navegador, sem instalacao.

O projeto nao deve depender de:

- APIs externas
- banco de dados remoto
- autenticacao online
- servidor dedicado

Quando chegar na fase de exportacao, pode ser necessario instalar os export templates da Godot para Web.

## Observacoes de Desenvolvimento

- O jogo deve permanecer exclusivamente 2D.
- O escopo deve continuar simples e adequado a um projeto academico.
- O arquivo `PROJECT-CONTEXT.md` contem o contexto consolidado, regras e estado atual do desenvolvimento.

