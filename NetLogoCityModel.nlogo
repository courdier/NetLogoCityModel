;=================================================================================================
; Programme de simulation de déplacement de véhicule sur la commune de Saint-Denis de la Réunion
; Version 0.4
;==================================================================================================

;---declaration des librairies d'extension au langage----
extensions [ gis ]

;---Déclaration des variables globales du programme------
globals [
  dataset_route
  dataset_quartier
  dataset_habitation
  dataset_commercial
  dataset_industriel
  dataset_leisure
  feature_list
  totalHabitation
  totalVoiture
  totalRoute
  totalQuartier
  g_watchTarget?
  totalVoituresPanneEnergie
  totalVoituresToDestination
  xcor-target
  ycor-target
  LastvisitedTarget
  degre
]


;---Définition des classes d'agents------------------------
breed [ voitures voiture ]
voitures-own [
  direction    ; sens de déplacement
  home-pos     ; coordonnée de départ
  dest-pos ; coordonnée point d'arrivée
  isElectric?  ; FALSE classique, TRUE Electrique
  isArrived?
  energyLevel  ; 1 à 100
]
breed [ targets target ]
targets-own [
  nbcars_arrived_to_this_target
]
;---Initialisation des patches------------------------------
patches-own [ road? list_car_memory]

;==================================================================================================
; Procedure d'initialisation de la simulation
;==================================================================================================
to setup
  ;remise à zero
  clear-all
  ;set g_watchACar nobody
  set g_watchTarget? FALSE
  set totalVoiture 0
  set totalHabitation 0
  set totalRoute 0
  set totalVoituresPanneEnergie 0
  set totalVoituresToDestination 0
  ask patches [
    set pcolor white
    set road? false
    set list_car_memory list list_car_memory 0
  ]

  ;chargement de toutes les cartes (dataset)
  set dataset_route gis:load-dataset "NET/roads.shp"
  set dataset_quartier gis:load-dataset "NET/Quartier.shp"
  set dataset_habitation gis:load-dataset "NET/home.shp"
  ;set dataset_commercial gis:load-dataset "NET/commercial.shp"
  ;set dataset_leisure gis:load-dataset "NET/leisure.shp"

  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of dataset_route)
                                                (gis:envelope-of dataset_quartier)
                                                ;(gis:envelope-of dataset_commercial)
                                                ;(gis:envelope-of dataset_leisure)
                                                (gis:envelope-of dataset_habitation))
  ; creation d'une cible de destination pour les voitures
  set xcor-target -2
  set ycor-target 93
  create-targets 1  [setxy xcor-target ycor-target set color red set size 3 set shape "circle 2"]
  ; initialisation du séquenceur agents
  ask targets [set hidden? true]
  set LastvisitedTarget nobody
  reset-ticks
end

;==================================================================================================
; Procedure d'animation de la simulation
;==================================================================================================
to go
  ; animer ici l'activité de mobilité des habitants
  let liste_voitures_non_arrivees voitures with [ isElectric? and not isArrived?]
  ifelse any? liste_voitures_non_arrivees
    [ ask voitures with [ isElectric? and not isArrived?] [drive]
      tick
    ]
    [ ; si toutes les voitures sont arrivées alors stopper
      stop
    ]
end
;==================================================================================================

to set-target
  ;let creation false
  if mouse-down? [
      let node one-of targets with [distancexy mouse-xcor mouse-ycor < 4]

      if node = nobody [
        set xcor-target (word (int mouse-xcor))
        set ycor-target (word (int mouse-ycor))
        create-targets 1 [
           setxy mouse-xcor mouse-ycor
           set color red
           set size 3
           set shape "circle 2"
           set nbcars_arrived_to_this_target 0
           set hidden? false
        ]
      ]
      if node = LastvisitedTarget and node != nobody [
        ask node [ask my-links [set hidden? true]]
      ]
  ]

  if mouse-inside? [

    let node one-of targets with [distancexy mouse-xcor mouse-ycor < 2]
    if node != nobody and node != LastvisitedTarget
       [ask node
          [ set label-color black
            set label nbcars_arrived_to_this_target
            set xcor-target int mouse-xcor
            set ycor-target int mouse-ycor
            ask targets [ask my-links [set hidden? true]]
            ask my-links [set hidden? false]
            set LastvisitedTarget node
          ]
    ]
  ]
  display
end

