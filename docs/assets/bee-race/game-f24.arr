use context starter2024







#|             
███████╗███████╗███████╗  ██████╗  █████╗  ██████╗███████╗
██╔══██║██╔════╝██╔════╝  ██╔══██╗██╔══██╗██╔════╝██╔════╝
███████║█████╗  █████╗    ██████╔╝███████║██║     █████╗    
██╔══██║██╔══╝  ██╔══╝    ██╔══██╗██╔══██║██║     ██╔══╝ 
███████║███████╗███████╗  ██║  ██║██║  ██║╚██████╗███████╗ 
╚══════╝╚══════╝╚══════╝  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
   (Fall 2024)
|#






# IGNORE THIS - this imports support code
include shared-gdrive("dcic-2021", "1wyQZj_L0qqV9Ekgr9au6RX2iqt2Ga8Ep")
include shared-gdrive("project2-support-fall24.arr", "1BBNcHnYHMF72ZxNHsfZU7E6uLpsdZEla")
include reactors

#######################################################################
# -------------------- External Data & Constants ---------------------#
#######################################################################


#Design Check Task 7: Uncomment this part when you are ready to load from Google Sheets
   
#Place the URL of the Google Sheet to use for the maze here!
ssid = "1GBDq-SJs9GxHXLMRgnzU6-1iXGTwnT9GKLGglchU4Bo"
 
#load maze from spreadsheet into List<List<String>>
maze-grid  = load-maze(ssid) 
   
# load item positions from spreadsheet into Table form
item-table = load-items(ssid) 



# Loads all images for the game: You will need to use these constants!
base-url = "https://code.pyret.org/shared-image-contents?sharedImageId="
bee-img = image-url(base-url + "1h5Gq21noGRMbc3MYh-rgJlSscphcXER0")
beehive-img = image-url(base-url + "1RCdkKkc5Tx3fy7VqsmCpI1CSuz4fQ0au")
queen-img = image-url(base-url + "1cDfVtqLlxkKMBlF_k7m2-U24OGmgSBJe")
portal-img = image-url(base-url + "1TLhH6uMmefJpTUeQZdLirjLBvhr3FFwe")
bear-img = image-url(base-url + "1kKpfQny4zRh8XWFU1dmyQQHR_dUBTsEq")
honey-img = image-url(base-url + "1n3WyiOBnWUYqLIeUvlMJsYGvYOFeXhH-")
grass-img = image-url(base-url + "1d4eOV1CXQ4I5suYmuAnZcUu3Vy4FnGvN")
water-img = image-url(base-url + "19fqjNeJlavkuUCtuBN26lwKzRpWBPzZI")

### DATA TYPES ###

data Widget:
  | honey(c :: Coord)
  | beehive(c :: Coord)
  | bear(c :: Coord)
  | queen(c :: Coord)
end

data Coord:
  | coord(x :: Number, y :: Number)
end

data Block:
  | grass
  | water
end

data Bee:
    bee(c :: Coord,
      stamina :: Number)
end

data GameState:
    game(bee :: Bee, Widget :: List<Widget>)
end

### THE BACKGROUND ###

fun row-to-image(coords :: List<String>) -> Image:
  doc: ```x places grass, o placws water.```
  
  cases(List)coords:
    |empty => empty-image
    |link(f,r)=>
      if f == "x":
        beside(grass-img, row-to-image(r))
      else:
        beside(water-img, row-to-image(r))
          
      end
      end
end

fun maze-to-image(coords :: List<List<String>>) -> Image:
  doc: ```function to turn our maze into an image, iterating through our list of lists```
  cases(List)coords:
    |empty => empty-image
    |link(fst,rst)=>
      above-align("left", row-to-image(fst), (maze-to-image(rst)))
  end
end




### Converters for x and y positions to pixels ###

fun xpos(r :: Row) -> Number:
  doc: "converts x positions to pixels for maze"
  (45 + (30 * (r["x"] - 1)))
  #(30 * (r["x"] - 1)) + 45

end

fun ypos(r :: Row) -> Number:
  doc: "converts y positions to pixels for maze"
  (30 * (r["y"] + 1)) - 15


