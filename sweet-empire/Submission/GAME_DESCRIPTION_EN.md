# SWEET EMPIRE

## Developer Information
Developer: Iskakov Temirlan

## Game Overview
Step into a cozy bakery and help Mia turn a modest cookie operation into a thriving sweet empire. In this 3D bakery management game, you move through the shop yourself, collect freshly made products and deliver them to the checkout before customers lose patience. Every sale helps you invest in equipment, hire cooks and expand the range of treats on offer. Follow Sophie?s guidance through a three-chapter campaign, complete goals and prepare for the intense Rush Hour challenge. Keep an eye on your queue and stock: visitors have different preferences, and an empty counter can leave a customer waiting. Sophie?s demand forecasts offer another perspective on what to prepare, but the decisions and deliveries remain yours. Earn crystals and give the bakery and Mia a personal touch with cosmetic items.

## Genre
3D bakery management and time management.

## Gameplay Features
- Carry products from production stations to the checkout and serve a waiting queue.
- Buy and upgrade equipment, hire cooks, unlock new areas and grow your assortment.
- Follow campaign objectives, quests and achievements; prepare for Rush Hour.
- Use coins for development and crystals for optional cosmetic items from the main menu.
- Consult Sophie?s analytics for stock and demand information.

## Artificial Intelligence Integration
Customers use a profile-based, weighted probabilistic selection algorithm to choose among available products; Rush modifies weights. This is algorithmic game AI, not machine learning. A separately trained Ridge regression model estimates orders for each product over the next 120 seconds. Its inputs include rating, chapter, available products, Rush, recent orders, arrivals, customer mix, session time, opportunities and missed demand. The packaged JSON contains scaling parameters and coefficients; GDScript validates and evaluates them locally, with a rule-based fallback if the model is invalid or absent. Sophie displays the forecasts and can advise preparing more stock. The player reads the advice and makes the decisions; the model does not automatically buy equipment or produce goods. Training and reported evaluation used synthetic data. Exported gameplay and AI remain to be verified in a full interactive release test; see AI_TECHNICAL_REPORT.md. No neural network is claimed. Development tools are separate from in-game AI.

## Game Controls
Keyboard: WASD move; E collect or deliver; 1 development; 2 personnel; Tab journal; Esc pause or close menus. Mouse: select buttons and navigate menus. The source includes optional webcam gesture controls, but the current Windows package does not include the required external worker; use keyboard and mouse. Touch control is not verified.

## Technical Requirements
Windows x64 PC, keyboard and mouse, and a graphics device capable of running Godot?s Compatibility renderer. Exact minimum specifications and performance have not been measured. No webcam or microphone is required for keyboard play; no online service is required by the core gameplay code, but offline operation on a separate PC has not been tested. The exported game is intended to run without the editor or Python; its interactive packaged operation requires verification. Extract the complete Windows package and run `SWEET_EMPIRE.exe` beside its `.pck`. The game interface is in Russian.

## How to Play
1. Start the game, choose ?????? ????? and follow Sophie?s introduction.
2. Move to the oven with WASD, then press E to collect cookies when ready.
3. Go to the checkout and press E to deliver them; customers are served when their orders are stocked.
4. Spend earned coins through the development and personnel menus; consult the journal and Sophie?s analytics.
5. Complete campaign objectives and prepare stock before starting Rush Hour.

## Competition Highlights
- Hands-on delivery combined with bakery management.
- Customers with different order preferences and a waiting queue.
- Locally evaluated demand forecasts and contextual advice.
- Campaign progression, Rush Hour and cosmetic customisation.