to drive
  ;ifelse (distancexy read-from-string xcor-target read-from-string ycor-target < velocity)
  ifelse (distancexy (item 0 dest-pos) (item 1 dest-pos) < velocity)
     [; la viture est arrivée
          set isArrived? TRUE
          set totalVoituresToDestination totalVoituresToDestination + 1
          ask targets-here [set nbcars_arrived_to_this_target nbcars_arrived_to_this_target + 1]
          set color yellow
     ]
     [; la voiture n'est pas arrivée
          ifelse energyLevel >= 0 [
            ; elle a encore de l'energie
            ; [TODO] *** A coder pour que les voitures ne se déplacent pas n'importe ou !!! ***
            next-direction
          ]

          [ ; elle n'a plus d'energie
            set totalVoituresPanneEnergie totalVoituresPanneEnergie + 1
            ; on supprime la voiture en panne du réseau routier
            die
          ]
  ]
end

to consume
       set energyLevel energyLevel - .1 ; @RC TODO simpliste à retravailler
end

to next-direction
  let old-heading heading
  facexy (item 0 dest-pos) (item 1 dest-pos)
  set degre 30
  ; on est face à notre destination si il y a une route on la prend
  ; sinon on se remet dans notre direction d'avant et une cherche à continuer notre route
                       ; if who = g_watchACar [set size 3 set color green ask my-links [set hidden? false] print "" type "***" type who type ": "] ; @RC DEBUG
  let p one-of patches in-cone velocity degre with [road?]
  ifelse (peut-avancer? p )
    [ avance p ]
    [ set heading old-heading
                       ; if who = g_watchACar[ask patch-ahead 1 [set pcolor black]] ; @RC DEBUG
      search-direction
    ]
end

to search-direction ; call by nest-direction
      let p one-of patches in-cone velocity degre with [road?]
                      ; if who = g_watchACar [ ask patches in-cone velocity degre [set pcolor blue ]] ; *** RC@ DEBUG
                      ; if who = g_watchACar [ if user-yes-or-no? degre [ ask patches in-cone velocity degre [set pcolor white ] ]] ; *** RC@ DEBUG
      ifelse (peut-avancer? p )
       [ avance p]
       [              ; if who = g_watchACar [print degre type " "]; @RC DEBUG
         set degre degre + 30
         if degre < 361 [search-direction]
       ]
end

to avance [p]
  move-to p
  consume
  set list_car_memory fput who list_car_memory
  if who = g_watchACar [ print "###" print list_car_memory ] ; *** RC@ DEBUG
end

to-report peut-avancer? [p]
  let nb_passage length (filter [ i -> i = who ] list_car_memory)
                        ; if who = g_watchACar [ print "" type " list : nb_passage " type nb_passage type " - " print list_car_memory ] ; *** RC@ DEBUG
  ifelse (is-patch? p and p != patch-here and nb_passage < 3)
    [report true]
    [report false]
end

to display-routes
  gis:set-drawing-color grey

  gis:draw dataset_route 0.75
  ; recupération des routes comme attribut du patch
  ask patches [ if gis:intersects? dataset_route self [ set road? True ]]

  foreach gis:feature-list-of dataset_route [ set totalRoute totalRoute + 1 ]
  ask targets [set hidden? false]
  if (debug?) [
      show "--- Propriétés du dataset_route : "
      print gis:property-names dataset_route
      print gis:feature-list-of dataset_route
      ; les routes seront en jaunes
      ask patches with [road?][set pcolor yellow]
  ]
end

to display-habitations
  gis:set-drawing-color green
  gis:draw dataset_habitation 1
  foreach gis:feature-list-of dataset_quartier [ set totalHabitation totalHabitation + 1]

  if (debug?) [
    show "--- Propriété du dataset_habitation : "
    print gis:property-names dataset_habitation
    print gis:feature-list-of dataset_habitation
  ]
end

to display-quartiers

  gis:set-drawing-color red
  gis:draw dataset_quartier 3
  foreach gis:feature-list-of dataset_quartier [ set totalQuartier totalQuartier + 1]

  if (debug?) [
    show "--- Propriété du dataset_habitation : "
    print gis:property-names dataset_quartier
    print gis:feature-list-of dataset_quartier
  ]
end


