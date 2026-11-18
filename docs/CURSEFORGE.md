# SuperNovaUI Forever

**A modular options panel for World of Warcraft: Forever, and a macro that follows a spell's cooldown.** Every function is a module with its own switch, so you keep only what you want.

WoW Forever only (interface 16001). The Retail version is a separate addon called **SuperNovaUI**, with its own saved variables.

Type `/snui` to open the options panel.

---

## What it does

### 1. Options panel: `/snui`

One window for everything SuperNovaUI Forever does:

- **Modules by category** (General, Compatibility, Tools), each with its own on/off switch, a search box, and **Enable all / Disable all**.
- A short **first-run question** so you start with only what you want. You can ask it again from the General page.
- **Profile**: export your settings as text and import them on another character or computer.
- **English and Portuguese (Brazil)**, automatic or chosen by you.
- A dark "deep space" look with the game's own font, and a window you can drag and reset.

### 2. Macro by cooldown (module)

Keeps a macro of yours pointing at the right spell: while a spell is on cooldown the macro shows and casts another one, and when the cooldown ends it goes back by itself. It does nothing until you set it up, it never casts anything for you, and a change that would happen during combat waits until the fight ends.

- Set it up in **Tools > Macro by cooldown**: the spell, the macro name, and the two texts (one while the spell is ready, one while it recharges).
- It remembers when the cooldown ends (talents and Blizzard changes included) and looks again only at that moment, not every second.
- The **Fill with the druid example** button writes the racial *Sky Vision* while ready, and Cat Form plus Dash while it is on cooldown, as a starting point.
- A macro cannot be edited during combat. The page explains a two-fixed-macros alternative for combat use.

---

## Commands

| Command | What it does |
|---|---|
| `/snui` or `/supernova` | Open the options panel |
| `/snui help` | List the commands in the chat |
| `/snui status` | State of every module |
| `/snui macro` | Open the Macro by cooldown page |
| `/snui reload` | Reload the UI |

## Installation

Copy **both** folders from the zip into `World of Warcraft/_forever_/Interface/AddOns/`:

- `SuperNovaUI_Forever` - the addon and the panel
- `!SuperNovaUI_Forever_Compat` - loads first; it will restore API functions the game lacks (empty for now)

No dependencies. Settings are kept in `SuperNovaUIForeverDB`.

## What it never does

- It never edits, replaces or deletes files of other addons.
- It does not collect or send any data.
- It does not automate gameplay: the macro only changes its own text, and never casts for you.

## Limits

- There are no fixes for other addons in this version yet.
- A macro can only change outside combat, so a change during a fight is applied when the fight ends.

---

## Credits

SuperNovaUI Forever shares its panel and the Macro by cooldown module with the Retail addon.

## License

MIT. See `LICENSE` inside each addon folder.

---
---

# SuperNovaUI Forever (Português do Brasil)

**Um painel de opções modular para o World of Warcraft: Forever e uma macro que acompanha a recarga de uma magia.** Cada função é um módulo com liga/desliga próprio, para você manter só o que quiser.

Somente WoW Forever (interface 16001). A versão Retail é um addon separado, chamado **SuperNovaUI**, com configurações próprias.

Digite `/snui` para abrir o painel de opções.

---

## O que ele faz

### 1. Painel de opções: `/snui`

Uma janela para tudo o que o SuperNovaUI Forever faz:

- **Módulos por categoria** (General, Compatibility, Tools), cada um com o seu liga/desliga, uma busca e **Enable all / Disable all**.
- Uma **pergunta rápida na primeira vez**, para você começar só com o que quer. Dá para ver de novo na página General.
- **Perfil**: exporte suas configurações como texto e importe em outro personagem ou computador.
- **Inglês e português (Brasil)**, automático ou escolhido por você.
- Visual escuro de "espaço profundo" com a fonte do próprio jogo, e uma janela que você pode arrastar e reposicionar.

### 2. Macro por recarga (módulo)

Mantém uma macro sua apontando para a magia certa: enquanto uma magia está em recarga, a macro mostra e usa outra, e quando a recarga acaba ela volta sozinha. Ele não faz nada até você configurar, nunca lança nada por você, e uma mudança que aconteceria durante o combate espera a luta acabar.

- Configure em **Tools > Macro by cooldown**: a magia, o nome da macro e os dois textos (um enquanto a magia está pronta, outro enquanto recarrega).
- Ele guarda quando a recarga termina (talentos e mudanças da Blizzard incluídos) e só olha de novo nesse momento, não a cada segundo.
- O botão **Fill with the druid example** escreve a racial *Visão do Céu* enquanto pronta, e Forma de Felino mais Arremetida enquanto está em recarga, como ponto de partida.
- Uma macro não pode ser editada em combate. A página explica uma alternativa com duas macros fixas para usar em combate.

---

## Comandos

| Comando | O que faz |
|---|---|
| `/snui` ou `/supernova` | Abre o painel de opções |
| `/snui help` | Lista os comandos no chat |
| `/snui status` | Estado de cada módulo |
| `/snui macro` | Abre a página da Macro por recarga |
| `/snui reload` | Recarrega a interface |

## Instalação

Copie **as duas** pastas do zip para `World of Warcraft/_forever_/Interface/AddOns/`:

- `SuperNovaUI_Forever` - o addon e o painel
- `!SuperNovaUI_Forever_Compat` - carrega primeiro; vai devolver funções da API que o jogo não tem (vazio por enquanto)

Sem dependências. As configurações ficam em `SuperNovaUIForeverDB`.

## O que ele nunca faz

- Nunca edita, substitui nem apaga arquivos de outros addons.
- Não coleta nem envia nenhum dado.
- Não automatiza o jogo: a macro só muda o próprio texto, e nunca lança nada por você.

## Limites

- Esta versão ainda não tem correções para outros addons.
- Uma macro só pode mudar fora de combate, então uma mudança durante a luta é aplicada quando ela acaba.

---

## Créditos

O SuperNovaUI Forever divide o painel e o módulo Macro por recarga com o addon Retail.

## Licença

MIT. Veja o arquivo `LICENSE` dentro de cada pasta do addon.
