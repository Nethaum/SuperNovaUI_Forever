# SuperNovaUI Forever

**A modular options panel for World of Warcraft: Forever, and a macro that follows a spell's cooldown.** Every function is a module with its own switch, so you keep only what you want.

WoW Forever only (interface 16001). The Retail version is a separate addon called **SuperNovaUI**, with its own saved variables.

![Options panel](https://media.forgecdn.net/attachments/2261/498/forever_013_en-us-png.png)

Type `/snui` to open the options panel.

---

## What it does

### 1. Options panel: `/snui`

One window for everything SuperNovaUI Forever does:

- **Modules by category** (General, Compatibility, Interface, Tools), each with its own on/off switch, a search box, and **Enable all / Disable all**.
- **Modules that do not apply to you start off.** One that would be useless for you, or that duplicates an addon you already run, starts off; once you switch it yourself, your choice is kept.
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

### 3. Exploration markers (module)

Marks, on the world map and on the minimap, the regions of the zone you are in that you have not discovered yet. A marker is a small ring, and it disappears when you discover the region. It is off if another addon already uncovers the map for you (Leatrix Maps).

- Two switches in its page: markers on the world map and markers on the minimap.
- `/snui explore` lists in the chat the regions of the current zone that are still to discover.
- It shares its code with the Retail addon; the regions are the ones of the WoW Forever zones.

### 4. Elemental Convergence markers (module)

Marks every elemental convergence on the world map and on the minimap with a small wind swirl, for the Skysight of the Windshaper Skyborne. It starts on only for that race (or anyone who knows Skysight), and off for everyone else.

- Two switches in its page: markers on the world map and markers on the minimap.
- `/snui converge` tells how many convergences the current zone has.
- Only in this addon: the positions are taken from the Wowhead page of the object, 417 points in 41 zones.
- With [Skyborne Leyline & Convergence Marker](https://www.curseforge.com/wow/addons/sllcm) (by tr0tsky) installed, this module uses that addon's list of points, which is bigger and keeps growing. As that addon draws the same markers (and shows which ones were seen just now), this module starts off next to it; you can still switch it on.

### 5. Profession goal (module)

Set the level you want to reach in any profession (for example Cooking 180) and, with the profession window open, a box under it says how many points are left and the cheapest way to get there. It starts off until you set a goal.

- Set it in **Tools > Profession goal**: the target level (a number), or only the name of a recipe, and the level that recipe needs is found for you. Only recipes that exist in WoW Forever are accepted.
- The cheapest way is worked out recipe by recipe, from the price of each reagent: Auction House prices when you have Auctionator or TradeSkillMaster, and vendor prices (learned when you open a vendor, or from VoidGPS if you have it). Without prices it still tells which recipes can give you points, and says the plan is incomplete.
- `/snui goal` says how far the goal of the open profession is, and `/snui goal plan` prints the whole plan: recipes to buy, every step and the shopping list with prices.
- It works in any game language: goals are saved per profession, not per translated name.
- The recipe data is inside the addon; no other addon is needed.

---

## Commands

| Command | What it does |
|---|---|
| `/snui` or `/supernova` | Open the options panel |
| `/snui help` | List the commands in the chat |
| `/snui status` | State of every module |
| `/snui macro` | Open the Macro by cooldown page |
| `/snui explore` | List the regions of this zone you have not discovered yet |
| `/snui converge` | How many elemental convergences this zone has |
| `/snui goal` | How far the goal of the open profession is |
| `/snui goal plan` | The cheapest way to the goal, with prices and what to buy |
| `/snui reload` | Reload the UI |

## Installation

Copy **both** folders from the zip into `World of Warcraft/_forever_/Interface/AddOns/`:

- `SuperNovaUI_Forever` - the addon and the panel
- `!SuperNovaUI_Forever_Compat` - loads first; it will restore API functions the game lacks (empty for now)

No dependencies. Auctionator, TradeSkillMaster and VoidGPS are optional: the Profession goal module uses their prices when they are installed. Settings are kept in `SuperNovaUIForeverDB`.

## What it never does

- It never edits, replaces or deletes files of other addons.
- It does not collect or send any data.
- It does not automate gameplay: the macro only changes its own text, and never casts for you.

## Limits

- There are no fixes for other addons in this version yet.
- A macro can only change outside combat, so a change during a fight is applied when the fight ends.

---

## Credits

SuperNovaUI Forever shares its panel, the Macro by cooldown module and the Exploration markers module with the Retail addon. The optional list of elemental convergences comes from Skyborne Leyline & Convergence Marker by tr0tsky (MIT). The list of WoW Forever recipes used by the Profession goal module is built from the data of [VoidProf](https://www.curseforge.com/wow/addons/voidprof) by bughatti (MIT), and the numbers in it match the game's own tables; its notice is in `THIRD_PARTY_NOTICES.md`. VoidProf does not need to be installed.

## License

MIT. See `LICENSE` inside each addon folder.

---
---

# SuperNovaUI Forever (Português do Brasil)

**Um painel de opções modular para o World of Warcraft: Forever e uma macro que acompanha a recarga de uma magia.** Cada função é um módulo com liga/desliga próprio, para você manter só o que quiser.

Somente WoW Forever (interface 16001). A versão Retail é um addon separado, chamado **SuperNovaUI**, com configurações próprias.

![Painel de opções](https://media.forgecdn.net/attachments/2261/499/forever_013_pt-br-png.png)

Digite `/snui` para abrir o painel de opções.

---

## O que ele faz

### 1. Painel de opções: `/snui`

Uma janela para tudo o que o SuperNovaUI Forever faz:

- **Módulos por categoria** (General, Compatibility, Interface, Tools), cada um com o seu liga/desliga, uma busca e **Enable all / Disable all**.
- **Módulos que não se aplicam a você começam desligados.** Um que seria inútil para você, ou que repete um addon que você já usa, começa desligado; depois que você mexe no liga/desliga, a sua escolha é mantida.
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

### 3. Marcadores de exploração (módulo)

Marca, no mapa-múndi e no minimapa, as regiões da zona em que você está que ainda não foram descobertas. O marcador é um pequeno anel e some quando você descobre a região. Ele fica desligado se outro addon já revela o mapa para você (Leatrix Maps).

- Dois liga/desliga na página dele: marcadores no mapa-múndi e marcadores no minimapa.
- `/snui explore` lista no chat as regiões da zona atual que ainda faltam descobrir.
- Ele divide o código com o addon Retail; as regiões são as das zonas do WoW Forever.

### 4. Marcadores de Convergência Elemental (módulo)

Marca todas as convergências elementais no mapa-múndi e no minimapa com um pequeno redemoinho de vento, para a Visão do Céu dos Celonatos Moldaventos. Ele começa ligado só para essa raça (ou para quem conhece a Visão do Céu) e desligado para todos os outros.

- Dois liga/desliga na página dele: marcadores no mapa-múndi e marcadores no minimapa.
- `/snui converge` diz quantas convergências a zona atual tem.
- Só neste addon: as posições vêm da página do objeto no Wowhead, 417 pontos em 41 zonas.
- Com o [Skyborne Leyline & Convergence Marker](https://www.curseforge.com/wow/addons/sllcm) (de tr0tsky) instalado, este módulo usa a lista de pontos desse addon, que é maior e continua crescendo. Como esse addon desenha os mesmos marcadores (e mostra quais foram vistos agora há pouco), este módulo começa desligado junto dele; você ainda pode ligá-lo.

### 5. Meta de profissão (módulo)

Defina o nível que você quer alcançar em qualquer profissão (por exemplo Culinária 180) e, com a janela da profissão aberta, uma caixa embaixo dela diz quantos pontos faltam e o caminho mais barato até lá. Ele começa desligado até você definir uma meta.

- Defina em **Tools > Profession goal**: o nível desejado (um número), ou só o nome de uma receita, e o nível que ela exige é descoberto para você. Só são aceitas receitas que existem no WoW Forever.
- O caminho mais barato é calculado receita por receita, pelo preço de cada reagente: preços do leilão se você tem o Auctionator ou o TradeSkillMaster, e preços de vendedores (aprendidos quando você abre um vendedor, ou do VoidGPS se você o tem). Sem preços ele ainda diz quais receitas podem dar pontos, e avisa que o plano está incompleto.
- `/snui goal` diz o quanto falta da meta da profissão aberta, e `/snui goal plan` mostra o plano inteiro: receitas a comprar, cada passo e a lista de compras com preços.
- Funciona em qualquer idioma do jogo: as metas são guardadas por profissão, não pelo nome traduzido.
- Os dados das receitas estão dentro do addon; nenhum outro addon é necessário.

---

## Comandos

| Comando | O que faz |
|---|---|
| `/snui` ou `/supernova` | Abre o painel de opções |
| `/snui help` | Lista os comandos no chat |
| `/snui status` | Estado de cada módulo |
| `/snui macro` | Abre a página da Macro por recarga |
| `/snui explore` | Lista as regiões desta zona que você ainda não descobriu |
| `/snui converge` | Quantas convergências elementais esta zona tem |
| `/snui goal` | O quanto falta da meta da profissão aberta |
| `/snui goal plan` | O caminho mais barato até a meta, com preços e o que comprar |
| `/snui reload` | Recarrega a interface |

## Instalação

Copie **as duas** pastas do zip para `World of Warcraft/_forever_/Interface/AddOns/`:

- `SuperNovaUI_Forever` - o addon e o painel
- `!SuperNovaUI_Forever_Compat` - carrega primeiro; vai devolver funções da API que o jogo não tem (vazio por enquanto)

Sem dependências. Auctionator, TradeSkillMaster e VoidGPS são opcionais: o módulo Meta de profissão usa os preços deles quando estão instalados. As configurações ficam em `SuperNovaUIForeverDB`.

## O que ele nunca faz

- Nunca edita, substitui nem apaga arquivos de outros addons.
- Não coleta nem envia nenhum dado.
- Não automatiza o jogo: a macro só muda o próprio texto, e nunca lança nada por você.

## Limites

- Esta versão ainda não tem correções para outros addons.
- Uma macro só pode mudar fora de combate, então uma mudança durante a luta é aplicada quando ela acaba.

---

## Créditos

O SuperNovaUI Forever divide o painel e os módulos Macro por recarga e Marcadores de exploração com o addon Retail. A lista opcional de convergências elementais vem do Skyborne Leyline & Convergence Marker, de tr0tsky (MIT). A lista de receitas do WoW Forever usada pelo módulo Meta de profissão é feita a partir dos dados do [VoidProf](https://www.curseforge.com/wow/addons/voidprof), de bughatti (MIT), e os números dela batem com as tabelas do próprio jogo; o aviso dele está em `THIRD_PARTY_NOTICES.md`. O VoidProf não precisa estar instalado.

## Licença

MIT. Veja o arquivo `LICENSE` dentro de cada pasta do addon.
