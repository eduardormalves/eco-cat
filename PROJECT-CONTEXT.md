# EcoCat - Contexto Consolidado do Projeto

Este arquivo consolida as informações de `CONTEXT.MD` e `GAME-RULES.MD` em uma referência única para desenvolvimento.

---

## Identidade do Jogo

**Nome:** EcoCat

**Gênero:** jogo 2D top-down de coleta urbana, reciclagem, progressão econômica e educação ambiental.

**Engine:** Godot Engine 4.x

**Linguagem:** GDScript

**Plataforma alvo:** Web / HTML5

**Resolução base:** 1280x720

**Público-alvo:** público geral interessado em jogos casuais, educativos e sustentáveis.

**Inspiração visual:** Stardew Valley, com estética pixel art cozy, acolhedora e relaxante.

---

## Estado Atual do Desenvolvimento

### Setup Local Inicial

Criado em 14/05/2026.

O projeto já possui um setup mínimo rodável na Godot:

- `project.godot` configurado
- cena principal em `res://scenes/Main.tscn`
- player placeholder em `res://player/Player.tscn`
- script principal em `res://scripts/main.gd`
- script de movimentação em `res://player/player.gd`
- resolução base 1280x720 configurada
- estrutura de pastas inicial criada
- input básico por WASD e setas
- mapa placeholder desenhado por código
- HUD placeholder com moedas, item atual e sustentabilidade
- EcoCat placeholder com câmera seguindo o jogador
- alias `godot` e `godot_console` configurados no profile do PowerShell para facilitar execução local
- colisões básicas adicionadas a prédios, árvores e lixeiras
- player configurado com camada e máscara de colisão
- cena `res://items/WasteItem.tscn` criada para resíduos coletáveis
- script `res://items/waste_item.gd` criado para coleta por contato
- resíduos iniciais de plástico, papel, vidro, metal e orgânico aparecem no mapa
- inventário simples de um item atual implementado diretamente no `Main`
- HUD atualiza o item carregado e mostra feedback de coleta
- cena `res://items/RecycleBin.tscn` criada para lixeiras funcionais
- script `res://items/recycle_bin.gd` criado para detectar descarte por contato
- descarte automático ao encostar na lixeira implementado
- acerto concede moedas e aumenta sustentabilidade
- erro gera feedback negativo leve e mantém o item para nova tentativa

Esta versão existe apenas para validar que o projeto abre, executa e mostra algo localmente. Os visuais são placeholders e devem ser substituídos por pixel art nas próximas fases.

### Fase Atual

O projeto está iniciando a **Fase 6 - Sistema de Lixeiras** e a **Fase 7 - Sistema Econômico** em versão mínima.

Já existe:

- `CharacterBody2D` para o EcoCat
- movimentação top-down
- câmera seguindo o player
- sprite placeholder desenhado por código
- colisão básica contra obstáculos do mapa
- coleta de resíduos por contato
- limite simples de carregar apenas um resíduo por vez
- HUD com item atual
- lixeiras funcionais por tipo
- validação de descarte correto/incorreto
- moedas por descarte correto
- sustentabilidade aumentando em acertos e reduzindo levemente em erros

Regra atual de descarte incorreto: o jogador recebe feedback negativo leve e perde um pouco de sustentabilidade, mas mantém o item para tentar novamente na lixeira correta.

Próximo passo recomendado: separar inventário/economia em sistemas próprios ou melhorar feedback visual da coleta/descarte.

---

## Escopo Definitivo

EcoCat é um jogo **single player** acadêmico, simples, bonito, sustentável e educativo.

O objetivo não é criar um jogo comercial complexo, mas sim uma experiência funcional, agradável, visualmente acolhedora e coerente com sustentabilidade.

### Requisitos Acadêmicos Obrigatórios

