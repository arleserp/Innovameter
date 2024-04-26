extensions [csv]

breed [ tech-access tech-point ] ;; places that offer access to technology
breed [ people person ]

patches-own [quality price sd-dist]
globals [ counter average-utility average-age globalind count-new-people max-tech-access tech-access-perc max-util min-util average-y-schooling alpha]
tech-access-own [utility]
people-own [ age utility-p years-scolarity years-scolarity-count ]

to setup
  clear-all
  ;setup-patches
  setup-people
  ;ask patches [ update-patch-color ]
  reset-ticks
end



to setup-people
  create-people 1000
  ask people
  [
    set color red
    set shape "person"
    ;let radius 10
    set size 1
    set age  random life-expectancy
    setxy random-xcor random-ycor
    init-education-start-mean
    ;setxy ( ( radius / 2 ) - random-float ( radius * 1.0 ) ) ( ( radius / 2 ) - random-float ( radius * 1.0 ) )
  ]
end

to write-data-to-csv
  csv:to-file "report.csv" [ 2 ]
end

;;
;; Runtime Procedures
;;
to go
  update-view
  locate-people
  update-stats
  plot-globalind
;  if counter > goverment-efficiency
;  [
;    locate-service
;    set counter 0
;  ]
  kill-people
  ;kill-service
  update-view ;visualise stats

  tick
end


to go-once
  locate-people
  update-stats
  plot-globalind
;  if counter > goverment-efficiency
;  [
;    locate-service
;    set counter 0
;  ]
  kill-people
  ;kill-service
  update-view ;visualise stats

  tick
end

to locate-people
  set count-new-people count(people) * (birth-rate) ;works since we start with 1000 people
  set counter  counter + count-new-people
  ask people [
    set age (age + 1)
    if age >= 15 and age <= 65
    [
      set color red + ( age * 0.1 )
      evaluate-people
    ]
  ]


  create-people count-new-people
  [
    set color red
    set shape "person"
    set age 0; life-expectancy ;
    set size 1
    let radius 10
    init-education-mean
    ;evaluate-people
    if age >= 15 and age <= 65
    [
      evaluate-people
    ]
    setxy random-xcor random-ycor
    ;decrease-value
    ;decrease-price
  ]
end

to evaluate-people
  ;let candidate-patches n-of number-of-options patches
  ;set candidate-patches candidate-patches with [ not any? turtles-here ]
  ;if (not any? candidate-patches)
  ;   [ stop ]

  ;; we use a hedonistic utility function for our agents, shown below
  ;; basically, poor people are looking for inexpensive real estate, close to jobs
  ;let best-candidate max-one-of candidate-patches
  ;  [ patch-utility ]
  ;move-to best-candidate
  ask people [
    set-utility
    set-education-mean
    ;set utility-p [ patch-utility ] ;of best-candidate
  ]
end

to-report patch-utility
  report ( pcolor - green ) / 4.9;( ( 1 / (sd-dist + 0.1) ) ^ ( 1 - quality-priority ) ) * ( quality ^ ( 1 + quality-priority) ) ; to study this equation taken from urban suite Uri Wilensky
end

to locate-service
  let empty-patches patches with [ not any? turtles-here ]

  if any? empty-patches
  [
    ask one-of empty-patches
    [
      sprout-tech-access 1
      [
        set color red
        set shape "circle"
        set size 2
        ;evaluate-tech-point
      ]
    ]
    ask patches
      [ set sd-dist min [distance myself + .01] of tech-access ]
  ]
end


;to evaluate-tech-point
;  let candidate-patches n-of number-of-options patches
;  set candidate-patches candidate-patches with [ not any? turtles-here ]
;  if (not any? candidate-patches)
;    [ stop ]
;
;  ;; In this model, we assume that jobs move toward where the money is.
;  ;; The validity of this assumption in a real-world setting is worthy of skepticism.
;  ;;
;  ;; However, it may not be entirely unreasonable. For instance, places with higher real
;  ;; estate values are more likely to have affluent people nearby that will spend money
;  ;; at retail commercial shops.
;  ;;
;  ;; On the other hand, companies would like to pay less rent, and so they may prefer to buy
;  ;; land at low real-estate values
;  ;; (particularly true for industrial sectors, which have no need for consumers nearby)
;  let best-candidate max-one-of candidate-patches [ price ]
;  move-to best-candidate
;  set utility [ price ] of best-candidate
;end


to kill-service
  ; always kill the oldest job
  while [count(tech-access) >= max-tech-access][
    ask min-one-of tech-access [who]
    [ die ]
  ]
  ask patches
    [ set sd-dist min [distance myself + .01] of tech-access ]