to display-cars
  foreach gis:feature-list-of dataset_habitation [ vector-feature ->
      let centroid gis:location-of gis:centroid-of vector-feature
      let nbVoitures gis:property-value vector-feature "VOITURE"
      set totalVoiture totalVoiture + nbVoitures
      ; centroid will be an empty list if it lies outside the bounds
      ; of the current NetLogo world, as defined by our current GIS
      ; coordinate transformation
      if not empty? centroid
      [ create-voitures nbVoitures
          [ set home-pos list xcor ycor
            let aTarget one-of targets;
            create-link-to aTarget
            ask my-links [hide-link]; [set hidden? true]
            let temp-pos list 0 0
            ask aTarget [set temp-pos list xcor ycor]
            set dest-pos temp-pos
            set shape "car"
            set isElectric? FALSE
            set isArrived? FALSE
            set color white - 3
            set xcor item 0 centroid
            set ycor item 1 centroid
          ]
      ]
  ]
  ; parametrage des voitures electric
  ask n-of (totalVoiture * pourcentageElectrique / 100) voitures [
        set isElectric? TRUE
        set color red
        set EnergyLevel random 100
  ]
end


to supNotElect
  ; parametrage des voitures electric
  ask voitures [ if not isElectric? [die] ]
  set totalVoiture count voitures
end

;===================================================================
; *** Copyright LIM lab, University of reunion Island, 2018
;===================================================================
@#$#@#$#@
GRAPHICS-WINDOW
210
10
2228
2029
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-100
100
-100
100
0
0
1
ticks
30.0

BUTTON
10
26
188
59
1. Clear and setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
48
67
188
100
2. View roads
display-routes
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
48
100
188
133
[2. View homes]
display-habitations
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
48
133
188
166
[2. View city districts]
display-quartiers
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
17
284
192
317
4. go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
16
335
94
380
Nb quartiers
totalQuartier
17
1
11

MONITOR
16
385
95
430
Nb routes
totalRoute
17
1
11

MONITOR
105
335
190
380
Nb voitures
totalVoiture
17
1
11

MONITOR
106
385
191
430
Nb Maisons
totalHabitation
17
1
11

SLIDER
16
450
192
483
pourcentageElectrique
pourcentageElectrique
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
18
490
190
523
velocity
velocity
0
5
5.0
.5
1
NIL
HORIZONTAL

MONITOR
20
533
101
578
Cars to dest.
totalVoituresToDestination
17
1
11

MONITOR
103
533
191
578
Cars 0 Energy
totalVoituresPanneEnergie
17
1
11

BUTTON
15
209
188
242
3. Create cars
display-cars
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
15
241
118
275
[Sup not elec. cars]
SupNotElect
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
24
790
193
823
debug?
debug?
1
1
-1000

BUTTON
118
242
188
275
Sup all cars
ask voitures [die]\nset totalVoiture 0
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
48
166
116
199
Set target
set-target
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
116
166
188
199
Sup Targets
ask targets [die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
20
623
102
668
NIL
xcor-target
17
1
11

MONITOR
103
623
191
668
NIL
ycor-target
17
1
11

INPUTBOX
24
728
195
788
g_watchACar
412.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

This model simulates various mobility realities of residents of the City of Saint-Denis a french city located in the heart of the Indian Ocean, on the reunion Island that is one of Europe's outermost regions.

## HOW IT WORKS

A CITYSCAPE is generated, spreading out from a city center. Each patch is assigned a road-value. A road network is drawn from a GIS shape file.
An initial set of cars are created from real data given by the French statistic INSEE French institution. 
Then each cars is assigned a energy system, some of theme are electrical (define randomly by considering a ratio defined in the Dash Board), the energy-level attribute determine the value of energy evalable for each car. Each resident has an activity calendar an has targets to reach during the day.

With each model tick, cars move on the road network to reach their target which may be work, commercial or leisure location.

## HOW TO USE IT

Press CLEAR & SETUP to clear the screen and prepare for the simulation

Press VIEW ROADS to draw an initial city road map. Do not use the GO button until after VIEW ROADS has completed its process.

Press CREATE CARS to associate cars to location in the city. Do not use the GO button until after VIEW ROADS has completed its process.

Press GO to run the simulation. (Only after you have run CLEAR, and let VIEW ROADS and CREATE CARS run to completion).

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

SmartCityModel : Imperial College London - https://github.com/albertopolis/SmartCityModel


## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Ramanandraisoa, W., Courdier, R. (2010).  NetLogo Urban City Model - Saint-Denis residents mobility simulation.  https://github.com/courdier/NetLogoCityModel

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


## CREDITS AND REFERENCES

Copyright 2018, Universioty of Reunion Island & City of Saint-Denis, Reunion Island.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

<!-- 2018 Cite: Courdier, R., Ramanandraisoa, W. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