- o desenvolvimento deve ser realizado preferencialmente no Godot
- o jogo deve ser exclusivamente 2D
- não são permitidos projetos em 3D
- o build final deve ser exportado para HTML5/Web
- o jogo deve funcionar integralmente no navegador, sem instalação
- não é permitido usar APIs externas
- não é permitido usar banco de dados remoto
- não é permitido usar autenticação online
- o jogo deve ser autossuficiente, contendo todos os arquivos localmente
- o projeto deve seguir um modelo estático/local
- o jogo deve possuir mecânica cíclica ou rejogável, permitindo múltiplas partidas

### O Projeto Deve Ser

- single player
- simples
- cozy
- sustentável
- acadêmico
- fácil de jogar
- fácil de demonstrar
- leve para rodar na Web
- organizado e modular
- visualmente legível

### O Projeto Não Deve Ter

- multiplayer
- coop online
- PvP
- ranking online
- matchmaking
- chat
- servidores dedicados
- sincronização em rede
- economia online
- login ou autenticação
- banco de dados externo
- sistemas competitivos
- mundo aberto gigante
- combate
- crafting complexo
- árvores de habilidade complexas
- IA avançada
- clima dinâmico
- sistema de fome
- física complexa

Regra geral: se existir uma solução simples e uma solução complexa, escolher a solução simples.

---

## Conceito Central

O jogador controla Eco, um gato antropomórfico simpático que coleta resíduos urbanos, separa corretamente o lixo e usa os recursos obtidos para desenvolver uma startup sustentável.

Loop principal:

```txt
Coletar -> Separar -> Receber moedas -> Investir -> Expandir -> Coletar mais
```

O jogo deve transmitir a sensação de:

```txt
mais uma coleta
```

---

## Objetivo Educacional

EcoCat busca transformar um problema urbano real, o descarte incorreto de resíduos, em uma experiência interativa e acessível.

O jogo deve ensinar ou reforçar:

- importância da coleta seletiva
- consciência ambiental
- responsabilidade cidadã
- economia circular
- valor econômico dos resíduos
- consumo responsável
- cidades sustentáveis
- inovação e empreendedorismo sustentável

O projeto se alinha a ODS relacionados a consumo responsável, cidades sustentáveis, educação ambiental, inovação e empreendedorismo.

---

## Personagem Principal

**EcoCat / Eco**

Eco é um gato antropomórfico amigável, responsável por coletar e separar resíduos pela cidade.

Características desejadas:

- mochila reciclável
- cachecol verde
- aparência simpática
- design simples e memorável
- transmite curiosidade, cuidado e responsabilidade ambiental

---

## Direção Artística

### Sensação Desejada

- cozy
- acolhedora
- otimista
- relaxante
- amigável
- alegre

### Paleta Recomendada

- verdes suaves
- azul claro
- amarelo pastel
- bege
- marrom claro
- laranja suave

### Evitar

- neon
- tons extremamente escuros
- visual cyberpunk
- realismo excessivo
- shaders pesados

### Pixel Art

Usar pixel art simples e legível.

Sprites recomendados:

- tamanho base 32x32
- baixa complexidade
- fácil leitura
- animações leves

---

## Cidade e Progressão Visual

A cidade deve parecer viva, amigável, pequena e acolhedora.

Evitar mapas gigantes. Priorizar mapas compactos, áreas memoráveis e progressão visual clara.

### Início

- mais lixo espalhado
- áreas degradadas
- menos vegetação

### Meio

- cidade mais limpa
- árvores surgindo
- melhorias urbanas

### Final

- cidade sustentável
- áreas verdes
- painéis solares
- startup ecológica desenvolvida
- indicador de sustentabilidade em 100%

---

## Regras de Gameplay

O jogador deve:

- andar pela cidade
- coletar resíduos espalhados
- identificar o tipo de lixo
- depositar o resíduo na lixeira correta
- receber moedas por acertos
- investir moedas em melhorias
- desbloquear novas áreas e aumentar impacto ambiental

### Tipos de Resíduos Iniciais

- plástico
- papel
- vidro
- metal
- orgânico

### Sistema de Recompensa

