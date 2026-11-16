# Game Title

SWEET EMPIRE

# Developer Information

Developer: Iskakov Temirlan

# Game Description

Welcome to SWEET EMPIRE, a 3D bakery management game where a growing business begins with a tray of cookies. You play as Mia, moving around the bakery to collect fresh products from workstations and deliver them to the checkout. Customers arrive with different preferences, and keeping the right treats in stock helps you serve the queue before patience runs out.

Each sale earns coins that can be invested in equipment, upgrades and cooks. As the bakery develops, its assortment grows from cookies to coffee, cupcakes and cakes, while new areas provide room for expansion. Sophie introduces the campaign and offers advice as you work toward objectives across three chapters. Quests and achievements give you further goals, while Rush Hour challenges you to prepare for a demanding period of service.

Running the bakery is a balance between immediate needs and planning ahead. Sophie's analytics show a demand forecast for each product, helping you decide what to carry next. The final decisions remain yours: watch the queue, manage your stock and grow a bakery that reflects your own style with cosmetic items.

# Main Features

- **Hands-on service:** carry products from workstations to the checkout and serve customers in order.
- **Bakery development:** buy and upgrade equipment, hire cooks and open new areas.
- **Growing assortment:** produce cookies, coffee, cupcakes and cakes as the relevant equipment and staff become available.
- **Campaign and challenges:** follow three chapters, complete quests and achievements, and prepare for Rush Hour.
- **Customer preferences:** different customer profiles influence the products visitors choose and their patience.
- **Sophie's analytics:** inspect demand forecasts and advice alongside stock, queue and business information.
- **Cosmetic customisation:** spend earned crystals on visual items for Mia and the bakery through the main-menu shop.

# AI Integration

SWEET EMPIRE combines two distinct AI systems:

**Customer decision-making.** A profile-based, weighted probabilistic algorithm selects customer types and product preferences from the available assortment. Customer profiles also define patience, and Rush Hour adjusts product weights. These choices influence incoming orders, the queue and the stock Mia needs to deliver. This is algorithmic game AI, not machine learning.

**Demand forecasting.** A Ridge regression model trained offline with Python and scikit-learn estimates the number of orders for each product over the next 120 seconds. Its inputs include the bakery's rating and campaign chapter, available products, Rush state, recent orders, arrival rate, customer mix, session time, opportunities and missed demand. Training data is synthetic. The exported model's scaling parameters and coefficients are evaluated locally in GDScript; a rule-based fallback is used if the model is unavailable or invalid.

Sophie displays forecasts in her analytics panel and can suggest preparing more of a product when predicted demand exceeds available checkout and tray stock. More urgent stock and queue warnings take priority. The player reads the information and chooses what to deliver; the model does not automatically control production or purchases. Interactive verification of these features in the exported game remains required.

# Game Controls

- **WASD:** move Mia.
- **E:** collect products or deliver them to the checkout.
- **1:** open the development menu.
- **2:** open the personnel menu.
- **Tab:** open the journal.
- **Esc:** pause or close a menu.
- **Mouse:** select interface buttons and navigate menus.

The source also contains an optional webcam gesture system: a calibrated palm controls movement, a short fist triggers interaction, a long fist pauses, and pointing and pinching operate a cursor. It requires a separate Python worker, MediaPipe, OpenCV and the hand-tracking model; that worker is not included in the existing Windows package, and real-camera operation requires verification. Keyboard and mouse are the standard controls. Touch controls have not been confirmed.

# How to Play

1. Start a new game from the main menu and follow Sophie's introduction.
2. Walk to the oven with WASD and press E to collect cookies when they are ready.
3. Take them to the checkout and press E to deliver them. Customers can be served when their requested products are stocked.
4. Use the coins earned from sales to buy equipment, hire cooks and improve the bakery through the development and personnel menus.
5. Check the journal for objectives and consult Sophie's analytics. Expand your assortment, keep the queue supplied and prepare stock before starting Rush Hour.

# Technical Requirements

- **Engine and technology:** Godot 4.7.2, GDScript and the Compatibility renderer; offline demand-model training uses Python and scikit-learn.
- **Target platform:** Windows x64 PC. A browser build has not been verified.
- **Devices:** keyboard and mouse; a graphics device capable of running the Compatibility renderer. A webcam is optional for the separate gesture setup; a microphone is not required for normal play.
- **Dependencies:** the intended Windows export does not require the Godot editor or Python for ordinary keyboard-and-mouse play. Gesture controls require the separately configured Python worker, MediaPipe, OpenCV and model file.
- **Installation:** extract the complete Windows package and run the executable with its PCK file beside it. A fully interactive test of the exported package and a separate-PC installation test are still required.
- Exact minimum hardware specifications and performance have not been measured. The interface is in Russian. Internet-free operation on a separate PC requires confirmation.

# Screenshots

Recommended captures from the current, verified game:

1. **Main menu:** title and available options.
2. **Bakery gameplay:** Mia, workstations, checkout and customers.
3. **Controls and interface:** the in-game HUD and interaction prompt.
4. **Economy and development:** equipment, upgrades and available coins.
5. **AI analytics:** Sophie's demand forecasts and their displayed source.
6. **Progression:** campaign objectives, quests or an expanded bakery.

REQUIRES USER INPUT: capture or verify current-build images before submission.

# GitHub Repository

REQUIRES USER INPUT: confirmed, accessible GitHub repository URL.

# Playable Game

REQUIRES USER INPUT: link to an uploaded, verified playable build.