end


# Additional column called "Widget", which contains Widget positions
table-with-widget = build-column(
  item-table,
  "Widget",
  lam(r):
    if r["name"] == "Honey":
      honey(coord(xpos(r), ypos(r))) 
      
    else if r["name"] == "Beehive":
      beehive(coord(xpos(r), ypos(r))) 
      
    else if r["name"] == "Queen":
      queen(coord(xpos(r), ypos(r))) 
     
    else:
      bear(coord(xpos(r), ypos(r))) 
    end
    end)


fun overlay-widget(back-image :: Image, widget-list :: List<Widget>) -> Image:
  doc: ```placing our widgets in the game background```
  
  cases(List) widget-list:
    |empty => back-image
    |link(fst, rst) =>
      if fst == honey(fst.c):
        overlay-xy(honey-img, (-1 * fst.c.x) + 15, (-1 * fst.c.y) + 12, overlay-widget(back-image, rst))
        
      else if fst == beehive(fst.c):
        overlay-xy(beehive-img, (-1 * fst.c.x) + 15, (-1 * fst.c.y) + 12, overlay-widget(back-image, rst))
        
      else if fst == bear(fst.c):
        overlay-xy(bear-img, (-1 * fst.c.x) + 15, (-1 * fst.c.y) + 12, overlay-widget(back-image, rst))
        
      else if fst == queen(fst.c):
        overlay-xy(queen-img, (-1 * fst.c.x) + 15, (-1 * fst.c.y) + 12, overlay-widget(back-image, rst))
        
      else:
        overlay-widget(back-image, rst)
      end
  end
end


fun grid-to-pixels(x :: Number) -> Number:
  doc: ```converts a grid to 30x30 pixels```
  (x * 30) - 15

  where:
  grid-to-pixels(6) is 165

end

fun pixels-to-grid(x :: Number) -> Number:
  doc: ```inverse of grid-to-pixel```
  
  (x / 30) + 0.5
  
where:
  pixels-to-grid(90) is 3.5
end
  

### INITIALIZE GAME ###
init-state = game(bee(coord(grid-to-pixels(2), grid-to-pixels(2)), 110), table-with-widget.get-column("Widget"))


fun use-widget(bee-info :: GameState, widget-list :: List<Widget>) -> GameState:
  doc: ```Handles widget interactions and updates the GameState based on the widget type.```

  cases(List) widget-list:
    |empty => bee-info
    |link(f, r) =>
      # Checking if the player hits a widget location
      if (bee-info.bee.c == f.c) and (f == honey(f.c)):
        game(
          bee(coord(bee-info.bee.c.x, bee-info.bee.c.y), 100),
          bee-info.Widget.filter(lam(t): t <> honey(f.c) end)
          )
        
      else if (bee-info.bee.c == f.c) and (f == beehive(f.c)):
        game(
          bee(coord(bee-info.bee.c.x, bee-info.bee.c.y), bee-info.bee.stamina - 20),
          bee-info.Widget.filter(lam(t): t <> beehive(f.c) end)
        )
        
      else if (bee-info.bee.c == f.c) and (f == bear(f.c)):
        game(
          bee(coord(bee-info.bee.c.x, bee-info.bee.c.y), bee-info.bee.stamina - 20),
          bee-info.Widget.filter(lam(t): t <> bear(f.c) end)
        )
        
      else if (bee-info.bee.c == f.c) and (f == (queen(f.c))):
        game(
          bee(coord(bee-info.bee.c.x, bee-info.bee.c.y), bee-info.bee.stamina),
          bee-info.Widget.filter(lam(t): t <> queen(f.c) end)
        )
        
      else:
        use-widget(bee-info, r)
      end
  end
end