Descarte correto:

- gera moedas
- aumenta pontuação
- aumenta sustentabilidade
- pode contribuir para combos
- dá feedback positivo visual e sonoro

Descarte incorreto:

- reduz pontuação ou recompensa
- reduz pouco a sustentabilidade
- dá feedback negativo leve
- não deve punir de forma frustrante

### Expansão da Cidade

Conforme o jogador acumula moedas e sustentabilidade:

- novos bairros podem ser desbloqueados
- a quantidade de lixo aumenta
- tipos de resíduos mais complexos podem aparecer
- a dificuldade cresce levemente

A expansão deve criar sensação de progresso sem transformar o jogo em mundo aberto grande.

---

## Startup Sustentável

Após acumular capital suficiente, o jogador desbloqueia a possibilidade de fundar uma startup ecológica.

Possíveis conceitos:

- empresa de reciclagem inteligente
- plataforma de logística sustentável
- cooperativa de reaproveitamento de resíduos
- fábrica de produtos reciclados

Mecânicas possíveis:

- investir moedas na criação da empresa
- melhorar equipamentos
- aumentar capacidade de coleta
- automatizar processos simples
- expandir atuação pela cidade
- gerar maior retorno com melhorias

Exemplos de upgrades:

- mochila maior
- coleta mais rápida
- bônus por descarte correto
- lixeiras inteligentes
- melhoria visual da cidade

Ciclo econômico:

```txt
Trabalho sustentável -> Investimento -> Crescimento -> Maior impacto -> Mais retorno
```

---

## MVP

O MVP deve provar que o jogo funciona como uma experiência simples, educativa e divertida.

Não tentar implementar tudo de uma vez.

### Funcionalidades do MVP

- movimentação 2D do player
- animações básicas
- interação simples
- resíduos coletáveis
- inventário pequeno
- item atual exibido na HUD
- lixeiras por tipo
- validação de descarte correto
- moedas
- sustentabilidade %
- mapa inicial pequeno
- feedback visual e sonoro simples
- save/load básico de moedas e sustentabilidade

### Mapa Inicial

Um pequeno bairro contendo:

- ruas
- calçadas
- árvores
- obstáculos
- lixeiras
- resíduos espalhados
- colisões básicas

---

## Plano de Desenvolvimento

A cada fase:

1. implementar apenas o necessário
2. testar no Godot
3. validar funcionalmente
4. corrigir erros
5. só então avançar

### Fase 0 - Ambiente

Preparar:

- Godot Engine 4.x
- Git
- VS Code ou IDE escolhida
- extensão de GDScript, se aplicável

Resultado esperado: ambiente pronto para iniciar desenvolvimento.

### Fase 1 - Base do Projeto

- criar estrutura de pastas
- configurar resolução 1280x720
- criar `Main.tscn`
- criar mapa inicial
- configurar câmera 2D
- configurar input básico

Resultado esperado: projeto abre, executa e mostra uma cena inicial simples.

### Fase 2 - Player e Movimentação

- criar `Player.tscn`
- usar `CharacterBody2D`
- criar movimentação top-down
- adicionar colisão
- adicionar câmera seguindo o player
- usar sprite placeholder se necessário

Resultado esperado: jogador consegue andar pelo mapa com colisão básica.

### Fase 3 - Mapa Inicial

- criar bairro pequeno navegável
- adicionar ruas, calçadas, árvores, obstáculos e lixeiras
- configurar colisões básicas

Resultado esperado: cenário simples, coerente e cozy.

### Fase 4 - Resíduos

- criar `WasteItem.tscn`
- criar tipos de resíduos
- permitir coleta por interação ou contato
- armazenar item no inventário
- remover item do mapa após coleta

Resultado esperado: player coleta resíduos espalhados.

### Fase 5 - Inventário

- criar `InventorySystem`
- limitar inventário de forma simples
- mostrar item atual na HUD
- permitir descarte posterior

Resultado esperado: jogo sabe qual item o jogador está carregando.

