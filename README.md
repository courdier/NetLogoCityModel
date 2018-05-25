# NetLogoCityModel
Urban mobility simultation on NetLogo framework

WHAT IS IT?

This model simulates various mobility realities of residents of the City of Saint-Denis a french city located in the heart of the Indian Ocean, on the reunion Island that is one of Europe’s outermost regions.

HOW IT WORKS

A CITYSCAPE is generated, spreading out from a city center. Each patch is assigned a road-value. A road network is drawn from a GIS shape file. An initial set of cars are created from real data given by the French statistic INSEE French institution. Then each cars is assigned a energy system, some of theme are electrical (define randomly by considering a ratio defined in the Dash Board), the energy-level attribute determine the value of energy evalable for each car. Each resident has an activity calendar an has targets to reach during the day.
With each model tick, cars move on the road network to reach their target which may be work, commercial or leisure location.

HOW TO USE IT

Press CLEAR & SETUP to clear the screen and prepare for the simulation
Press VIEW ROADS to draw an initial city road map. Do not use the GO button until after VIEW ROADS has completed its process.
Press CREATE CARS to associate cars to location in the city. Do not use the GO button until after VIEW ROADS has completed its process.
Press GO to run the simulation. (Only after you have run CLEAR, and let VIEW ROADS and CREATE CARS run to completion).

THINGS TO NOTICE

(suggested things for the user to notice while running the model)

NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

RELATED MODELS

SmartCityModel : Imperial College London - https://github.com/albertopolis/SmartCityModel

HOW TO CITE
If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.
For the model itself:
Ramanandraisoa, W., Courdier, R. (2010). NetLogo Urban City Model - Saint-Denis residents mobility simulation. https://github.com/courdier/NetLogoCityModel
Please cite the NetLogo software as:
Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

CREDITS AND REFERENCES
Copyright 2018, Universioty of Reunion Island & City of Saint-Denis, Reunion Island.