fun move-bee(Bee :: GameState, key :: String) -> GameState:
  doc: ``` Checks if a player presses a key, then checks in the directional move is possible```
  # Current player location on the grid
  new-x = pixels-to-grid(Bee.bee.c.x)
  new-y = pixels-to-grid(Bee.bee.c.y)

  # Rows
  row-below = maze-grid.get(new-y - 2)
  row-above = maze-grid.get(new-y)
  current-row = maze-grid.get(new-y - 1)

  # 'W' key
  if (key == "w") and (row-below.get(new-x - 1) <> "x"):
    use-widget(game(
        bee(coord(Bee.bee.c.x, Bee.bee.c.y - 30), Bee.bee.stamina - 4),
      Bee.Widget), Bee.Widget)

    # 'S' key
  else if (key == "s") and (row-above.get(new-x - 1) <> "x"):
    use-widget(game(
        bee(coord(Bee.bee.c.x, Bee.bee.c.y + 30), Bee.bee.stamina - 4),
      Bee.Widget), Bee.Widget)

    # 'A' key
  else if (key == "a") and (current-row.get(new-x - 2) <> "x"):
    use-widget(game(
        bee(coord(Bee.bee.c.x - 30, Bee.bee.c.y), Bee.bee.stamina - 4),
      Bee.Widget), Bee.Widget)

    # 'D' key
  else if (key == "d") and (current-row.get(new-x) <> "x"):
    use-widget(game(
        bee(coord(Bee.bee.c.x + 30, Bee.bee.c.y), Bee.bee.stamina - 4),
      Bee.Widget), Bee.Widget)

    # Condition for no keys pressed
  else:
    game(bee(
        coord(Bee.bee.c.x, Bee.bee.c.y),Bee.bee.stamina),
      Bee.Widget)
  end
  
where:
  move-bee(init-state, "w") is init-state

end

fun stamina-bar(energy :: Number) -> Image:
  doc: ```Creates a stamina bar based on the bee's energy level.```
  
  # Constants for stamina bar dimensions
  BAR_WIDTH = 50
  BAR_HEIGHT = 550
  BAR_X = 1050
  BAR_Y = 100

  # Calculate the filled portion of the stamina bar
  filled-height = if energy < 0: 0 else: energy * 5 end

  # Create the filled part of the bar and the outline
  filled-bar = rectangle(BAR_WIDTH, filled-height, "solid", "yellow")
  outline-bar = rectangle(BAR_WIDTH, BAR_HEIGHT, "outline", "black")

  # Overlay the filled bar on the outline
  overlay-align("center", "bottom", filled-bar, outline-bar)
end

fun draw-bee(game-state :: GameState) -> Image:
  doc: ```Draws the bee, overlays widgets, and adds the stamina bar.```

  # Base game image with maze and widgets
  base-image = place-image(bee-img, game-state.bee.c.x, game-state.bee.c.y,
    beside(overlay-widget(maze-to-image(maze-grid), game-state.Widget),
    stamina-bar(game-state.bee.stamina)))

  # Check if the bee is out of energy
  out-of-energy = game-state.bee.stamina <= 0
  queen-captured = game-state.Widget.filter(lam(w): w == queen(coord(game-state.bee.c.x, game-state.bee.c.y)) end).length() < 0

  # Display "Bee Exhausted" message if energy is 0 or less
  if out-of-energy:
    overlay-xy(text("Bee Exhausted", 35, "red"), 600, 300, base-image)

  # Display "Victory!" message if the bee captures the queen
  else if queen-captured:
    overlay-xy(text("Victory!", 35, "green"), 600, 300, base-image)

  # Otherwise, return the base image
  else:
    base-image
  end
end


test-case-1 = game(bee(coord(100,100), 100),
  [list: queen(coord(400,400)), bear(coord(50,50)), beehive(coord(200,300)), honey(coord(250,400))])

# Reaches end (the queen)
test-case-3 = game(bee(coord(400,400), 100),
  [list: queen(coord(400,400)), bear(coord(50,50)), beehive(coord(200,300)), honey(coord(250,400))])

# Hits the bear
test-case-4= game(bee(coord(100,100), 100),
  [list: queen(coord(400,400)), bear(coord(100,100)), beehive(coord(200,300)), honey(coord(250,400))])