### Fase 6 - Lixeiras

- criar `RecycleBin.tscn`
- definir tipo da lixeira
- permitir interação
- comparar tipo da lixeira com tipo do resíduo
- aplicar recompensa ou penalidade leve

Resultado esperado: jogador descarta resíduos corretamente e recebe feedback.

### Fase 7 - Economia

- criar `EconomySystem`
- adicionar moedas por descarte correto
- reduzir ou remover recompensa em erro
- atualizar HUD

Resultado esperado: jogador recebe moedas ao reciclar corretamente.

### Fase 8 - HUD e Feedback

- exibir moedas
- exibir item atual
- exibir sustentabilidade %
- adicionar feedback positivo
- adicionar feedback negativo leve
- adicionar partículas ou animações simples

Resultado esperado: jogador entende claramente o que está acontecendo.

### Fase 9 - Sustentabilidade

- criar variável de sustentabilidade
- aumentar com acertos
- reduzir pouco com erros
- refletir progresso na HUD
- opcionalmente limpar partes do mapa visualmente

Resultado esperado: jogador percebe que suas ações melhoram a cidade.

### Fase 10 - Save/Load

- salvar moedas
- salvar sustentabilidade
- salvar progresso básico
- carregar ao iniciar

Resultado esperado: progresso permanece entre sessões.

### Fase 11 - Expansão Simples

- desbloquear nova área por moedas ou sustentabilidade
- liberar novos resíduos
- aumentar levemente dificuldade

Resultado esperado: sensação de evolução sem escopo excessivo.

### Fase 12 - Startup

- criar tela simples de startup
- investir moedas em melhorias
- upgrades aumentam eficiência ou recompensa

Resultado esperado: jogador usa moedas para ampliar impacto sustentável.

### Fase 13 - Polimento

- substituir placeholders
- melhorar tiles
- adicionar sons leves
- adicionar música calma
- melhorar animações e menus

Resultado esperado: jogo apresentável para contexto acadêmico.

### Fase 14 - Exportação Web

- configurar export HTML5/Web
- testar build local
- corrigir performance
- validar controles e assets no navegador

Resultado esperado: jogo roda via navegador.

### Fase 15 - Revisão Final

- revisar bugs
- melhorar textos explicativos
- garantir clareza educacional
- preparar roteiro de apresentação
- validar fluxo completo

Resultado esperado: MVP pronto para apresentação acadêmica.

---

## Arquitetura Recomendada

Separar sistemas em managers independentes, evitando lógica excessiva diretamente nos nodes de cena.

Sistemas sugeridos:

- `WasteSystem`
- `InventorySystem`
- `EconomySystem`
- `SaveSystem`
- `CityProgressionSystem`
- `UIManager`

Priorizar:

- scripts pequenos
- responsabilidade única
- baixo acoplamento
- reutilização
- facilidade de expansão

---

## Estrutura Recomendada

```txt
res://
├── scenes/
├── scripts/
├── systems/
├── managers/
├── ui/
├── entities/
├── player/
├── npcs/
├── items/
├── environments/
├── tilemaps/
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   ├── audio/
│   └── fonts/
├── data/
└── saves/
```

---

## Regras de Código

- usar nomes claros
- usar `snake_case` para variáveis e funções
- evitar arquivos gigantes
- comentar apenas quando necessário
- pensar em performance web desde o início
- evitar loops desnecessários
- evitar excesso de partículas
- evitar texturas grandes demais

---

## Diretriz Principal para o Codex

Sempre priorizar:

- simplicidade
- clareza
- modularidade
- legibilidade visual
- gameplay funcional
- progressão testável por etapas

Antes de implementar qualquer funcionalidade grande, dividir em pequenas partes testáveis.

Nunca implementar multiplayer, sistemas online, login, ranking ou qualquer complexidade que fuja do objetivo acadêmico.

O foco principal é:

```txt
criar uma experiência educativa, cozy, sustentável, simples e divertida.
```