end

to kill-people
  ;let agents-before count(people)
  ;ask people with [age >= life-expectancy] [ die ]
  ;let new-pop agents-before - ( agents-before * (death-rate / 100))
  ;while [count(people) > new-pop][
  ;  ask one-of people [die] ;with [age >= life-expectancy] [ die ]; [die]
  ;]
  set alpha (0.085 * 0.5 / (exp(0.085 * life-expectancy) - 1))
  ask people [
    ;Mapping life expectancy to probability of death through the 50% point on the Gompertz cummulative density function
     ;if random 1000 < ( 1 - exp(-(0.693) * (1 - exp(0.085 * age)) / (1 - exp(0.085 * life-expectancy)))) * 1000 [
      ;if random 1000 < ( 1 - ( exp ( ( 1 - exp(0.085 * age)) / ( 1 - exp(0.085 * life-expectancy)) * -0.693))) * 1000 [
      if random 1000 < (alpha * exp(0.085 * age)) * 1000 [
      ;set ndeaths ndeaths + 1
         die
      ]
  ]
end

;;visualisation procedures


to update-stats
 ask people[
    set average-utility (mean [utility-p] of people  with [age >= 15 and age <= 65] )
    set average-age (mean [age] of people)
    set average-y-schooling mean [years-scolarity-count] of people with [age >= 25]
    set globalind average-utility * 0.000104 + life-expectancy * 0.129 + average-y-schooling * 0.458 +  ICTuse * -0.059 + Research&Development * -0.155
  ]
end

to plot-globalind
    set-current-plot "Global Innovation Index"
    set-current-plot-pen "globalind"
    plot globalind
end

to update-view
;  if (view-mode = "poor-utility" or view-mode = "rich-utility")
;  [
;    let poor-util-list [ patch-utility-for-poor ] of patches
;    set min-poor-util min poor-util-list
;    set max-poor-util max poor-util-list
;
;    let rich-util-list [ patch-utility-for-rich ] of patches
;    set min-rich-util min rich-util-list
;    set max-rich-util max rich-util-list
;  ]
  set max-util max [pcolor] of patches
  set min-util min [pcolor] of patches
  ;ask patches [ update-patch-color ]
end



to set-utility ; person procedure
  set utility-p years-scolarity * 0.665 + 4.538
end

to set-education-mean ;person procedure
  if age >= 5 and years-scolarity-count < years-scolarity
  [
    set  years-scolarity-count  ( years-scolarity-count + 1 )
  ]
end


to init-education-mean ;person procedure
    set years-scolarity random-poisson mean-years-schooling
end


to init-education-start-mean ;person procedure
    set years-scolarity-count random-poisson mean-years-schooling
    set  years-scolarity  years-scolarity-count
end
@#$#@#$#@
GRAPHICS-WINDOW
173
10
691
529
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
-25
25
-25
25
1
1
1
ticks
30.0

BUTTON
1
11
64
44
NIL
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

SLIDER
1
85
173
118
birth-rate
birth-rate
0
10
0.016
0.01
1
NIL
HORIZONTAL

BUTTON
64
11
127
44
NIL
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

SLIDER
1
119
173
152
life-expectancy
life-expectancy
1
100
77.3
0.1
1
NIL
HORIZONTAL

PLOT
693
10
893
160
Global Innovation Index
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"globalind" 1.0 0 -5298144 true "" ""

PLOT
1040
312
1240
462
Mean utility of people
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [utility-p] of people"

PLOT
693
161
893
311
People
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -11085214 true "" "plot count people"

PLOT
1041
10
1241
160
average age
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [age] of people"

BUTTON
0
44
77
77
NIL
go-once
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
150
172
183
mean-years-schooling
mean-years-schooling
0
20
8.6
0.1
1
NIL
HORIZONTAL

PLOT
1041
161
1241
311
Mean years schooling
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [years-scolarity-count] of people"

SLIDER
0
184
172
217
ICTuse
ICTuse
0
150
79.0
1
1
NIL
HORIZONTAL

SLIDER
0
217
171
250
Research&Development
Research&Development
0
150
42.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model takes advantage or some previous correlation analysis to define the main variables that predict the Global Innovation Index of a country. 

## HOW IT WORKS

The simulation time is defined by discrete rounds, where one round represents one year. The output of the simulation is an estimate of the Global Innovation Index.
At the start of the simulation, the following actions are carried out:
	The simulation starts creating 1000 individuals and locating each one randomly in the space.
	Initialize the age of each individual with an integer random value between 0 and the life expectancy of a given country.
	Create a value called maximum-years-scolarity for each individual.
At the beginning of each round the following process is carried out:
	Create new people according to the birth rate. Creating a person also involves generating two individual values for each person: 
	Life expectancy: a pseudo-random number generated from 0 to the life expectancy of people of a given country.
	Maximum years of schooling: a poisson random number generated from the mean years of schooling of a country.
	Apply the mortality rate to random individuals: This is done using a Gompertz cumulative density function (36).  The mortality rate at age x is given by
μ(x)= αe^βx
Where α and β are constants that are applied using the 50% point of the Gompertz cumulative density function to map life expectancy to the probability of death
	α=  (0.085*0.5)/(e^(0.085*lifeexp)-1) (1)

β is the actuarial aging rate, which determines how quickly the mortality rate increases as additional years are added. Values of α and β are taken from (https://modelingcommons.org/browse/one_model/6305#model_tabs_browse_info).  
If a random number is less than μ(x), an individual is removed from simulation simulating death.
	Increase the age of each individual in one.
	Evaluate each individual: This step contains to steps:
	Evaluate Scholarity: Increase the years of schooling in one if the value is less than the maximum individual years of schooling.
	Evaluate individual incomes: We assume that a person has an individual utility if the age is between 15 and 65. We run a regression to determine individual utility from individual years of schooling. We obtain the following expression for the income of individual i:
utility_i= schoolyears_i*0.665+4.538
	Update the Global Innovation Index using the expression obtained from the regression. The equation for updating the simulated global innovation index of a country c is as follows:
simulatedgni_c=(0.000104*utility_c)+(lifeexpectancy_c*0.129)+(computedav〖gschooling〗_c*0.458)+(ICTUse*-0.059)+(Research&Development*-0.155)
Where:
	utility_c: is the average utility of country c obtained by all the live individuals.
	lifeexpectancy_c: life expectancy by a country c.
	computedav〖gschooling〗_c: is the average utility of country c obtained by all the live individuals.
	ICTUse: ranking obtained from database in (Global Innovation Index Appendix III Sources and definitions, p-351)
	Research&Development: ranking obtained from database in (Global Innovation Index Appendix III Sources and definitions, p-350)




## HOW TO USE IT

The model define at country level:

* Birth rate: number of people born each year per 1000 people in the population (Jones & Lopez, 2006).
* Life expectancy: age in years defined as a numerical variable to measure the health dimension of the HDI. (https://hdr.undp.org/data-center/human-development-index#/indicies/HDI)
* Mean years of schooling: Numeric variable measuring the educational dimension for adults aged 25.
* ICT use is a ranking derived from a composite index that assigns 25 percent to each of the percentage of individuals using internet. (Global Innovation Index Appendix III Sources and definitions, p.351)
* Research&Development: Ranking of research of a country. -(Global Innovation Index Appendix III Sources and definitions, p-350).



## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Switzerland" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="83.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="13.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.011"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Sweden" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="82.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="12.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.012"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Finland" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="81.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="12.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.011"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Singapore" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="83.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="11.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.009"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Germany" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="81.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="14.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.009"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Israel" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.018"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Ireland" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="82.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="12.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.014"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="China" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="76.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="8.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.012"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Japan" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="84.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="12.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.008"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="France" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="82.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="11.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.012"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Spain" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="83.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="10.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.009"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Italy" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="44"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="83.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="10.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.009"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Portugal" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="82.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="9.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.008"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Chile" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="41"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="80.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="10.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.013"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Mexico" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="72"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="75.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="8.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.018"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Costa Rica" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="46"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="80.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="8.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.015"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Uruguay" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="31"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="77.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="8.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.013"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Brazil" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="57"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="75.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.014"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Colombia" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="58"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="77.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="8.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.016"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Peru" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="86"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="73"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="76.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="9.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.018"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Argentina" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="53"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="38"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="76.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="10.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.017"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Panama" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="104"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="78.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="10.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.018"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Paraguay" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="87"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="74.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="8.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.017"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Ecuador" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="77"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="8.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.018"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Honduras" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="108"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="119"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="75.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="6.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.022"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Guatemala" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="107"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="117"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="74.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="6.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.025"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="El salvador" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="97"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="107"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="73.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="6.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.016"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Bolivia" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="71.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.022"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Nicaragua" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>globalind</metric>
    <enumeratedValueSet variable="ICTuse">
      <value value="105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Research&amp;Development">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="life-expectancy">
      <value value="74.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-years-schooling">
      <value value="6.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate">
      <value value="0.017"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