fun game-complete(bee-location :: GameState) -> Boolean:
  doc: ```Game end conditions: reaches queen ```
  ((bee-location.Widget.filter(lam(r): r == queen(coord(bee-location.bee.c.x,(bee-location.bee.c.y))) end).length() > 0))

end

### REACTOR ####
    
bee-game = reactor: 
  init: init-state,
  to-draw: draw-bee,
  on-key: move-bee,
  stop-when: game-complete
end
  
interact(bee-game)



### Reflection ###

#|

   1) Our support code represented the maze layout (water vs grass) as a list-of-lists of strings, rather than a table. What were the advantages and disadvantages of this choice?
   Using the support code representing the maze layout as a list-of-strings rather than a table was advantageous because we could go through an entire list as one row of grass/water, rather than having to iterate through each column in the row of a table. One of the disadvantages that we found from using a list of lists rather than a table was the the information is a bit less clear to read. Since table documentation can be easily loaded into our pyret window, it would have been easier to visual the different parts of our maze.
   
   
   2) In this project, you worked with the maze layout in three formats: the Google Sheet with the configuration of walls, the list-of-lists version, and the image itself. For each representation, briefly describe what it is good and bad for.
   - The google sheet: good for loading in large sums of data. Bad for visualizing what the data looked like within our Pyret window, as the X's and O's were stored in a google sheet.
   - List-of-lists: Good for going through each index in a list to draw grass/water. Convenient and straight forward. Bad for visualizing large sums of our data. Difficult to get a sense of our maze layout just by the lists.
   - Image: Good for visualization purposes, and of course necessary for moving our bee through the game. Difficult because the image does not include coordinates, so if a widget/tile had an error it was difficult to find where the error was occuring.
   
   
   3) If you used our design check solution, describe what you learned by comparing your own proposed datatypes to the datatypes in our solution.
   Originally the data types that we had proposed were very clunky. We defined a lot of individual data inside data types, when we realized that we really could have made new datatypes to both clean up our data and make it so we had to go back and make fewer individual adjustments everytime we needed to change something. The data types from the data type solution also excluded values that were constant like the maze, a mistake we had made by including that information in our game state.
   
   4) Describe one key insight gained about programming or data organization from working on this project. Each partner should answer this separately.
   Carter: From working on this project, I learned about the importance of having clean and readable data. This project was larger than the last one, and having convenient data type names made working through tasks much easier. It made me realize that when tackling a big project, your intitial data organization goes a long way in ensuring you're successful in what you work on.
   
   Shayne: This project showed me how large amounts of data can from multiple websites can be combined to create things like websites or games. Using the input map grid and game images was a reminder than computer programming is not just about running code, but combining outside resources to enhance whatever project/task that you are working on. There are limited capabilities with Pyret itself, but using ssid's and loaded in images combined coding with other internet capabilities to enhance our game.
   
   
   5) Describe one or two misconceptions or mistakes that you had to work through while doing the project. Each partner should answer this separately.
   Carter:
   1) Misconception about how to properly define our data types. Had tried to include constant information in them which wasn't necessary.
   2) Misconception about the stamina bar. Initially assumed it was going to be a timer based decrease, but realized quickly the stamina decreased based on movement not a timer.
   
   Shayne:
   1) Misunderstood the use of a list-of-lists rather than a table. Tried to convert the list of lists to a table at first, but realized the list of lists was actual a convenient strategy.
   
   
   6) State one or two followup questions that you have about programming or data organization after working on this project. Each partner should answer this separately.
   
   Carter:
   1) Not sure if this is exactly a question, but I am still a little unsure about distinguishing between something that belongs as part of a data type versus as a function input. I think there was a lot of data that was automatically defined because we had a specific data type for it, but I'm not always sure about when it's better to rely on a data type or have manual updating information as part of function inputs.
   
   Shayne:
   1) Still not fully convinced as to why using a list-of-lists was better than a table. I see how the list-of-lists is functional, but I think using lambda and interating through table columns could have also worked well.
   2) I'm wondering how programmers can look through thousands of lines of code and stay organized. When people work on huge projects that have tons and tons of code, do they use things that function like tab groups to organize their data?
   
|#